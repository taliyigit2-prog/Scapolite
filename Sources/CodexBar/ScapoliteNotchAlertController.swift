import AppKit
import CodexBarCore
import SwiftUI

@MainActor
final class ScapoliteNotchAlertController {
    private var panel: NSPanel?
    private var dismissalTask: Task<Void, Never>?

    func show(_ transition: ScapoliteServiceTransition) {
        let recovered = transition.current.indicator == .none
        guard recovered || transition.current.indicator.hasIssue else { return }

        self.dismissalTask?.cancel()
        let alert = ScapoliteNotchAlert(
            serviceName: transition.current.service.name,
            detail: transition.current.detail,
            indicator: transition.current.indicator,
            recovered: recovered)
        let hostingView = NSHostingView(rootView: ScapoliteNotchAlertView(alert: alert))
        hostingView.frame = NSRect(x: 0, y: 0, width: 460, height: 92)
        hostingView.setAccessibilityIdentifier("scapolite-service-alert-content")

        let panel = self.panel ?? self.makePanel()
        panel.contentView = hostingView
        self.position(panel)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }
        self.panel = panel

        self.dismissalTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(recovered ? 6 : 12))
            } catch {
                return
            }
            self?.dismiss()
        }
    }

    func dismiss() {
        self.dismissalTask?.cancel()
        self.dismissalTask = nil
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 0
        } completionHandler: {
            Task { @MainActor in panel.orderOut(nil) }
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 92),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.level = .statusBar
        panel.identifier = NSUserInterfaceItemIdentifier("com.taliyigit2.scapolite.notch-alert")
        panel.title = "Scapolite Service Alert"
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        return panel
    }

    private func position(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main
        guard let screen else { return }
        let topInset = max(0, screen.safeAreaInsets.top)
        let x = screen.frame.midX - panel.frame.width / 2
        let y = screen.frame.maxY - topInset - panel.frame.height - 6
        panel.setFrameOrigin(NSPoint(x: x.rounded(), y: y.rounded()))
    }
}

private struct ScapoliteNotchAlert: Sendable {
    let serviceName: String
    let detail: String?
    let indicator: ProviderStatusIndicator
    let recovered: Bool
}

private struct ScapoliteNotchAlertView: View {
    let alert: ScapoliteNotchAlert

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(self.alert.recovered ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                Image(systemName: self.alert.recovered ? "checkmark" : "exclamationmark.triangle.fill")
                    .foregroundStyle(self.alert.recovered ? .green : .red)
                    .font(.title3.weight(.semibold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(self.alert.recovered ? L("Service recovered") : L("Service disruption detected"))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(self.alert.serviceName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.95))
                if let detail = self.alert.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(width: 460, height: 82)
        .background(.black.opacity(0.94), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .padding(.vertical, 5)
    }
}
