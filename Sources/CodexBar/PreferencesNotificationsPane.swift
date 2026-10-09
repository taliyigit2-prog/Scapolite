import SwiftUI

@MainActor
struct NotificationsPane: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section {
                Toggle(L("Service disruption notifications"), isOn: self.$settings.scapoliteServiceNotificationsEnabled)
                    .accessibilityIdentifier("scapolite-service-notifications-toggle")
                Button(L("Show test notification")) {
                    NotificationCenter.default.post(name: .scapoliteTestServiceAlert, object: nil)
                }
                .disabled(!self.settings.scapoliteServiceNotificationsEnabled)
                .accessibilityIdentifier("scapolite-test-service-notification")
            } header: {
                Text(L("Service Status"))
            }

            Section {
                Toggle(isOn: self.$settings.credentialExpiryNotificationsEnabled) {
                    SettingsRowLabel(
                        L("Credential expiry"),
                        subtitle: L("Notify once when a provider account needs you to sign in again."))
                }
                Toggle(L("quota_depleted_title"), isOn: self.$settings.sessionQuotaNotificationsEnabled)
                Toggle(L("threshold_warnings_title"), isOn: self.$settings.quotaWarningNotificationsEnabled)
                DisclosureGroup(L("Advanced")) {
                    Toggle(
                        L("predictive_pace_warnings_title"),
                        isOn: self.$settings.predictivePaceWarningNotificationsEnabled)
                    Toggle(L("limit_reset_notifications_title"), isOn: self.$settings.limitResetNotificationsEnabled)
                    let visibility = QuotaWarningSettingsVisibility(
                        thresholdWarningsEnabled: self.settings.quotaWarningNotificationsEnabled,
                        predictiveWarningsEnabled: self.settings.predictivePaceWarningNotificationsEnabled)
                    if visibility.showsDeliveryControls {
                        GlobalQuotaWarningSettingsView(
                            settings: self.settings,
                            showsThresholdControls: visibility.showsThresholdControls)
                    }
                }
            } header: {
                Text(L("section_alerts"))
            }
        }
        .formStyle(.grouped)
        .toggleStyle(.switch)
        .scrollContentBackground(.hidden)
        .background(FocusResigningBackground())
    }
}
