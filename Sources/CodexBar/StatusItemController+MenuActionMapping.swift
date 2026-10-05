import AppKit

extension StatusItemController {
    func selector(for action: MenuDescriptor.MenuAction) -> (Selector, Any?) {
        switch action {
        case .installUpdate, .checkForUpdates, .refresh, .refreshAugmentSession, .dashboard,
             .scapoliteDashboard, .statusPage, .changelog, .addCodexAccount, .openCodexWorkspaces,
             .settings, .about, .quit:
            self.selector(forSimpleAction: action)
        case let .addProviderAccount(provider): (#selector(self.runSwitchAccount(_:)), provider.rawValue)
        case let .requestCodexSystemPromotion(managedAccountID):
            (#selector(self.requestCodexSystemPromotionFromMenu(_:)), managedAccountID.uuidString)
        case let .switchAccount(provider): (#selector(self.runSwitchAccount(_:)), provider.rawValue)
        case let .openTerminal(command): (#selector(self.openTerminalCommand(_:)), command)
        case let .loginToProvider(url): (#selector(self.openLoginToProvider(_:)), url)
        case let .providerSettings(provider): (#selector(self.showProviderSettings(_:)), provider.rawValue)
        case let .copyError(message): (#selector(self.copyError(_:)), message)
        case let .focusAgentSession(session, remoteHost):
            (#selector(self.focusAgentSession(_:)), [session.id, remoteHost ?? ""])
        }
    }

    private func selector(forSimpleAction action: MenuDescriptor.MenuAction) -> (Selector, Any?) {
        switch action {
        case .installUpdate: (#selector(self.installUpdate), nil)
        case .checkForUpdates: (#selector(self.checkForUpdates), nil)
        case .refresh: (#selector(self.refreshMenuItem(_:)), nil)
        case .refreshAugmentSession: (#selector(self.refreshAugmentSession), nil)
        case .dashboard: (#selector(self.openDashboard), nil)
        case .scapoliteDashboard: (#selector(self.openScapoliteDashboard), nil)
        case .statusPage: (#selector(self.openStatusPage), nil)
        case .changelog: (#selector(self.openChangelog), nil)
        case .addCodexAccount: (#selector(self.addManagedCodexAccountFromMenu(_:)), nil)
        case .openCodexWorkspaces:
            (#selector(self.openCodexWorkspaces(_:)), CodexWorkspacesWindowIdentity.menuItem)
        case .settings: (#selector(self.showSettingsGeneral), nil)
        case .about: (#selector(self.showSettingsAbout), nil)
        case .quit: (#selector(self.quit), nil)
        default: preconditionFailure("Expected a simple menu action")
        }
    }

    func codexAddAccountSubtitle() -> String? {
        if self.settings.hasUnreadableManagedCodexAccountStore {
            return L("Managed account storage unavailable")
        }
        guard self.managedCodexAccountCoordinator.isAuthenticatingManagedAccount else { return nil }
        return L("Managed Codex login in progress…")
    }
}
