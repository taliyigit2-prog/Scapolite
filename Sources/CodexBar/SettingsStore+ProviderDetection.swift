import AppKit
import CodexBarCore
import Foundation

enum ProviderDetectionPolicy {
    struct Signals {
        let codexCLIInstalled: Bool
        let claudeCLIInstalled: Bool
        let claudeDesktopInstalled: Bool
        let geminiCLIInstalled: Bool
        let geminiConfigured: Bool
        let antigravityAvailable: Bool
        var antigravityCLIInstalled = false
    }

    static func enabledProviders(
        signals: Signals,
        preserving alreadyEnabled: Set<UsageProvider> = []) -> Set<UsageProvider>
    {
        // Provider-specific by design: first-run detection probes these four concrete CLI/app credential sources.
        var enabled = alreadyEnabled
        if signals.codexCLIInstalled {
            enabled.insert(.codex)
        }
        if signals.claudeCLIInstalled || signals.claudeDesktopInstalled {
            enabled.insert(.claude)
        }
        if signals.geminiCLIInstalled, signals.geminiConfigured {
            enabled.insert(.gemini)
        }
        if signals.antigravityAvailable || signals.antigravityCLIInstalled {
            enabled.insert(.antigravity)
        }

        // Keep the historical Codex default when no usable provider source is found.
        if enabled.isEmpty {
            enabled.insert(.codex)
        }
        return enabled
    }
}

extension SettingsStore {
    func runInitialProviderDetectionIfNeeded(force: Bool = false) {
        guard force || !self.providerDetectionCompleted else { return }
        LoginShellPathCache.shared.captureOnce { [weak self] _ in
            Task { @MainActor in
                await self?.applyProviderDetection()
            }
        }
    }

    func applyProviderDetection() async {
        guard !self.providerDetectionCompleted else { return }
        // Provider-specific by design: detection reads each provider's installed app, CLI, or credential artifact.
        let codexCLIInstalled = BinaryLocator.resolveCodexBinary() != nil
        let claudeCLIInstalled = BinaryLocator.resolveClaudeBinary() != nil
        let claudeDesktopInstalled = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.anthropic.claudefordesktop") != nil
        let geminiCLIInstalled = BinaryLocator.resolveGeminiBinary() != nil
        let geminiConfigured = FileManager.default.fileExists(
            atPath: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".gemini/oauth_creds.json").path)
        let antigravityRunning = await AntigravityStatusProbe.isRunning()
        let antigravityLoggedIn = FileManager.default.fileExists(
            atPath: AntigravityOAuthCredentialsStore().fileURL.path)
        let antigravityCLIInstalled = BinaryLocator.resolveAntigravityBinary() != nil
        let logger = CodexBarLog.logger(LogCategories.providerDetection)

        // Debug and release builds share config.json but have separate first-launch defaults.
        // Detection must not disable a provider already enabled in the shared configuration.
        let alreadyEnabled = Set(self.configSnapshot.providers.compactMap { entry in
            entry.enabled == true ? entry.id.firstPartyProvider : nil
        })
        let enabledProviders = ProviderDetectionPolicy.enabledProviders(signals: .init(
            codexCLIInstalled: codexCLIInstalled,
            claudeCLIInstalled: claudeCLIInstalled,
            claudeDesktopInstalled: claudeDesktopInstalled,
            geminiCLIInstalled: geminiCLIInstalled,
            geminiConfigured: geminiConfigured,
            antigravityAvailable: antigravityRunning || antigravityLoggedIn,
            antigravityCLIInstalled: antigravityCLIInstalled), preserving: alreadyEnabled)

        logger.info(
            "Provider detection results",
            metadata: [
                "codexCLIInstalled": codexCLIInstalled ? "1" : "0",
                "claudeCLIInstalled": claudeCLIInstalled ? "1" : "0",
                "claudeDesktopInstalled": claudeDesktopInstalled ? "1" : "0",
                "geminiCLIInstalled": geminiCLIInstalled ? "1" : "0",
                "geminiConfigured": geminiConfigured ? "1" : "0",
                "antigravityRunning": antigravityRunning ? "1" : "0",
                "antigravityLoggedIn": antigravityLoggedIn ? "1" : "0",
                "antigravityCLIInstalled": antigravityCLIInstalled ? "1" : "0",
            ])
        logger.info(
            "Provider detection enablement",
            metadata: [
                "codex": enabledProviders.contains(.codex) ? "1" : "0",
                "claude": enabledProviders.contains(.claude) ? "1" : "0",
                "gemini": enabledProviders.contains(.gemini) ? "1" : "0",
                "antigravity": enabledProviders.contains(.antigravity) ? "1" : "0",
            ])

        self.updateProviderConfig(provider: .codex) { entry in
            entry.enabled = enabledProviders.contains(.codex)
        }
        self.updateProviderConfig(provider: .claude) { entry in
            entry.enabled = enabledProviders.contains(.claude)
        }
        self.updateProviderConfig(provider: .gemini) { entry in
            entry.enabled = enabledProviders.contains(.gemini)
        }
        self.updateProviderConfig(provider: .antigravity) { entry in
            entry.enabled = enabledProviders.contains(.antigravity)
        }
        self.providerDetectionCompleted = true
        logger.info("Provider detection completed")
    }
}
