import AppKit
import MoleWidgetCore
import SwiftUI

extension StatusItemController {
    func addScapoliteSystemMenuContent(to menu: NSMenu, width: CGFloat) {
        let view = ScapoliteSystemMenuView(metrics: self.scapoliteMetrics, width: width)
        menu.addItem(self.makeMenuCardItem(
            view,
            id: "scapoliteSystemMenu",
            width: width,
            heightCacheScope: "scapoliteSystemMenu",
            heightCacheFingerprint: "v1"))
        menu.addItem(.separator())
    }
}

struct ScapoliteSystemMenuView: View {
    let metrics: MetricsStore
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L("System"), systemImage: "cpu")
                    .font(.headline)
                Spacer()
                Text("\(self.metrics.healthScore)/100")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(self.healthColor)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                self.metric(L("CPU"), self.percent(self.metrics.cpu?.totalUsage), "cpu")
                self.metric(L("Memory"), self.percent(self.metrics.memory?.usedFraction), "memorychip")
                self.metric(L("Disk"), self.percent(self.metrics.diskUsage?.usedFraction), "internaldrive")
                self.metric(L("Battery"), self.batteryText, "battery.100percent")
                self.metric("\(L("Network")) ↓", self.rate(self.metrics.netRates?.download), "arrow.down")
                self.metric("\(L("Network")) ↑", self.rate(self.metrics.netRates?.upload), "arrow.up")
            }

            if let temperature = self.metrics.cpuTemperature {
                HStack {
                    Label(L("CPU temperature"), systemImage: "thermometer.medium")
                    Spacer()
                    Text(String(format: "%.1f °C", temperature)).monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if !self.metrics.topProcesses.isEmpty {
                Divider()
                Text(L("Top Processes"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(self.metrics.topProcesses.prefix(3), id: \.pid) { process in
                    HStack {
                        Text(process.name).lineLimit(1)
                        Spacer()
                        Text("\(Int((process.cpuFraction * 100).rounded()))%")
                            .monospacedDigit()
                        Text(Self.bytes(process.memoryBytes))
                            .monospacedDigit()
                            .frame(width: 72, alignment: .trailing)
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: self.width, alignment: .leading)
        .task {
            self.metrics.refreshFast()
            self.metrics.refreshProcesses()
            self.metrics.refreshDiskUsage()
            self.metrics.refreshPower()
        }
    }

    private func metric(_ title: String, _ value: String, _ systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.caption)
    }

    private var healthColor: Color {
        switch self.metrics.healthScore {
        case 80...: .green
        case 55...: .orange
        default: .red
        }
    }

    private var batteryText: String {
        guard let power = self.metrics.power else { return L("No battery") }
        let suffix = power.isCharging ? " · \(L("Charging"))" : ""
        return "\(Int((power.levelFraction * 100).rounded()))%\(suffix)"
    }

    private func percent(_ fraction: Double?) -> String {
        guard let fraction else { return "—" }
        return "\(Int((fraction * 100).rounded()))%"
    }

    private func rate(_ bytes: Double?) -> String {
        guard let bytes else { return "—" }
        return "\(ByteCountFormatter.string(fromByteCount: Int64(max(0, bytes)), countStyle: .file))/s"
    }

    private static func bytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .memory)
    }
}
