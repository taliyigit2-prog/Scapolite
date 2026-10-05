import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

@MainActor
struct ScapoliteSystemSwitcherTests {
    @Test
    func `merged switcher exposes the Mac system tab`() {
        var selected: ProviderSwitcherSelection?
        let switcher = ProviderSwitcherView(
            providers: [.codex, .claude],
            selected: .provider(.codex),
            includesOverview: true,
            includesSystem: true,
            width: 420,
            showsIcons: true,
            iconProvider: { _ in NSImage() },
            weeklyRemainingProvider: { _ in nil },
            onSelect: { selected = $0 })

        // Overview, Codex, Claude, System.
        #expect(switcher._test_simulateRuntimeClick(buttonTag: 3))
        #expect(selected == .system)
    }
}
