import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

struct ScapoliteQuotaBarTests {
    @Test
    func `overall Claude weekly exhaustion stays zero despite a fresh model allowance`() {
        let session = self.window(used: 0, minutes: 300)
        let weekly = self.window(used: 100, minutes: 10080)
        let scoped = self.window(used: 0, minutes: 10080)
        let snapshot = UsageSnapshot(primary: session, secondary: weekly, tertiary: scoped, updatedAt: Date())
        let reading = ScapoliteQuotaBar.Reading(
            provider: .claude,
            snapshot: snapshot,
            windows: ProviderSemanticWindows(session: session, weekly: scoped))
        #expect(reading.session == "100%")
        #expect(reading.weekly == "0%")
        let missing = ScapoliteQuotaBar.Reading(
            provider: .claude,
            snapshot: snapshot.with(primary: session, secondary: nil),
            windows: ProviderSemanticWindows(session: session, weekly: scoped))
        #expect(missing.weekly == "—")
    }

    @Test
    func `unknown synthetic invalid and wrong-cadence quotas never look available`() {
        for session in [
            nil,
            self.window(used: .nan, minutes: 300),
            self.window(used: 0, minutes: 1440),
            RateWindow(
                usedPercent: 0,
                windowMinutes: 300,
                resetsAt: nil,
                resetDescription: nil,
                isSyntheticPlaceholder: true),
        ] {
            let reading = ScapoliteQuotaBar.Reading(provider: .codex, session: session, weekly: nil)
            #expect(reading.session == "—")
            #expect(reading.weekly == "—")
        }
        #expect(ScapoliteQuotaBar.Reading(
            provider: .codex, session: self.window(used: 125, minutes: 300), weekly: nil).session == "0%")
    }

    @Test
    func `Antigravity separates session and weekly families and includes exhausted quotas`() {
        let rows = [
            NamedRateWindow(
                id: "antigravity-quota-summary-unknown-session",
                title: "Unmeasured session",
                window: self.window(used: 100, minutes: 300),
                usageKnown: false),
            NamedRateWindow(
                id: "antigravity-quota-summary-gemini-session",
                title: "Gemini session",
                window: self.window(used: 15, minutes: 300)),
            NamedRateWindow(
                id: "antigravity-quota-summary-gemini-weekly",
                title: "Gemini weekly",
                window: self.window(used: 30, minutes: 10080)),
            NamedRateWindow(
                id: "antigravity-quota-summary-3p-weekly",
                title: "Third party weekly",
                window: self.window(used: 100, minutes: 10080)),
        ]
        let snapshot = UsageSnapshot(primary: nil, secondary: nil, extraRateWindows: rows, updatedAt: Date())
        let windows = AntigravityProviderDescriptor.descriptor.presentation.semanticWindows(snapshot: snapshot)
        let reading = ScapoliteQuotaBar.Reading(provider: .antigravity, snapshot: snapshot, windows: windows)
        #expect(reading.session == "85%")
        #expect(reading.weekly == "0%")
        #expect(reading.quotaNote?.contains("Third party weekly") == true)
    }

    @Test
    func `selection preserves order removes duplicates and permits three providers`() {
        #expect(ScapoliteQuotaBar.providers(["claude", "codex", "claude", "unknown", "antigravity", "cursor"])
            == [.claude, .codex, .antigravity])
    }

    @Test @MainActor
    func `three provider template has stable width even at zero and one hundred`() {
        let readings = [UsageProvider.claude, .codex, .antigravity].map {
            ScapoliteQuotaBar.Reading(provider: $0, session: self.window(used: 0, minutes: 300), weekly: nil)
        }
        let image = ScapoliteQuotaBar.image(readings: readings)
        #expect(image.isTemplate)
        #expect(image.size == NSSize(width: 190, height: 22))
    }

    @Test @MainActor
    func `service alert preference defaults on and survives portable transfer`() throws {
        let settings = testSettingsStore(
            suiteName: "ScapoliteQuotaBarTests",
            userDefaults: InMemoryUserDefaults(),
            keychainAccessPolicy: .init(setDisabled: { _ in }, isExplicitlyDisabled: { true }))
        #expect(settings.scapoliteServiceNotificationsEnabled)
        settings.scapoliteServiceNotificationsEnabled = false
        settings.scapoliteMenuBarProviders = [.claude, .codex, .antigravity]
        let document = try settings.exportPreferences()
        settings.scapoliteServiceNotificationsEnabled = true
        settings.scapoliteMenuBarProviders = [.codex]
        try settings.importPreferences(document)
        #expect(!settings.scapoliteServiceNotificationsEnabled)
        #expect(settings.scapoliteMenuBarProviders == [.claude, .codex, .antigravity])
    }

    private func window(used: Double, minutes: Int) -> RateWindow {
        RateWindow(usedPercent: used, windowMinutes: minutes, resetsAt: nil, resetDescription: nil)
    }
}
