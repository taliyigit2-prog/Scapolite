import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct ScapoliteMenuBarDefaultsTests {
    @Test("Scapolite defaults show Codex and Claude remaining percentages")
    func quotaFirstDefaults() {
        let defaults = InMemoryUserDefaults()

        SettingsStore.applyScapoliteMenuBarDefaultsMigration(userDefaults: defaults)

        #expect(defaults.bool(forKey: "menuBarShowsBrandIconWithPercent"))
        #expect(defaults.bool(forKey: "mergeIcons"))
        #expect(defaults.bool(forKey: "mergeIconsStacked"))
        #expect(defaults.string(forKey: "mergeIconStackedTopProvider") == UsageProvider.codex.rawValue)
        #expect(defaults.string(forKey: "mergeIconStackedBottomProvider") == UsageProvider.claude.rawValue)
        #expect(defaults.integer(forKey: "scapoliteMenuBarDefaultsMigrationVersion") == 2)
        #expect(defaults.stringArray(forKey: "scapoliteMenuBarProviders") == ["codex", "claude", "antigravity"])
        #expect(defaults.string(forKey: "refreshFrequency") == RefreshFrequency.twoMinutes.rawValue)
        #expect(defaults.string(forKey: "backgroundWorkLowPowerModePreference")
            == LowPowerModePreference.automatic.rawValue)
    }

    @Test("Scapolite defaults migration preserves later user choices")
    func migrationIsIdempotent() {
        let defaults = InMemoryUserDefaults()

        SettingsStore.applyScapoliteMenuBarDefaultsMigration(userDefaults: defaults)
        defaults.set(false, forKey: "menuBarShowsBrandIconWithPercent")
        defaults.set(false, forKey: "mergeIconsStacked")

        SettingsStore.applyScapoliteMenuBarDefaultsMigration(userDefaults: defaults)

        #expect(!defaults.bool(forKey: "menuBarShowsBrandIconWithPercent"))
        #expect(!defaults.bool(forKey: "mergeIconsStacked"))
    }
}
