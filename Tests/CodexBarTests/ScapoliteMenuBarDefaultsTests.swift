import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct ScapoliteMenuBarDefaultsTests {
    @Test("Scapolite defaults show Codex and Claude remaining percentages")
    func quotaFirstDefaults() throws {
        let suite = "ScapoliteMenuBarDefaultsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        SettingsStore.applyScapoliteMenuBarDefaultsMigration(userDefaults: defaults)

        #expect(defaults.bool(forKey: "menuBarShowsBrandIconWithPercent"))
        #expect(defaults.bool(forKey: "mergeIcons"))
        #expect(defaults.bool(forKey: "mergeIconsStacked"))
        #expect(defaults.string(forKey: "mergeIconStackedTopProvider") == UsageProvider.codex.rawValue)
        #expect(defaults.string(forKey: "mergeIconStackedBottomProvider") == UsageProvider.claude.rawValue)
        #expect(defaults.integer(forKey: "scapoliteMenuBarDefaultsMigrationVersion") == 1)
    }

    @Test("Scapolite defaults migration preserves later user choices")
    func migrationIsIdempotent() throws {
        let suite = "ScapoliteMenuBarDefaultsTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        SettingsStore.applyScapoliteMenuBarDefaultsMigration(userDefaults: defaults)
        defaults.set(false, forKey: "menuBarShowsBrandIconWithPercent")
        defaults.set(false, forKey: "mergeIconsStacked")

        SettingsStore.applyScapoliteMenuBarDefaultsMigration(userDefaults: defaults)

        #expect(!defaults.bool(forKey: "menuBarShowsBrandIconWithPercent"))
        #expect(!defaults.bool(forKey: "mergeIconsStacked"))
    }
}
