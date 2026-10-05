import AppKit
import CodexBarCore

extension StatusItemController {
    private func switcherIcon(for provider: UsageProvider) -> NSImage {
        if let brand = ProviderBrandIcon.image(for: provider) {
            return brand
        }

        // Fallback to the dynamic icon renderer if resources are missing (e.g. dev bundle mismatch).
        let snapshot = self.store.snapshot(for: provider.instanceID)
        let showUsed = self.settings.usageBarsShowUsed
        let style = self.store.style(for: provider)
        let now = Date()
        let resolved = snapshot.map {
            IconRemainingResolver.resolvedPercents(
                snapshot: $0,
                style: style,
                showUsed: showUsed,
                secondaryOverrideWindowID: self.settings.copilotIconSecondaryWindowOverrideID(snapshot: $0),
                now: now)
        }
        let primary = resolved?.primary
        let weekly = resolved?.secondary
        let creditsProjection = self.store.codexConsumerProjectionIfNeeded(
            for: provider,
            surface: .menuBar,
            snapshotOverride: snapshot,
            now: now)
        let credits = creditsProjection?.menuBarFallback == .creditsBalance
            ? self.store.codexMenuBarCreditsRemaining(
                snapshotOverride: snapshot,
                now: now)
            : nil
        let stale = self.store.isStale(provider: provider)
        let indicator = self.store.statusIndicator(for: provider)
        let image = IconRenderer.makeIcon(
            primaryRemaining: primary,
            weeklyRemaining: weekly,
            creditsRemaining: credits,
            stale: stale,
            style: style,
            blink: 0,
            wiggle: 0,
            tilt: 0,
            statusIndicator: indicator,
            hideCritters: self.settings.menuBarHidesCritters,
            quotaLayoutPolicy: .provider(provider))
        image.isTemplate = true
        return image
    }

    func makeProviderSwitcherItem(
        providers: [UsageProvider],
        includesOverview: Bool,
        selected: ProviderSwitcherSelection,
        menu: NSMenu,
        width: CGFloat) -> NSMenuItem
    {
        let view = ProviderSwitcherView(
            providers: providers,
            pluginProviders: self.topLevelUserProviderPlugins(),
            selected: selected,
            includesOverview: includesOverview,
            includesSystem: true,
            width: width,
            showsIcons: self.settings.switcherShowsIcons,
            iconProvider: { [weak self] provider in
                self?.switcherIcon(for: provider) ?? NSImage()
            },
            pluginIconProvider: { [weak self] plugin in
                self?.userPluginSwitcherIcon(for: plugin) ?? NSImage()
            },
            weeklyRemainingProvider: { [weak self] provider in
                self?.switcherWeeklyRemaining(for: provider)
            },
            onSelect: { [weak self, weak menu] selection in
                guard let self, let menu else { return }
                MenuSwitchFlickerProbe.debugLog("onSelect \(selection)")
                var provider: UsageProvider?
                self.preservingMergedSwitcherContentCachesDuringInvalidation {
                    switch selection {
                    case .overview:
                        self.scapoliteSystemMenuSelected = false
                        self.settings.mergedMenuLastSelectedWasOverview = true
                        provider = self.resolvedMenuProvider()
                    case .system:
                        self.scapoliteSystemMenuSelected = true
                        self.settings.mergedMenuLastSelectedWasOverview = false
                        provider = nil
                    case let .provider(selectedProvider):
                        self.scapoliteSystemMenuSelected = false
                        self.settings.mergedMenuLastSelectedWasOverview = false
                        self.selectedMenuProvider = selectedProvider
                        provider = selectedProvider.firstPartyProvider
                    }
                    switch selection {
                    case .overview:
                        // Provider-specific by design: Codex is the persisted fallback for an empty overview.
                        self.lastMenuProvider = (provider ?? .codex).instanceID
                    case .system:
                        self.lastMenuProvider = (self.resolvedMenuProvider() ?? .codex).instanceID
                    case let .provider(provider):
                        self.lastMenuProvider = provider
                    }
                    self.lastMergedSwitcherSelection = selection
                    self.refreshProviderSelectionDependentUI(deferRendering: true)
                }
                self.requestProviderSwitcherMenuRebuild(menu, provider: provider)
            })
        let item = NSMenuItem()
        item.title = ""
        item.view = view
        item.isEnabled = false
        return item
    }
}
