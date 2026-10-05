import CodexBarCore
import Foundation
import MoleWidgetCore
import Observation

enum ScapoliteTelegramCommand: Equatable {
    case help
    case status
    case usage
    case sessions
    case system
    case refresh
    case unknown(String)

    static func parse(_ text: String?) -> Self? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              text.hasPrefix("/")
        else { return nil }
        let token = text.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? text
        let command = token.split(separator: "@", maxSplits: 1).first.map(String.init)?.lowercased() ?? token
        return switch command {
        case "/start", "/help": .help
        case "/status": .status
        case "/usage": .usage
        case "/sessions": .sessions
        case "/system": .system
        case "/refresh": .refresh
        default: .unknown(command)
        }
    }
}

private struct ScapoliteTelegramTokenStore: Sendable {
    private let store = KeychainStringStore(
        account: "scapolite-telegram-bot-token",
        service: "com.taliyigit2.Scapolite",
        promptKind: .telegramToken,
        logCategory: "telegram")

    func load() throws -> String? {
        try self.store.load()
    }

    func loadWithoutUserInteraction() throws -> String? {
        try self.store.loadWithoutUserInteraction()
    }

    func save(_ token: String?) throws {
        try self.store.store(token, isValid: ScapoliteTelegramBotClient.isValidToken)
    }
}

@MainActor
@Observable
final class ScapoliteTelegramController {
    private enum DefaultsKey {
        static let enabled = "scapolite.telegram.enabled"
        static let chatID = "scapolite.telegram.chatID"
    }

    private let usageStore: UsageStore
    private let sessions: AgentSessionsStore
    private let serviceMonitor: ScapoliteServiceMonitor
    private let tokenStore = ScapoliteTelegramTokenStore()
    private let defaults: UserDefaults

    private(set) var isConfigured: Bool
    private(set) var isConnected = false
    private(set) var botUsername: String?
    private(set) var lastError: String?
    private(set) var chatID: String

    @ObservationIgnored private var client: ScapoliteTelegramBotClient?
    @ObservationIgnored private var pollTask: Task<Void, Never>?
    @ObservationIgnored private var nextUpdateOffset: Int?

    init(
        usageStore: UsageStore,
        sessions: AgentSessionsStore,
        serviceMonitor: ScapoliteServiceMonitor,
        defaults: UserDefaults = .standard)
    {
        self.usageStore = usageStore
        self.sessions = sessions
        self.serviceMonitor = serviceMonitor
        self.defaults = defaults
        self.isConfigured = defaults.bool(forKey: DefaultsKey.enabled)
        self.chatID = defaults.string(forKey: DefaultsKey.chatID) ?? ""
    }

    deinit {
        self.pollTask?.cancel()
    }

    func start() {
        guard self.isConfigured, self.pollTask == nil else { return }
        do {
            guard let token = try self.tokenStore.loadWithoutUserInteraction(),
                  ScapoliteTelegramBotClient.isValidToken(token),
                  Self.isValidChatID(self.chatID)
            else {
                self.isConfigured = false
                self.lastError = L("Telegram configuration is incomplete.")
                return
            }
            self.beginPolling(client: ScapoliteTelegramBotClient(token: token))
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func stop() {
        self.pollTask?.cancel()
        self.pollTask = nil
        self.client = nil
        self.isConnected = false
    }

    func connect(token: String, chatID: String) async {
        self.lastError = nil
        do {
            let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            let effectiveToken: String = if cleanToken.isEmpty, let stored = try self.tokenStore.load() {
                stored
            } else {
                cleanToken
            }
            guard ScapoliteTelegramBotClient.isValidToken(effectiveToken) else {
                throw ScapoliteTelegramError.invalidToken
            }
            let cleanChatID = chatID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard Self.isValidChatID(cleanChatID) else {
                throw ScapoliteTelegramError.invalidChatID
            }

            let client = ScapoliteTelegramBotClient(token: effectiveToken)
            let bot = try await client.getMe()
            try self.tokenStore.save(effectiveToken)
            self.chatID = cleanChatID
            self.defaults.set(cleanChatID, forKey: DefaultsKey.chatID)
            self.defaults.set(true, forKey: DefaultsKey.enabled)
            self.isConfigured = true
            self.botUsername = bot.username
            self.beginPolling(client: client)
        } catch {
            self.lastError = error.localizedDescription
            self.isConnected = false
        }
    }

    func discoverChatID(token: String) async -> String? {
        self.lastError = nil
        do {
            let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
            let effectiveToken = if cleanToken.isEmpty {
                try self.tokenStore.load()
            } else {
                cleanToken
            }
            guard let effectiveToken, ScapoliteTelegramBotClient.isValidToken(effectiveToken) else {
                throw ScapoliteTelegramError.invalidToken
            }
            let client = ScapoliteTelegramBotClient(token: effectiveToken)
            let updates = try await client.getUpdates(offset: nil, timeout: 0)
            guard let discovered = updates.reversed().compactMap(\.message?.chat.id).first else {
                throw ScapoliteTelegramError.noChatFound
            }
            return String(discovered)
        } catch {
            self.lastError = error.localizedDescription
            return nil
        }
    }

    func sendTestMessage() async {
        do {
            guard let client, Self.isValidChatID(self.chatID) else {
                throw ScapoliteTelegramError.notConfigured
            }
            try await client.sendMessage(
                chatID: self.chatID,
                text: "✅ Scapolite is connected. Use /help to see available commands.")
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func disconnect() {
        self.stop()
        do {
            try self.tokenStore.save(nil)
        } catch {
            self.lastError = error.localizedDescription
        }
        self.defaults.removeObject(forKey: DefaultsKey.chatID)
        self.defaults.set(false, forKey: DefaultsKey.enabled)
        self.chatID = ""
        self.botUsername = nil
        self.isConfigured = false
    }

    func sendServiceTransition(_ transition: ScapoliteServiceTransition) {
        guard self.isConfigured, let client else { return }
        let recovered = transition.current.indicator == .none
        let icon = recovered ? "✅" : "🚨"
        let title = recovered ? "Service recovered" : "Service disruption detected"
        var lines = ["\(icon) \(title)", transition.current.service.name]
        if let detail = transition.current.detail, !detail.isEmpty {
            lines.append(detail)
        }
        lines.append(transition.current.service.statusURL.absoluteString)
        let chatID = self.chatID
        Task {
            try? await client.sendMessage(chatID: chatID, text: lines.joined(separator: "\n"))
        }
    }

    private func beginPolling(client: ScapoliteTelegramBotClient) {
        self.stop()
        self.client = client
        self.isConnected = true
        self.lastError = nil
        self.pollTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    let updates = try await client.getUpdates(offset: self.nextUpdateOffset, timeout: 25)
                    for update in updates {
                        self.nextUpdateOffset = update.updateID + 1
                        await self.handle(update, client: client)
                    }
                    self.isConnected = true
                    self.lastError = nil
                } catch is CancellationError {
                    return
                } catch {
                    self.isConnected = false
                    self.lastError = error.localizedDescription
                    do {
                        try await Task.sleep(for: .seconds(5))
                    } catch {
                        return
                    }
                }
            }
        }
    }

    private func handle(_ update: ScapoliteTelegramUpdate, client: ScapoliteTelegramBotClient) async {
        guard let message = update.message,
              String(message.chat.id) == self.chatID,
              let command = ScapoliteTelegramCommand.parse(message.text)
        else { return }

        let response: String
        switch command {
        case .help:
            response = Self.helpText
        case .status:
            response = self.statusSummary()
        case .usage:
            response = self.usageSummary()
        case .sessions:
            response = self.sessionsSummary()
        case .system:
            response = await self.systemSummary()
        case .refresh:
            await self.serviceMonitor.refresh()
            await self.usageStore.refreshForSettingsChange()
            response = "✅ Scapolite data refreshed."
        case let .unknown(name):
            response = "Unknown command: \(name)\n\n\(Self.helpText)"
        }

        do {
            try await client.sendMessage(chatID: self.chatID, text: String(response.prefix(4000)))
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    private func statusSummary() -> String {
        let lines = self.serviceMonitor.health.map { health in
            "\(Self.statusEmoji(health.indicator)) \(health.service.name): \(Self.statusLabel(health.indicator))"
        }
        return (["Scapolite service status"] + lines).joined(separator: "\n")
    }

    private func usageSummary() -> String {
        let lines = self.usageStore.enabledFirstPartyProvidersForDisplay().map { provider in
            let name = self.usageStore.metadata(for: provider).displayName
            guard let snapshot = self.usageStore.presentationSnapshot(for: provider) else {
                return "• \(name): unavailable"
            }
            let remaining = [snapshot.primary, snapshot.secondary, snapshot.tertiary]
                .compactMap { $0?.measured }
                .map { "\(Int($0.remainingPercent.rounded()))%" }
            return "• \(name): \(remaining.isEmpty ? "no quota data" : remaining.joined(separator: " / "))"
        }
        return (["Scapolite AI usage (remaining)"] + lines).joined(separator: "\n")
    }

    private func sessionsSummary() -> String {
        let local = self.sessions.localSessions.prefix(15).map { session in
            // Provider-specific by design: Telegram distinguishes Claude Code from the Codex-compatible session label.
            let provider = session.provider == .claude ? "Claude Code" : "Codex"
            let state = session.state == .active ? "active" : "idle"
            let title = session.sessionName ?? session.projectName ?? "Untitled"
            return "• \(provider) · \(state) · \(title)"
        }
        let remoteCount = self.sessions.remoteHosts.reduce(0) { $0 + $1.sessions.count }
        var lines = ["Scapolite sessions", "Local: \(self.sessions.localSessions.count) · Remote: \(remoteCount)"]
        lines.append(contentsOf: local)
        return lines.joined(separator: "\n")
    }

    private func systemSummary() async -> String {
        let metrics = MetricsStore()
        metrics.refreshFast()
        metrics.refreshDiskUsage()
        metrics.refreshPower()
        do {
            try await Task.sleep(for: .milliseconds(400))
        } catch {
            return "System snapshot cancelled."
        }
        metrics.refreshFast()

        var lines = ["Scapolite system health", "Health score: \(metrics.healthScore)/100"]
        if let cpu = metrics.cpu?.totalUsage {
            lines.append("CPU: \(Int((cpu * 100).rounded()))%")
        }
        if let memory = metrics.memory {
            lines.append("Memory: \(Int((memory.usedFraction * 100).rounded()))%")
        }
        if let disk = metrics.diskUsage {
            lines.append("Disk: \(Int((disk.usedFraction * 100).rounded()))%")
        }
        if let power = metrics.power {
            lines.append("Battery: \(Int((power.levelFraction * 100).rounded()))%")
        }
        if let temperature = metrics.cpuTemperature {
            lines.append(String(format: "CPU temperature: %.1f °C", temperature))
        }
        return lines.joined(separator: "\n")
    }

    private static func isValidChatID(_ chatID: String) -> Bool {
        guard let value = Int64(chatID), value != 0 else { return false }
        return true
    }

    private static func statusEmoji(_ indicator: ProviderStatusIndicator) -> String {
        switch indicator {
        case .none: "✅"
        case .minor: "⚠️"
        case .major, .critical: "🚨"
        case .maintenance: "🛠️"
        case .unknown: "❔"
        }
    }

    private static func statusLabel(_ indicator: ProviderStatusIndicator) -> String {
        switch indicator {
        case .none: "operational"
        case .minor: "minor issue"
        case .major: "partial outage"
        case .critical: "major outage"
        case .maintenance: "maintenance"
        case .unknown: "unknown"
        }
    }

    private static let helpText = """
    Scapolite Telegram commands
    /status — AI service health
    /usage — remaining AI quotas
    /sessions — recent Claude Code and Codex sessions
    /system — Mac system health
    /refresh — refresh status and usage
    /help — show this message
    """
}

private enum ScapoliteTelegramError: LocalizedError {
    case invalidToken
    case invalidChatID
    case noChatFound
    case notConfigured
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidToken: "The Telegram bot token is invalid."
        case .invalidChatID: "The Telegram chat ID is invalid."
        case .noChatFound: "No chat found. Send /start to the bot in Telegram, then try again."
        case .notConfigured: "Telegram is not configured."
        case let .api(message): message
        }
    }
}

private struct ScapoliteTelegramBot: Decodable, Sendable {
    let username: String?
}

struct ScapoliteTelegramUpdate: Decodable, Sendable {
    let updateID: Int
    let message: ScapoliteTelegramMessage?

    private enum CodingKeys: String, CodingKey {
        case updateID = "update_id"
        case message
    }
}

struct ScapoliteTelegramMessage: Decodable, Sendable {
    let text: String?
    let chat: ScapoliteTelegramChat
}

struct ScapoliteTelegramChat: Decodable, Sendable {
    let id: Int64
}

private struct ScapoliteTelegramEnvelope<Value: Decodable & Sendable>: Decodable, Sendable {
    let ok: Bool
    let result: Value?
    let description: String?
}

private actor ScapoliteTelegramBotClient {
    private let token: String
    private let session: URLSession

    init(token: String) {
        self.token = token
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 35
        configuration.waitsForConnectivity = false
        self.session = URLSession(configuration: configuration)
    }

    static func isValidToken(_ token: String) -> Bool {
        token.range(of: #"^[0-9]{5,}:[A-Za-z0-9_-]{20,}$"#, options: .regularExpression) != nil
    }

    func getMe() async throws -> ScapoliteTelegramBot {
        try await self.call("getMe", body: [:], as: ScapoliteTelegramBot.self)
    }

    func getUpdates(offset: Int?, timeout: Int) async throws -> [ScapoliteTelegramUpdate] {
        var body: [String: Any] = [
            "timeout": timeout,
            "allowed_updates": ["message"],
        ]
        if let offset { body["offset"] = offset }
        return try await self.call("getUpdates", body: body, as: [ScapoliteTelegramUpdate].self)
    }

    func sendMessage(chatID: String, text: String) async throws {
        _ = try await self.call(
            "sendMessage",
            body: ["chat_id": chatID, "text": text],
            as: ScapoliteTelegramMessage.self)
    }

    private func call<Value: Decodable & Sendable>(
        _ method: String,
        body: [String: Any],
        as type: Value.Type)
        async throws -> Value
    {
        _ = type
        guard let url = URL(string: "https://api.telegram.org/bot\(self.token)/\(method)") else {
            throw ScapoliteTelegramError.invalidToken
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await self.session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ScapoliteTelegramError.api("Telegram returned an HTTP error.")
        }
        let envelope = try JSONDecoder().decode(ScapoliteTelegramEnvelope<Value>.self, from: data)
        guard envelope.ok, let result = envelope.result else {
            throw ScapoliteTelegramError.api(envelope.description ?? "Telegram request failed.")
        }
        return result
    }
}
