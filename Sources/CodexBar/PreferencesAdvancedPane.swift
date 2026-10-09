import CodexBarCore
import SwiftUI

@MainActor
struct AdvancedPane: View {
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore
    @State private var isInstallingCLI = false
    @State private var cliStatus: String?
    @State private var showsHooks = false
    @State private var showsPlugins = false

    var body: some View {
        Form {
            PreferencesTransferSection(settings: self.settings)

            Section {
                SettingsMenuPicker(
                    selection: self.$settings.preferredCurrencyCode,
                    options: PreferredCurrencyOption.codes,
                    label: { Text(L("currency_title")) },
                    optionLabel: { Text(verbatim: PreferredCurrencyOption.label(for: $0)) })
                    .onChange(of: self.settings.preferredCurrencyCode) { _, code in
                        guard CurrencyExchange.requiresLiveRates(preferredCurrencyCode: code) else { return }
                        Task { await CurrencyExchange.shared.fetchLatestRatesIfNeeded(preferredCurrencyCode: code) }
                    }
                Toggle(L("Track costs"), isOn: self.$settings.costUsageEnabled)
            } header: {
                Text(L("Usage & Spend"))
            }

            Section {
                Button(L("tab_hooks")) { self.showsHooks = true }
                Button(L("Plugins")) { self.showsPlugins = true }
                DisclosureGroup(L("Tools")) {
                    Button(L("install_cli")) { Task { await self.installCLI() } }
                        .disabled(self.isInstallingCLI)
                    if let status = self.cliStatus {
                        Text(status).font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle(L("Stay Awake"), isOn: self.$settings.stayAwakeEnabled)
                    Toggle(L("disable_keychain_access_title"), isOn: self.$settings.debugDisableKeychainAccess)
                    AgentSessionHostsEditor(settings: self.settings)
                }
            } header: {
                Text(L("Advanced"))
            }
        }
        .formStyle(.grouped)
        .toggleStyle(.switch)
        .scrollContentBackground(.hidden)
        .sheet(isPresented: self.$showsHooks) {
            VStack {
                HooksPane(settings: self.settings)
                Button(L("Close")) { self.showsHooks = false }.padding()
            }
            .frame(width: 700, height: 500)
        }
        .sheet(isPresented: self.$showsPlugins) {
            VStack {
                PluginsPane(settings: self.settings, store: self.store)
                Button(L("Close")) { self.showsPlugins = false }.padding()
            }
            .frame(width: 700, height: 500)
        }
    }
}

extension AdvancedPane {
    private func installCLI() async {
        if self.isInstallingCLI {
            return
        }
        self.isInstallingCLI = true
        defer { self.isInstallingCLI = false }

        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/CodexBarCLI")
        let fm = FileManager.default
        guard fm.fileExists(atPath: helperURL.path) else {
            self.cliStatus = L("cli_not_found")
            return
        }

        let destinations = [
            "/usr/local/bin/codexbar",
            "/opt/homebrew/bin/codexbar",
        ]

        var installed: [String] = []
        var conflicts: [String] = []
        var failures: [String] = []
        for dest in destinations {
            let dir = (dest as NSString).deletingLastPathComponent
            guard fm.fileExists(atPath: dir) else { continue }

            if fm.fileExists(atPath: dest) {
                if Self.isLink(atPath: dest, pointingTo: helperURL.path) {
                    installed.append("Installed: \(dir)")
                } else {
                    conflicts.append("Exists: \(dir)")
                }
                continue
            }

            guard fm.isWritableFile(atPath: dir) else {
                failures.append("No write access: \(dir)")
                continue
            }

            do {
                try fm.createSymbolicLink(atPath: dest, withDestinationPath: helperURL.path)
                installed.append("Installed: \(dir)")
            } catch {
                failures.append("Failed: \(dir)")
            }
        }

        self.cliStatus = Self.cliInstallStatus(
            installed: installed,
            conflicts: conflicts,
            failures: failures)
    }

    private static func isLink(atPath path: String, pointingTo destination: String) -> Bool {
        guard let link = try? FileManager.default.destinationOfSymbolicLink(atPath: path) else { return false }
        let dir = (path as NSString).deletingLastPathComponent
        let resolved = URL(fileURLWithPath: link, relativeTo: URL(fileURLWithPath: dir))
            .standardizedFileURL
            .path
        return resolved == destination
    }

    static func cliInstallStatus(installed: [String], conflicts: [String], failures: [String]) -> String {
        if installed.isEmpty == false {
            return (installed + conflicts).joined(separator: " · ")
        }
        if conflicts.isEmpty == false {
            return (conflicts + failures).joined(separator: " · ")
        }
        if failures.isEmpty == false {
            return failures.joined(separator: " · ")
        }
        return L("no_writable_bin_dirs")
    }
}
