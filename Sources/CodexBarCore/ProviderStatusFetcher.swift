import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Shared, lock-guarded ISO8601 formatters for status feeds. Allocating a fresh
/// `ISO8601DateFormatter` per decoded date field is a measurable share of decoding the
/// Google Workspace incidents feed, which can run to hundreds of kilobytes (#1399).
private final class StatusISO8601FormatterBox: @unchecked Sendable {
    let lock = NSLock()
    let withFractional: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt
    }()

    let plain: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt
    }()
}

private enum StatusFeedDateParser {
    static let box = StatusISO8601FormatterBox()

    static func parse(_ text: String) -> Date? {
        self.box.lock.lock()
        defer { self.box.lock.unlock() }
        return self.box.withFractional.date(from: text) ?? self.box.plain.date(from: text)
    }

    static func decodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = StatusFeedDateParser.parse(raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date")
            }
            return date
        }
    }
}

package enum ProviderStatusFetcher {
    private static let aiStudioStatusPageURL = URL(string: "https://aistudio.google.com/status")!
    private static let aiStudioStatusRPCURL = URL(
        string: "https://alkalimakersuite-pa.clients6.google.com/$rpc/" +
            "google.internal.alkali.applications.makersuite.v1.MakerSuiteService/ListIncidentsHistory")!

    /// Google AI Studio publishes incidents through the same public RPC used by its status page.
    /// The page embeds a browser-restricted public key which may rotate, so resolve it at runtime
    /// instead of shipping Google's key in the app.
    @concurrent
    package static func fetchAIStudioStatus(
        transport: any ProviderHTTPTransport = ProviderHTTPClient.shared)
        async throws -> ProviderStatus
    {
        var pageRequest = URLRequest(url: Self.aiStudioStatusPageURL)
        pageRequest.timeoutInterval = 10
        let (pageData, _) = try await transport.data(for: pageRequest)
        let apiKey = try Self.parseAIStudioPublicAPIKey(data: pageData)

        var request = URLRequest(url: Self.aiStudioStatusRPCURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.httpBody = Data("[]".utf8)
        request.setValue("application/json+protobuf", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("https://aistudio.google.com/", forHTTPHeaderField: "Referer")
        request.setValue("https://aistudio.google.com", forHTTPHeaderField: "Origin")
        let (data, _) = try await transport.data(for: request)
        return try Self.parseAIStudioIncidentHistory(data: data)
    }

    package static func parseAIStudioPublicAPIKey(data: Data) throws -> String {
        guard let page = String(data: data, encoding: .utf8),
              let expression = try? NSRegularExpression(pattern: #"\"WIu0Nc\":\"(AIza[^\"]+)\""#),
              let match = expression.firstMatch(
                  in: page,
                  range: NSRange(page.startIndex..., in: page)),
              let keyRange = Range(match.range(at: 1), in: page)
        else {
            throw URLError(.cannotParseResponse)
        }
        return String(page[keyRange])
    }

    package static func parseAIStudioIncidentHistory(data: Data) throws -> ProviderStatus {
        let root = try JSONSerialization.jsonObject(with: data)
        let incidents = Self.aiStudioIncidentArrays(in: root)
        let active = incidents.compactMap(Self.aiStudioActiveIncident)
        guard let worst = active.max(by: {
            Self.indicatorRank($0.indicator) < Self.indicatorRank($1.indicator)
        }) else {
            return ProviderStatus(indicator: .none, description: nil, updatedAt: nil)
        }
        return ProviderStatus(
            indicator: worst.indicator,
            description: worst.description,
            updatedAt: worst.updatedAt)
    }

    private static func aiStudioIncidentArrays(in value: Any) -> [[Any]] {
        guard let array = value as? [Any] else { return [] }
        if array.count >= 4,
           array[0] is String,
           array[1] is String,
           array[3] is [Any]
        {
            return [array]
        }
        return array.flatMap(Self.aiStudioIncidentArrays)
    }

    private static func aiStudioActiveIncident(
        _ incident: [Any])
        -> (indicator: ProviderStatusIndicator, description: String, updatedAt: Date?)?
    {
        guard incident.count >= 4,
              let title = incident[1] as? String,
              let updates = incident[3] as? [Any],
              let latest = updates.last as? [Any],
              let state = latest.first as? NSNumber,
              state.intValue != 4
        else { return nil }

        let severity = (incident[2] as? NSNumber)?.intValue ?? 1
        let indicator: ProviderStatusIndicator = severity >= 2 ? .major : .minor
        let updateText = latest.count > 3 ? latest[3] as? String : nil
        let updatedAt = Self.aiStudioUpdateDate(latest)
        return (indicator, updateText ?? title, updatedAt)
    }

    private static func aiStudioUpdateDate(_ update: [Any]) -> Date? {
        guard update.count > 2,
              let timestamps = update[2] as? [Any],
              let raw = timestamps.first as? String,
              let seconds = TimeInterval(raw)
        else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    /// DeepSeek's status site is FlashDuty-backed and does not expose Statuspage's `/api/v2` API.
    /// Its public RSS feed keeps the newest incident first and includes the current incident state.
    @concurrent
    package static func fetchDeepSeekStatus(
        from feedURL: URL,
        transport: any ProviderHTTPTransport = ProviderHTTPClient.shared)
        async throws -> ProviderStatus
    {
        var request = URLRequest(url: feedURL)
        request.timeoutInterval = 10
        let (data, _) = try await transport.data(for: request)
        return try Self.parseDeepSeekRSSStatus(data: data)
    }

    package static func parseDeepSeekRSSStatus(data: Data) throws -> ProviderStatus {
        guard let xml = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        guard let item = Self.firstRSSItem(in: xml) else {
            return ProviderStatus(indicator: .none, description: nil, updatedAt: nil)
        }

        let title = Self.normalizedRSSField(Self.rssValue(named: "title", in: item))
        let description = Self.normalizedRSSField(Self.rssValue(named: "description", in: item))
        let status = Self.deepSeekIncidentStatus(from: description)
        let indicator = Self.deepSeekIndicator(status: status, title: title)
        let updatedAt = Self.deepSeekRSSDate(Self.rssValue(named: "pubDate", in: item))

        return ProviderStatus(
            indicator: indicator,
            description: indicator == .none ? nil : title,
            updatedAt: updatedAt)
    }

    private static func firstRSSItem(in xml: String) -> Substring? {
        guard let start = xml.range(of: "<item>"),
              let end = xml.range(of: "</item>", range: start.upperBound..<xml.endIndex)
        else { return nil }
        return xml[start.upperBound..<end.lowerBound]
    }

    private static func rssValue(named name: String, in item: Substring) -> String? {
        let opening = "<\(name)>"
        let closing = "</\(name)>"
        guard let start = item.range(of: opening),
              let end = item.range(of: closing, range: start.upperBound..<item.endIndex)
        else { return nil }
        return String(item[start.upperBound..<end.lowerBound])
    }

    private static func normalizedRSSField(_ value: String?) -> String? {
        guard var value else { return nil }
        let entities = [
            "&lt;": "<",
            "&gt;": ">",
            "&amp;": "&",
            "&quot;": "\"",
            "&#39;": "'",
            "&#xA;": "\n",
            "&#10;": "\n",
        ]
        for (entity, replacement) in entities {
            value = value.replacingOccurrences(of: entity, with: replacement)
        }
        value = value.replacingOccurrences(of: "</p>", with: "\n", options: .caseInsensitive)
        value = value.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: "",
            options: .regularExpression)
        let normalized = value
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return normalized.isEmpty ? nil : normalized
    }

    private static func deepSeekIncidentStatus(from description: String?) -> String? {
        guard let description else { return nil }
        for line in description.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.lowercased().hasPrefix("status:") else { continue }
            return trimmed.dropFirst("status:".count).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private static func deepSeekIndicator(status: String?, title: String?) -> ProviderStatusIndicator {
        let status = status?.lowercased() ?? ""
        let title = title?.lowercased() ?? ""
        if status.contains("resolved") || status.contains("operational") {
            return .none
        }
        if status.contains("maintenance") {
            return .maintenance
        }
        if status.contains("monitoring") || title.contains("degraded") || title.contains("性能下降") {
            return .minor
        }
        if title.contains("partial") || title.contains("部分") {
            return .major
        }
        if title.contains("unavailable") || title.contains("outage") || title.contains("中断") {
            return .critical
        }
        if status.contains("investigating") || status.contains("identified") || !status.isEmpty {
            return .major
        }
        return .unknown
    }

    private static func deepSeekRSSDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.date(from: raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Status feeds decode off the main actor: the Google Workspace incidents payload alone
    /// can be hundreds of kilobytes and cost 150-340ms to decode (#1399), and these helpers
    /// touch no store state.
    @concurrent
    package static func fetchStatus(
        from baseURL: URL,
        transport: any ProviderHTTPTransport = ProviderHTTPClient.shared)
        async throws -> ProviderStatus
    {
        let apiURL = baseURL.appendingPathComponent("api/v2/status.json")
        var request = URLRequest(url: apiURL)
        request.timeoutInterval = 10

        let (data, _) = try await transport.data(for: request)

        return try Self.parseStatuspageStatus(data: data)
    }

    /// Resolves the provider's status and component list.
    ///
    /// OpenAI's status page is powered by incident.io, whose native feed groups components
    /// (APIs / ChatGPT / Codex / FedRAMP) — so we try that first. Classic Atlassian
    /// statuspage.io pages (Claude, Cursor, GitHub) expose a flat `api/v2` feed, which we fall
    /// back to. `components.json` is used for the flat list because `summary.json` omits unlisted
    /// components such as "FedRAMP".
    @concurrent
    package static func fetchStatusSummary(
        from baseURL: URL,
        transport: any ProviderHTTPTransport = ProviderHTTPClient.shared)
        async throws -> (status: ProviderStatus, components: [ProviderStatusComponent]?)
    {
        // incident.io native feed (grouped): https://<host>/proxy/<host>
        if let host = baseURL.host,
           let proxyURL = URL(string: "https://\(host)/proxy/\(host)")
        {
            var proxyRequest = URLRequest(url: proxyURL)
            proxyRequest.timeoutInterval = 10
            if let (data, _) = try? await transport.data(for: proxyRequest),
               let parsed = try? Self.parseIncidentIOSummary(data: data)
            {
                // The proxy feed derives the indicator from component leaves but carries no
                // top-level description or timestamp; fetch the summary endpoint so callers
                // get the full status banner.
                let overlay = try? await Self.fetchStatus(from: baseURL, transport: transport)
                let status = ProviderStatus(
                    indicator: parsed.status.indicator,
                    description: overlay?.description,
                    updatedAt: overlay?.updatedAt)
                return (status, parsed.components)
            }
        }

        // Classic statuspage.io fallback.
        var summaryRequest = URLRequest(url: baseURL.appendingPathComponent("api/v2/summary.json"))
        summaryRequest.timeoutInterval = 10
        var componentsRequest = URLRequest(url: baseURL.appendingPathComponent("api/v2/components.json"))
        componentsRequest.timeoutInterval = 10

        let (summaryData, _) = try await transport.data(for: summaryRequest)
        let status = try Self.parseStatuspageStatus(data: summaryData)
        let components: [ProviderStatusComponent]? = if let (componentsData, _) = try? await transport
            .data(for: componentsRequest)
        {
            try? Self.parseStatuspageComponents(data: componentsData)
        } else {
            nil
        }
        return (status, components)
    }

    /// Parses incident.io's native status-page summary (`/proxy/<host>`). Groups come from
    /// `structure.items`; per-component statuses come from `affected_components` (anything not
    /// listed there is operational). A group's status aggregates the worst of its children.
    package static func parseIncidentIOSummary(
        data: Data)
        throws -> (status: ProviderStatus, components: [ProviderStatusComponent])
    {
        // The incident.io payload mirrors a deeply nested JSON shape; the response models follow it
        // 1:1 for clarity, which exceeds the default type-nesting depth.
        // swiftlint:disable nesting
        struct Response: Decodable {
            struct Summary: Decodable {
                struct AffectedComponent: Decodable {
                    let componentID: String
                    let status: String?
                    private enum CodingKeys: String, CodingKey {
                        case componentID = "component_id"
                        case status
                    }
                }

                struct Structure: Decodable {
                    struct Item: Decodable {
                        struct Group: Decodable {
                            struct Child: Decodable {
                                let componentID: String
                                let name: String?
                                let hidden: Bool?
                                private enum CodingKeys: String, CodingKey {
                                    case componentID = "component_id"
                                    case name, hidden
                                }
                            }

                            let id: String
                            let name: String?
                            let hidden: Bool?
                            let components: [Child]?
                        }

                        struct Component: Decodable {
                            let componentID: String
                            let name: String?
                            let hidden: Bool?
                            private enum CodingKeys: String, CodingKey {
                                case componentID = "component_id"
                                case name, hidden
                            }
                        }

                        let group: Group?
                        let component: Component?
                    }

                    let items: [Item]?
                }

                let affectedComponents: [AffectedComponent]?
                let structure: Structure?
                private enum CodingKeys: String, CodingKey {
                    case affectedComponents = "affected_components"
                    case structure
                }
            }

            let summary: Summary?
        }
        // swiftlint:enable nesting

        let response = try JSONDecoder().decode(Response.self, from: data)
        guard let summary = response.summary,
              let items = summary.structure?.items,
              !items.isEmpty
        else {
            throw URLError(.cannotParseResponse)
        }

        var statusByID: [String: String] = [:]
        for affected in summary.affectedComponents ?? [] {
            statusByID[affected.componentID] = affected.status
        }

        func leaf(id: String, name: String) -> ProviderStatusComponent {
            let raw = statusByID[id] ?? "operational"
            return ProviderStatusComponent(
                id: id,
                name: name,
                indicator: ProviderStatusComponent.indicator(forStatuspageStatus: raw),
                status: raw)
        }

        var topLevel: [ProviderStatusComponent] = []
        for item in items {
            if let group = item.group, group.hidden != true {
                let children = (group.components ?? [])
                    .filter { $0.hidden != true }
                    .compactMap { child -> ProviderStatusComponent? in
                        guard let name = Self.normalizedStatusComponentName(child.name) else { return nil }
                        return leaf(id: child.componentID, name: name)
                    }
                guard let groupName = Self.normalizedStatusComponentName(group.name) else { continue }
                let worst = children.max { Self.indicatorRank($0.indicator) < Self.indicatorRank($1.indicator) }
                topLevel.append(ProviderStatusComponent(
                    id: group.id,
                    name: groupName,
                    indicator: worst?.indicator ?? .none,
                    status: worst?.status ?? "operational",
                    children: children))
            } else if let component = item.component,
                      component.hidden != true,
                      let name = Self.normalizedStatusComponentName(component.name)
            {
                topLevel.append(leaf(id: component.componentID, name: name))
            }
        }

        let leaves = topLevel.flatMap { $0.isGroup ? $0.children : [$0] }
        let overall = leaves.max { Self.indicatorRank($0.indicator) < Self.indicatorRank($1.indicator) }
        let status = ProviderStatus(
            indicator: overall?.indicator ?? .none,
            description: nil,
            updatedAt: nil)
        return (status, topLevel)
    }

    package static func parseStatuspageStatus(data: Data) throws -> ProviderStatus {
        struct Response: Decodable {
            struct Status: Decodable {
                let indicator: String
                let description: String?
            }

            struct Page: Decodable {
                let updatedAt: Date?

                private enum CodingKeys: String, CodingKey {
                    case updatedAt = "updated_at"
                }
            }

            let page: Page?
            let status: Status
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = StatusFeedDateParser.decodingStrategy()
        let response = try decoder.decode(Response.self, from: data)
        let indicator = ProviderStatusIndicator(rawValue: response.status.indicator) ?? .unknown
        return ProviderStatus(
            indicator: indicator,
            description: response.status.description,
            updatedAt: response.page?.updatedAt)
    }

    package static func parseStatuspageComponents(data: Data) throws -> [ProviderStatusComponent] {
        struct Response: Decodable {
            struct Component: Decodable {
                let id: String
                let name: String
                let status: String
                let group: Bool?
                let groupID: String?
                let position: Int?

                private enum CodingKeys: String, CodingKey {
                    case id, name, status, group, position
                    case groupID = "group_id"
                }
            }

            let components: [Component]?
        }

        let response = try JSONDecoder().decode(Response.self, from: data)
        let raw = (response.components ?? [])
            .filter { Self.normalizedStatusComponentName($0.name) != nil }
            .sorted { ($0.position ?? 0) < ($1.position ?? 0) }

        func makeRow(
            _ component: Response.Component,
            children: [ProviderStatusComponent]) -> ProviderStatusComponent
        {
            ProviderStatusComponent(
                id: component.id,
                name: Self.normalizedStatusComponentName(component.name) ?? component.name,
                indicator: ProviderStatusComponent.indicator(forStatuspageStatus: component.status),
                status: component.status,
                children: children)
        }

        // Children keyed by their parent group id, preserving position order.
        var childrenByGroup: [String: [ProviderStatusComponent]] = [:]
        for component in raw where component.group != true {
            guard let groupID = component.groupID else { continue }
            childrenByGroup[groupID, default: []].append(makeRow(component, children: []))
        }

        // Top-level rows: groups (with their children) and ungrouped leaf components, in order.
        return raw.compactMap { component in
            if component.group == true {
                return makeRow(component, children: childrenByGroup[component.id] ?? [])
            }
            // Skip leaves that belong to a group; they are rendered inside the group's dropdown.
            if component.groupID != nil { return nil }
            return makeRow(component, children: [])
        }
    }

    private nonisolated static func normalizedStatusComponentName(_ name: String?) -> String? {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
        return name
    }

    @concurrent
    package static func fetchWorkspaceStatus(
        productID: String,
        transport: any ProviderHTTPTransport = ProviderHTTPClient.shared,
        beforeDecoding: (@Sendable () -> Void)? = nil)
        async throws -> ProviderStatus
    {
        guard let url = URL(string: "https://www.google.com/appsstatus/dashboard/incidents.json") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (data, _) = try await transport.data(for: request)
        beforeDecoding?()
        return try Self.parseGoogleWorkspaceStatus(data: data, productID: productID)
    }

    package static func parseGoogleWorkspaceStatus(data: Data, productID: String) throws -> ProviderStatus {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = StatusFeedDateParser.decodingStrategy()

        let incidents = try decoder.decode([GoogleWorkspaceIncident].self, from: data)
        let active = incidents.filter { $0.isRelevant(productID: productID) && $0.isActive }
        guard !active.isEmpty else {
            return ProviderStatus(indicator: .none, description: nil, updatedAt: nil)
        }

        var best: (
            indicator: ProviderStatusIndicator,
            incident: GoogleWorkspaceIncident,
            update: GoogleWorkspaceUpdate?)
        best = (indicator: .none, incident: active[0], update: active[0].mostRecentUpdate ?? active[0].updates?.last)

        for incident in active {
            let update = incident.mostRecentUpdate ?? incident.updates?.last
            let indicator = Self.workspaceIndicator(
                status: update?.status ?? incident.statusImpact,
                severity: incident.severity)
            if Self.indicatorRank(indicator) <= Self.indicatorRank(best.indicator) { continue }
            best = (indicator: indicator, incident: incident, update: update)
        }

        let description = Self.workspaceSummary(from: best.update?.text ?? best.incident.externalDesc)
        let updatedAt = best.update?.when ?? best.incident.modified ?? best.incident.begin
        return ProviderStatus(indicator: best.indicator, description: description, updatedAt: updatedAt)
    }

    private nonisolated static func indicatorRank(_ indicator: ProviderStatusIndicator) -> Int {
        switch indicator {
        case .none: 0
        case .maintenance: 1
        case .minor: 2
        case .major: 3
        case .critical: 4
        case .unknown: 1
        }
    }

    private nonisolated static func workspaceIndicator(status: String?, severity: String?) -> ProviderStatusIndicator {
        switch status?.uppercased() {
        case "AVAILABLE": return .none
        case "SERVICE_INFORMATION": return .minor
        case "SERVICE_DISRUPTION": return .major
        case "SERVICE_OUTAGE": return .critical
        case "SERVICE_MAINTENANCE", "SCHEDULED_MAINTENANCE": return .maintenance
        default: break
        }

        switch severity?.lowercased() {
        case "low": return .minor
        case "medium": return .major
        case "high": return .critical
        default: return .minor
        }
    }

    private nonisolated static func workspaceSummary(from text: String?) -> String? {
        guard let text else { return nil }
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: true)
        for rawLine in lines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            let lower = trimmed.lowercased()
            if lower.hasPrefix("**summary") || lower.hasPrefix("**description") || lower == "summary" {
                continue
            }
            var cleaned = trimmed.replacingOccurrences(of: "**", with: "")
            cleaned = cleaned.replacingOccurrences(
                of: #"\[([^\]]+)\]\([^)]+\)"#,
                with: "$1",
                options: .regularExpression)
            if cleaned.hasPrefix("- ") {
                cleaned.removeFirst(2)
            }
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty { return cleaned }
        }
        return nil
    }

    private struct GoogleWorkspaceIncident: Decodable {
        let begin: Date?
        let end: Date?
        let modified: Date?
        let externalDesc: String?
        let statusImpact: String?
        let severity: String?
        let affectedProducts: [GoogleWorkspaceProduct]?
        let currentlyAffectedProducts: [GoogleWorkspaceProduct]?
        let mostRecentUpdate: GoogleWorkspaceUpdate?
        let updates: [GoogleWorkspaceUpdate]?

        var isActive: Bool {
            self.end == nil
        }

        func isRelevant(productID: String) -> Bool {
            if let current = currentlyAffectedProducts {
                return current.contains(where: { $0.id == productID })
            }
            return self.affectedProducts?.contains(where: { $0.id == productID }) ?? false
        }
    }

    private struct GoogleWorkspaceProduct: Decodable {
        let title: String?
        let id: String
    }

    private struct GoogleWorkspaceUpdate: Decodable {
        let when: Date?
        let status: String?
        let text: String?
    }
}
