import AppKit
import CodexBarCore
import MoleWidgetCore
import Observation
import SwiftUI

@MainActor
final class ScapoliteDashboardWindowController: NSWindowController, NSWindowDelegate {
    private let metrics = MetricsStore()
    private let selection = ScapoliteDashboardSelection()

    init(
        store: UsageStore,
        settings: SettingsStore,
        sessions: AgentSessionsStore,
        serviceMonitor: ScapoliteServiceMonitor,
        telegram: ScapoliteTelegramController,
        openSettings: @escaping @MainActor () -> Void)
    {
        let rootView = ScapoliteDashboardView(
            selection: self.selection,
            store: store,
            settings: settings,
            sessions: sessions,
            metrics: self.metrics,
            serviceMonitor: serviceMonitor,
            telegram: telegram,
            openSettings: openSettings)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.identifier = NSUserInterfaceItemIdentifier("com.taliyigit2.scapolite.dashboard")
        window.title = "Scapolite"
        window.setContentSize(NSSize(width: 920, height: 680))
        window.minSize = NSSize(width: 760, height: 540)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("Scapolite.DashboardWindow")
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func open(spend: Bool = false) {
        if spend { self.selection.tab = .spend }
        self.metrics.start()
        guard let window = self.window else { return }
        window.centerIfNeeded()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func stop() {
        self.metrics.stop()
    }

    func windowWillClose(_ notification: Notification) {
        _ = notification
        self.metrics.stop()
    }
}

extension NSWindow {
    fileprivate func centerIfNeeded() {
        guard UserDefaults.standard.string(forKey: "NSWindow Frame Scapolite.DashboardWindow") == nil else { return }
        self.center()
    }
}

private enum ScapoliteDashboardTab: String, CaseIterable, Identifiable {
    case usage
    case spend
    case sessions
    case system
    case status
    case telegram

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .usage: L("Usage")
        case .spend: L("Spend")
        case .sessions: L("Sessions")
        case .system: L("System")
        case .status: L("Service Status")
        case .telegram: "Telegram"
        }
    }

    var systemImage: String {
        switch self {
        case .usage: "chart.bar.fill"
        case .spend: "chart.line.uptrend.xyaxis"
        case .sessions: "bubble.left.and.bubble.right.fill"
        case .system: "cpu.fill"
        case .status: "waveform.path.ecg"
        case .telegram: "paperplane.fill"
        }
    }
}

@MainActor
@Observable
private final class ScapoliteDashboardSelection {
    var tab = ScapoliteDashboardTab.usage
}

private struct ScapoliteDashboardView: View {
    @Bindable var selection: ScapoliteDashboardSelection
    let store: UsageStore
    let settings: SettingsStore
    let sessions: AgentSessionsStore
    let metrics: MetricsStore
    let serviceMonitor: ScapoliteServiceMonitor
    let telegram: ScapoliteTelegramController
    let openSettings: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 0) {
            self.header
            Divider()
            Group {
                switch self.selection.tab {
                case .usage:
                    ScapoliteUsageView(store: self.store)
                case .spend:
                    SpendDashboardPane(settings: self.settings, store: self.store)
                case .sessions:
                    ScapoliteSessionsView(sessions: self.sessions)
                case .system:
                    ScapoliteSystemView(metrics: self.metrics)
                case .status:
                    ScapoliteStatusView(monitor: self.serviceMonitor)
                case .telegram:
                    ScapoliteTelegramView(controller: self.telegram)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .id(self.settings.appLanguage)
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Scapolite")
                    .font(.title2.weight(.semibold))
                Text(L("AI usage, sessions, system health, and service status"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker(L("Dashboard Section"), selection: self.$selection.tab) {
                ForEach(ScapoliteDashboardTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: 520)

            Button {
                self.openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help(L("Settings..."))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
}

private struct ScapoliteTelegramView: View {
    let controller: ScapoliteTelegramController

    @State private var token = ""
    @State private var chatID = ""
    @State private var isWorking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L("Your private Telegram bot"))
                            .font(.title3.weight(.semibold))
                        Text(L("Scapolite talks only to the bot and chat you configure on this Mac."))
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox(L("Setup")) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L("Create a bot with @BotFather, send /start to it, then paste the bot token below."))
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        LabeledContent(L("Bot token")) {
                            SecureField(
                                self.controller.isConfigured ? L("Leave blank to keep the saved token") : "123456:ABC…",
                                text: self.$token)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 420)
                        }

                        LabeledContent(L("Chat ID")) {
                            TextField("123456789", text: self.$chatID)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 260)
                        }

                        HStack {
                            Button(L("Discover Chat ID")) {
                                self.run {
                                    if let discovered = await self.controller.discoverChatID(token: self.token) {
                                        self.chatID = discovered
                                    }
                                }
                            }
                            .disabled(self.isWorking)

                            Button(self.controller.isConfigured ? L("Save Connection") : L("Connect Bot")) {
                                self.run {
                                    await self.controller.connect(token: self.token, chatID: self.chatID)
                                    if self.controller.isConfigured {
                                        self.token = ""
                                        self.chatID = self.controller.chatID
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(self.isWorking || self.chatID.isEmpty)
                        }
                    }
                    .padding(8)
                }

                GroupBox(L("Connection")) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(self.controller.isConnected ? Color.green : Color.secondary)
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(self.connectionTitle)
                                .font(.headline)
                            if let username = self.controller.botUsername {
                                Text("@\(username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button(L("Send Test")) {
                            self.run { await self.controller.sendTestMessage() }
                        }
                        .disabled(!self.controller.isConfigured || self.isWorking)
                        Button(L("Disconnect"), role: .destructive) {
                            self.controller.disconnect()
                            self.token = ""
                            self.chatID = ""
                        }
                        .disabled(!self.controller.isConfigured)
                    }
                    .padding(8)
                }

                if let error = self.controller.lastError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                }

                GroupBox(L("Commands")) {
                    Text("/status   /usage   /sessions   /system   /refresh   /help")
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .padding(8)
                }
            }
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if self.chatID.isEmpty {
                self.chatID = self.controller.chatID
            }
        }
    }

    private var connectionTitle: String {
        if self.controller.isConnected { return L("Connected") }
        if self.controller.isConfigured { return L("Reconnecting…") }
        return L("Not configured")
    }

    private func run(_ operation: @escaping @MainActor () async -> Void) {
        guard !self.isWorking else { return }
        self.isWorking = true
        Task { @MainActor in
            await operation()
            self.isWorking = false
        }
    }
}

private struct ScapoliteUsageView: View {
    let store: UsageStore

    var body: some View {
        let providers = self.store.enabledFirstPartyProvidersForDisplay()
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                ForEach(providers, id: \.rawValue) { provider in
                    ScapoliteUsageCard(store: self.store, provider: provider)
                }
            }
            .padding(24)
        }
        .overlay {
            if providers.isEmpty {
                ContentUnavailableView(
                    L("No providers enabled"),
                    systemImage: "chart.bar.xaxis",
                    description: Text(L("Enable providers in Settings to see usage and balances.")))
            }
        }
    }
}

private struct ScapoliteUsageCard: View {
    let store: UsageStore
    let provider: UsageProvider

    var body: some View {
        let metadata = self.store.metadata(for: self.provider)
        let snapshot = self.store.presentationSnapshot(for: self.provider)
        let accent = ProviderAccentPalette.color(for: self.provider)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle()
                    .fill(Color(red: accent.red, green: accent.green, blue: accent.blue))
                    .frame(width: 10, height: 10)
                Text(metadata.displayName)
                    .font(.headline)
                Spacer()
                if let updatedAt = snapshot?.updatedAt {
                    Text(updatedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if let snapshot {
                if let primary = snapshot.primary?.measured {
                    ScapoliteUsageBar(title: metadata.sessionLabel, window: primary, accent: accent)
                }
                if let secondary = snapshot.secondary?.measured {
                    ScapoliteUsageBar(title: metadata.weeklyLabel, window: secondary, accent: accent)
                }
                if let tertiary = snapshot.tertiary?.measured {
                    ScapoliteUsageBar(title: metadata.opusLabel ?? L("Additional"), window: tertiary, accent: accent)
                }
                ForEach(snapshot.extraRateWindows ?? [], id: \.id) { named in
                    ScapoliteUsageBar(
                        title: named.title, window: named.window, accent: accent, usageKnown: named.usageKnown)
                }
                if snapshot.primary == nil,
                   snapshot.secondary == nil,
                   snapshot.tertiary == nil,
                   snapshot.extraRateWindows?.isEmpty != false
                {
                    Text(L("No quota windows reported."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else if let error = self.store.userFacingError(for: self.provider) {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ScapoliteUsageBar: View {
    let title: String
    let window: RateWindow
    let accent: ProviderColor
    var usageKnown = true

    private var measured: Bool {
        self.usageKnown && !self.window.isSyntheticPlaceholder && self.window.usedPercent.isFinite
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(self.title)
                    .font(.caption.weight(.medium))
                Spacer()
                Text(self.measured
                    ? "\(Int(min(100, max(0, self.window.remainingPercent)).rounded()))% \(L("remaining"))" : "—")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if self.measured {
                ProgressView(value: min(100, max(0, self.window.usedPercent)), total: 100)
                    .tint(Color(red: self.accent.red, green: self.accent.green, blue: self.accent.blue))
            }
            if let resetsAt = self.window.resetsAt {
                Text("\(L("Resets")) \(resetsAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else if let detail = self.window.resetDescription, !detail.isEmpty {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct ScapoliteSessionsView: View {
    let sessions: AgentSessionsStore

    var body: some View {
        List {
            if !self.sessions.localSessions.isEmpty {
                Section(L("This Mac")) {
                    ForEach(self.sessions.localSessions) { session in
                        ScapoliteSessionRow(session: session, remoteHost: nil, sessions: self.sessions)
                    }
                }
            }
            ForEach(self.sessions.remoteHosts) { host in
                Section(host.host) {
                    if let error = host.error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(host.sessions) { session in
                        ScapoliteSessionRow(session: session, remoteHost: host.host, sessions: self.sessions)
                    }
                }
            }
        }
        .listStyle(.inset)
        .overlay {
            if !self.sessions.sessionDiscoveryEnabled {
                ContentUnavailableView {
                    Label(L("Session discovery is off"), systemImage: "eye.slash")
                } description: {
                    Text(L("Enable local discovery to list recent Claude Code and Codex CLI/App sessions."))
                } actions: {
                    Button(L("Enable Session Discovery")) {
                        self.sessions.enableSessionDiscovery()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if self.sessions.totalCount == 0 {
                ContentUnavailableView(
                    L("No sessions found"),
                    systemImage: "bubble.left.and.exclamationmark.bubble.right",
                    description: Text(L("Recent Claude Code and Codex CLI/App sessions appear here.")))
            }
        }
        .task {
            self.sessions.start()
            await self.sessions.refreshLocal()
        }
    }
}

private struct ScapoliteSessionRow: View {
    let session: AgentSession
    let remoteHost: String?
    let sessions: AgentSessionsStore

    var body: some View {
        Button {
            self.sessions.focus(self.session, remoteHost: self.remoteHost)
        } label: {
            HStack(spacing: 12) {
                // Provider-specific by design: Claude sessions use a distinct assistant glyph
                // in the shared session row.
                Image(systemName: self.session
                    .provider == .claude ? "sparkles" : "chevron.left.forwardslash.chevron.right")
                    .frame(width: 24)
                    .foregroundStyle(self.session.state == .active ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(self.title)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(self.providerName)
                        Text("•")
                        Text(self.session.source.rawValue)
                        if let cwd = self.session.cwd {
                            Text("•")
                            Text(URL(fileURLWithPath: cwd).lastPathComponent)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if let lastActivityAt = self.session.lastActivityAt {
                    Text(lastActivityAt, style: .relative)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                Image(systemName: "arrow.up.forward.app")
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        self.session.sessionName ?? self.session.projectName ?? L("Untitled Session")
    }

    private var providerName: String {
        // Provider-specific by design: session discovery supports only these three agent families and their dialects.
        switch self.session.provider {
        case .claude: "Claude Code"
        case .codex: "Codex"
        case .pi: self.session.dialect == .omp ? "OpenCode" : "Pi"
        }
    }
}

private struct ScapoliteSystemView: View {
    let metrics: MetricsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let info = self.metrics.systemInfo {
                    HStack {
                        Label(info.chip, systemImage: "desktopcomputer")
                        Spacer()
                        Text("macOS \(info.osVersion) · \(SystemInfoSnapshot.formatUptime(info.uptime))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 14)], spacing: 14) {
                    ScapoliteMetricCard(
                        title: L("CPU"),
                        value: self.percent(self.metrics.cpu?.totalUsage),
                        detail: self.loadDetail,
                        progress: self.metrics.cpu?.totalUsage,
                        systemImage: "cpu")
                    ScapoliteMetricCard(
                        title: L("Memory"),
                        value: self.percent(self.metrics.memory?.usedFraction),
                        detail: self.memoryDetail,
                        progress: self.metrics.memory?.usedFraction,
                        systemImage: "memorychip")
                    ScapoliteMetricCard(
                        title: L("Disk"),
                        value: self.percent(self.metrics.diskUsage?.usedFraction),
                        detail: self.diskDetail,
                        progress: self.metrics.diskUsage?.usedFraction,
                        systemImage: "internaldrive")
                    ScapoliteMetricCard(
                        title: L("Network"),
                        value: self.networkValue,
                        detail: self.networkDetail,
                        progress: nil,
                        systemImage: "network")
                    ScapoliteMetricCard(
                        title: L("Battery"),
                        value: self.percent(self.metrics.power?.levelFraction),
                        detail: self.powerDetail,
                        progress: self.metrics.power?.levelFraction,
                        systemImage: "battery.100percent")
                    ScapoliteMetricCard(
                        title: L("Health Score"),
                        value: "\(self.metrics.healthScore)",
                        detail: self.temperatureDetail,
                        progress: Double(self.metrics.healthScore) / 100,
                        systemImage: "heart.text.square")
                }

                GroupBox(L("Top Processes")) {
                    VStack(spacing: 0) {
                        ForEach(self.metrics.topProcesses.prefix(8), id: \.pid) { process in
                            HStack {
                                Text(process.name)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int((process.cpuFraction * 100).rounded()))% CPU")
                                    .monospacedDigit()
                                Text(Self.bytes(process.memoryBytes))
                                    .monospacedDigit()
                                    .frame(width: 90, alignment: .trailing)
                            }
                            .font(.callout)
                            .padding(.vertical, 6)
                            if process.pid != self.metrics.topProcesses.prefix(8).last?.pid {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(24)
        }
    }

    private var loadDetail: String? {
        guard let loadAverage = self.metrics.cpu?.loadAverage else { return nil }
        return loadAverage.map { String(format: "%.2f", $0) }.joined(separator: " / ")
    }

    private var memoryDetail: String? {
        guard let memory = self.metrics.memory else { return nil }
        return "\(Self.bytes(memory.used)) / \(Self.bytes(memory.total))"
    }

    private var diskDetail: String? {
        guard let disk = self.metrics.diskUsage else { return nil }
        return "\(Self.bytes(disk.used)) / \(Self.bytes(disk.total))"
    }

    private var networkValue: String {
        guard let rates = self.metrics.netRates else { return "—" }
        return "↓ \(Self.rate(rates.download))  ↑ \(Self.rate(rates.upload))"
    }

    private var networkDetail: String? {
        guard let info = self.metrics.networkInfo else { return nil }
        return [info.interfaceName, info.localIP].compactMap(\.self).joined(separator: " · ")
    }

    private var powerDetail: String? {
        guard let power = self.metrics.power else { return L("No battery") }
        var values = [power.isCharging ? L("Charging") : L("On battery")]
        if let health = power.healthFraction {
            values.append("\(Int((health * 100).rounded()))% \(L("health"))")
        }
        return values.joined(separator: " · ")
    }

    private var temperatureDetail: String? {
        guard let temperature = self.metrics.cpuTemperature else { return nil }
        return String(format: "%@ %.1f °C", L("CPU temperature"), temperature)
    }

    private func percent(_ fraction: Double?) -> String {
        guard let fraction else { return "—" }
        return "\(Int((fraction * 100).rounded()))%"
    }

    private static func bytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .memory)
    }

    private static func rate(_ bytes: Double) -> String {
        "\(ByteCountFormatter.string(fromByteCount: Int64(max(0, bytes)), countStyle: .file))/s"
    }
}

private struct ScapoliteMetricCard: View {
    let title: String
    let value: String
    let detail: String?
    let progress: Double?
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(self.title, systemImage: self.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(self.value)
                .font(.title2.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let progress {
                ProgressView(value: min(1, max(0, progress)))
            }
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 115, alignment: .topLeading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ScapoliteStatusView: View {
    let monitor: ScapoliteServiceMonitor

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("Live provider health"))
                    .font(.headline)
                Spacer()
                Button {
                    Task { await self.monitor.refresh() }
                } label: {
                    Label(L("Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(self.monitor.isRefreshing)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            Divider()
            List(self.monitor.health) { health in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Self.statusColor(health.indicator))
                            .frame(width: 10, height: 10)
                        Text(health.service.name)
                            .font(.headline)
                        Spacer()
                        Text(Self.statusLabel(health.indicator))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Link(destination: health.service.statusURL) {
                            Image(systemName: "arrow.up.right.square")
                        }
                        .buttonStyle(.borderless)
                    }
                    if let description = health.detail, !description.isEmpty {
                        Text(description)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if let updatedAt = health.updatedAt {
                        Text("\(L("Updated")) \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 6)
            }
            .listStyle(.inset)
        }
        .task {
            if self.monitor.healthByServiceID.isEmpty {
                await self.monitor.refresh()
            }
        }
    }

    private static func statusColor(_ indicator: ProviderStatusIndicator) -> Color {
        switch indicator {
        case .none: .green
        case .minor: .yellow
        case .major: .orange
        case .critical: .red
        case .maintenance: .blue
        case .unknown: .secondary
        }
    }

    private static func statusLabel(_ indicator: ProviderStatusIndicator) -> String {
        switch indicator {
        case .none: L("Operational")
        case .minor: L("Minor issue")
        case .major: L("Partial outage")
        case .critical: L("Major outage")
        case .maintenance: L("Maintenance")
        case .unknown: L("Unknown")
        }
    }
}
