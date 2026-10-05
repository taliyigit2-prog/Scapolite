import CodexBarCore
import Foundation
import Observation

struct ScapoliteMonitoredService: Identifiable, Sendable {
    enum Source: Sendable {
        case statuspage(URL)
        case aiStudio
        case deepSeek(URL)
    }

    let id: String
    let name: String
    let statusURL: URL
    let source: Source
}

struct ScapoliteServiceHealth: Identifiable, Sendable {
    let service: ScapoliteMonitoredService
    let indicator: ProviderStatusIndicator
    let detail: String?
    let updatedAt: Date?

    var id: String {
        self.service.id
    }
}

struct ScapoliteServiceTransition: Sendable {
    let previous: ScapoliteServiceHealth
    let current: ScapoliteServiceHealth
}

enum ScapoliteServiceTransitionPolicy {
    static func transition(
        previous: ScapoliteServiceHealth?,
        current: ScapoliteServiceHealth)
        -> ScapoliteServiceTransition?
    {
        guard let previous,
              previous.indicator != .unknown,
              current.indicator != .unknown,
              previous.indicator != current.indicator
        else { return nil }
        return ScapoliteServiceTransition(previous: previous, current: current)
    }
}

@MainActor
@Observable
final class ScapoliteServiceMonitor {
    static let services: [ScapoliteMonitoredService] = [
        // Provider-specific by design: these are the user-requested official AI status services monitored by Scapolite.
        ScapoliteMonitoredService(
            id: "openai",
            name: "OpenAI",
            statusURL: URL(string: "https://status.openai.com/")!,
            source: .statuspage(URL(string: "https://status.openai.com/")!)),
        ScapoliteMonitoredService(
            id: "claude",
            name: "Claude",
            statusURL: URL(string: "https://status.claude.com/")!,
            source: .statuspage(URL(string: "https://status.claude.com/")!)),
        ScapoliteMonitoredService(
            id: "google-ai-studio",
            name: "Google AI Studio & Gemini API",
            statusURL: URL(string: "https://aistudio.google.com/status")!,
            source: .aiStudio),
        ScapoliteMonitoredService(
            id: "cursor",
            name: "Cursor",
            statusURL: URL(string: "https://status.cursor.com/")!,
            source: .statuspage(URL(string: "https://status.cursor.com/")!)),
        ScapoliteMonitoredService(
            id: "copilot",
            name: "GitHub Copilot",
            statusURL: URL(string: "https://copilot.statuspage.io/")!,
            source: .statuspage(URL(string: "https://copilot.statuspage.io/")!)),
        ScapoliteMonitoredService(
            id: "deepseek",
            name: "DeepSeek",
            statusURL: URL(string: "https://status.deepseek.com/")!,
            source: .deepSeek(URL(string: "https://status.deepseek.com/feed.rss")!)),
    ]

    private(set) var healthByServiceID: [String: ScapoliteServiceHealth] = [:]
    private(set) var isRefreshing = false
    private(set) var lastUpdatedAt: Date?

    @ObservationIgnored private var pollTask: Task<Void, Never>?
    @ObservationIgnored var onTransition: (@MainActor (ScapoliteServiceTransition) -> Void)?

    var health: [ScapoliteServiceHealth] {
        Self.services.map { service in
            self.healthByServiceID[service.id] ?? ScapoliteServiceHealth(
                service: service,
                indicator: .unknown,
                detail: nil,
                updatedAt: nil)
        }
    }

    func start() {
        guard self.pollTask == nil else { return }
        self.pollTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.refresh()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(120))
                } catch {
                    return
                }
                await self.refresh()
            }
        }
    }

    func stop() {
        self.pollTask?.cancel()
        self.pollTask = nil
    }

    func refresh() async {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
        defer { self.isRefreshing = false }

        let results = await withTaskGroup(
            of: (ScapoliteMonitoredService, ProviderStatus?).self,
            returning: [(ScapoliteMonitoredService, ProviderStatus?)].self)
        { group in
            for service in Self.services {
                group.addTask {
                    await (service, try? Self.fetch(service))
                }
            }
            var collected: [(ScapoliteMonitoredService, ProviderStatus?)] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        for (service, status) in results {
            guard let status else { continue }
            let next = ScapoliteServiceHealth(
                service: service,
                indicator: status.indicator,
                detail: status.description,
                updatedAt: status.updatedAt)
            if let transition = ScapoliteServiceTransitionPolicy.transition(
                previous: self.healthByServiceID[service.id],
                current: next)
            {
                self.onTransition?(transition)
            }
            self.healthByServiceID[service.id] = next
        }
        self.lastUpdatedAt = Date()
    }

    private nonisolated static func fetch(_ service: ScapoliteMonitoredService) async throws -> ProviderStatus {
        switch service.source {
        case let .statuspage(baseURL):
            try await ProviderStatusFetcher.fetchStatusSummary(from: baseURL).status
        case .aiStudio:
            try await ProviderStatusFetcher.fetchAIStudioStatus()
        case let .deepSeek(feedURL):
            try await ProviderStatusFetcher.fetchDeepSeekStatus(from: feedURL)
        }
    }
}
