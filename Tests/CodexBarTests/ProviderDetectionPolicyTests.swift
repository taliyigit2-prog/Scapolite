import Testing
@testable import CodexBar
@testable import CodexBarCore

struct ProviderDetectionPolicyTests {
    @Test
    func `Antigravity CLI is detected without a running IDE or app OAuth credentials`() {
        let enabled = ProviderDetectionPolicy.enabledProviders(signals: .init(
            codexCLIInstalled: true,
            claudeCLIInstalled: true,
            claudeDesktopInstalled: false,
            geminiCLIInstalled: false,
            geminiConfigured: false,
            antigravityAvailable: false,
            antigravityCLIInstalled: true))

        #expect(enabled == [.codex, .claude, .antigravity])
    }

    @Test
    func `first launch in another app domain preserves configured providers`() {
        let enabled = ProviderDetectionPolicy.enabledProviders(signals: .init(
            codexCLIInstalled: true,
            claudeCLIInstalled: true,
            claudeDesktopInstalled: false,
            geminiCLIInstalled: false,
            geminiConfigured: false,
            antigravityAvailable: false), preserving: [.antigravity, .cursor])

        #expect(enabled == [.codex, .claude, .antigravity, .cursor])
    }

    @Test
    func `fresh install detects Codex and Claude Desktop without unconfigured Gemini`() {
        let enabled = ProviderDetectionPolicy.enabledProviders(signals: .init(
            codexCLIInstalled: true,
            claudeCLIInstalled: false,
            claudeDesktopInstalled: true,
            geminiCLIInstalled: true,
            geminiConfigured: false,
            antigravityAvailable: false))

        #expect(enabled == [.codex, .claude])
    }

    @Test
    func `configured Gemini CLI is detected`() {
        let enabled = ProviderDetectionPolicy.enabledProviders(signals: .init(
            codexCLIInstalled: false,
            claudeCLIInstalled: false,
            claudeDesktopInstalled: false,
            geminiCLIInstalled: true,
            geminiConfigured: true,
            antigravityAvailable: false))

        #expect(enabled == [.gemini])
    }

    @Test
    func `Codex remains the fallback when no provider source is available`() {
        let enabled = ProviderDetectionPolicy.enabledProviders(signals: .init(
            codexCLIInstalled: false,
            claudeCLIInstalled: false,
            claudeDesktopInstalled: false,
            geminiCLIInstalled: false,
            geminiConfigured: false,
            antigravityAvailable: false))

        #expect(enabled == [.codex])
    }
}
