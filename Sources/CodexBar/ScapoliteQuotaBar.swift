import AppKit
import CodexBarCore

struct ScapoliteQuotaBar {
    static let providerLimit = 3
    static let blockWidth: CGFloat = 58
    static let gap: CGFloat = 8

    struct Reading: Equatable {
        let provider: UsageProvider
        let session: String
        let weekly: String
        let stale: Bool
        let quotaNote: String?

        init(
            provider: UsageProvider,
            session: RateWindow?,
            weekly: RateWindow?,
            stale: Bool = false,
            quotaNote: String? = nil)
        {
            self.provider = provider
            self.session = ScapoliteQuotaBar.percent(session, minutes: 300)
            self.weekly = ScapoliteQuotaBar.percent(weekly, minutes: 10080)
            self.stale = stale
            self.quotaNote = quotaNote
        }

        init(provider: UsageProvider, snapshot: UsageSnapshot?, windows: ProviderSemanticWindows, stale: Bool = false) {
            // Model-specific rights cannot stand in for Claude's overall plan quota.
            let weekly = provider == .claude ? snapshot?.secondary : windows.weekly
            let titles = provider == .antigravity ? [windows.session, weekly].compactMap { window in
                snapshot?.extraRateWindows?.first(where: { $0.usageKnown && $0.window == window })?.title
            } : []
            self.init(
                provider: provider,
                session: windows.session,
                weekly: weekly,
                stale: stale,
                quotaNote: titles.isEmpty ? nil : titles.joined(separator: ", "))
        }

        var description: String {
            let name = ProviderDescriptorRegistry.descriptor(for: self.provider).metadata.displayName
            return "\(name): \(L("Session")) \(self.session), \(L("Weekly")) \(self.weekly)"
                + (self.stale ? " (\(L("stale data")))" : "")
                + (self.quotaNote.map { " — \($0)" } ?? "")
        }
    }

    static func providers(_ rawValues: [String]) -> [UsageProvider] {
        var seen: Set<UsageProvider> = []
        return Array(rawValues.compactMap(UsageProvider.init(rawValue:))
            .filter { seen.insert($0).inserted }.prefix(Self.providerLimit))
    }

    private static func percent(_ window: RateWindow?, minutes: Int) -> String {
        guard let window, !window.isSyntheticPlaceholder,
              window.windowMinutes == minutes, window.usedPercent.isFinite
        else { return "—" }
        return "\(Int(min(100, max(0, window.remainingPercent)).rounded()))%"
    }

    @MainActor
    static func image(readings: [Reading]) -> NSImage {
        let width = CGFloat(readings.count) * Self.blockWidth + CGFloat(max(0, readings.count - 1)) * Self.gap
        let image = NSImage(size: NSSize(width: width, height: 22))
        image.lockFocus()
        for (index, reading) in readings.enumerated() {
            let x = CGFloat(index) * (Self.blockWidth + Self.gap)
            let alpha = reading.stale ? 0.45 : 1.0
            ProviderBrandIcon.image(for: reading.provider)?.draw(
                in: NSRect(x: x, y: 3, width: 16, height: 16),
                from: .zero,
                operation: .sourceOver,
                fraction: alpha)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
                .foregroundColor: NSColor.black.withAlphaComponent(alpha),
            ]
            for (text, y) in [(reading.session, CGFloat(11)), (reading.weekly, CGFloat(0))] {
                (text as NSString).draw(at: NSPoint(x: x + 20, y: y), withAttributes: attributes)
            }
        }
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}

extension StatusItemController {
    func prepareLegacyQuotaBarLength(provider: UsageProvider) {
        if !self.settings.menuBarShowsBrandIconWithPercent {
            self.statusItems[provider.instanceID]?.length = NSStatusItem.variableLength
        }
    }

    func applySingleScapoliteQuotaBar(provider: UsageProvider) -> Bool? {
        guard self.settings.mergeIcons, self.settings.scapoliteCompactQuotaBarEnabled,
              let item = self.statusItems[provider.instanceID] else { return nil }
        return self.applyScapoliteQuotaBar(providers: [provider], to: item)
    }

    var scapoliteQuotaBarProviders: [UsageProvider] {
        _ = self.settings.scapoliteMenuBarProviders
        guard self.settings.mergeIcons, self.settings.scapoliteCompactQuotaBarEnabled else { return [] }
        let active = self.store.enabledFirstPartyProvidersForDisplay()
        let selected = self.settings.scapoliteMenuBarProviders.filter(active.contains)
        return selected.isEmpty ? Array(active.prefix(ScapoliteQuotaBar.providerLimit)) : selected
    }

    func applyScapoliteQuotaBar(providers: [UsageProvider], to item: NSStatusItem) -> Bool? {
        guard !providers.isEmpty, let button = item.button else { return nil }
        let readings = providers.map { provider in
            let snapshot = self.store.menuBarSnapshot(for: provider.instanceID)
            let windows = self.menuBarLayoutWindows(provider: provider, snapshot: snapshot, now: Date())
            return ScapoliteQuotaBar.Reading(
                provider: provider,
                snapshot: snapshot,
                windows: ProviderSemanticWindows(session: windows.session, weekly: windows.weekly),
                stale: self.store.isStale(provider: provider))
        }
        let description = readings.map(\.description).joined(separator: "\n")
        guard button.image?.accessibilityDescription != description else { return true }
        let image = ScapoliteQuotaBar.image(readings: readings)
        image.accessibilityDescription = description
        button.attributedTitle = NSAttributedString()
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = description
        button.setAccessibilityLabel(description)
        item.length = image.size.width + 6
        return false
    }
}
