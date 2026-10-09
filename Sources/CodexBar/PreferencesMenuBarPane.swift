import CodexBarCore
import SwiftUI

@MainActor
struct MenuBarPane: View {
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ForEach(self.selectedProviders, id: \.self) { provider in
                        HStack(spacing: 5) {
                            if let icon = ProviderBrandIcon.image(for: provider) {
                                Image(nsImage: icon).resizable().scaledToFit().frame(width: 18, height: 18)
                            }
                            VStack(spacing: 0) {
                                Text("87%")
                                Text("42%")
                            }
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                        }
                        .accessibilityLabel(self.store.metadata(for: provider).displayName)
                    }
                }
                Text(L("Top: remaining session quota. Bottom: remaining weekly quota."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(L("Preview"))
            }

            Section {
                ForEach(self.activeProviders, id: \.self) { provider in
                    Toggle(self.store.metadata(for: provider).displayName, isOn: Binding(
                        get: { self.selectedProviders.contains(provider) },
                        set: { selected in
                            var providers = self.selectedProviders
                            if selected { providers.append(provider) } else { providers.removeAll { $0 == provider } }
                            self.settings.scapoliteMenuBarProviders = providers
                        }))
                        .toggleStyle(.checkbox)
                        .disabled(self.selectedProviders.contains(provider)
                            ? self.selectedProviders.count == 1
                            : self.selectedProviders.count >= ScapoliteQuotaBar.providerLimit)
                }
                if self.activeProviders.isEmpty {
                    Text(L("Enable a provider to show its quota in the menu bar."))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(L("Choose up to three providers"))
            }

            if self.selectedProviders.count > 1 {
                Section {
                    ForEach(Array(self.selectedProviders.enumerated()), id: \.element) { index, provider in
                        HStack {
                            Text(self.store.metadata(for: provider).displayName)
                            Spacer()
                            Button { self.move(index, by: -1) } label: {
                                Image(systemName: "chevron.up")
                            }
                            .accessibilityLabel(L("Move up"))
                            .disabled(index == 0)
                            Button { self.move(index, by: 1) } label: {
                                Image(systemName: "chevron.down")
                            }
                            .accessibilityLabel(L("Move down"))
                            .disabled(index == self.selectedProviders.count - 1)
                        }
                    }
                } header: {
                    Text(L("Order"))
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var activeProviders: [UsageProvider] {
        self.store.enabledFirstPartyProvidersForDisplay()
    }

    private var selectedProviders: [UsageProvider] {
        let selected = self.settings.scapoliteMenuBarProviders.filter(self.activeProviders.contains)
        return selected.isEmpty ? Array(self.activeProviders.prefix(ScapoliteQuotaBar.providerLimit)) : selected
    }

    private func move(_ index: Int, by offset: Int) {
        var providers = self.selectedProviders
        let destination = index + offset
        guard providers.indices.contains(index), providers.indices.contains(destination) else { return }
        providers.swapAt(index, destination)
        self.settings.scapoliteMenuBarProviders = providers
    }
}
