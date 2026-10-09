# Scapolite privacy and cleanup

Scapolite keeps account credentials, cookies, usage snapshots, discovered sessions and Telegram tokens on the
user's Mac. Tests use fabricated accounts and in-memory credential stores. Live QA output must stay outside the
checkout; never commit account screenshots, configuration exports, session transcripts or diagnostic logs.

## macOS access warnings

Quota-only Claude CLI sessions explicitly disable browser integration with `--no-chrome`. They do not need
browser profiles, tools or Remote Control, and this override does not change the user's normal Claude sessions.
See the [official Claude CLI reference](https://code.claude.com/docs/en/cli-reference). macOS may attribute a
child CLI's denied app-data read to Scapolite; an access-denied notification is not evidence of an upload.
Do not grant Full Disk Access simply to dismiss it. Optional browser-cookie imports and desktop-session
discovery are separate data sources and can require permission.

Packaging uses SwiftPM's `--disable-keychain` and Xcode's `-packageAuthorizationProvider netrc` so package
resolution does not unlock the login Keychain. Ad-hoc signing does not require an Apple Developer identity.
Debug and release builds share provider configuration but have separate app preferences; first-launch
detection preserves enabled providers and recognizes Antigravity CLI without requiring its IDE to be running.

## Reviewed history

The initial Gitleaks audit scanned 7,498 commits and reported 46 inherited matches. None came from the two
Scapolite feature commits. The matches were reviewed with credential values redacted:

- Fabricated JWTs, API-token examples, placeholder authorization headers and opaque test account keys.
- Model identifiers, translated strings and encoded provider icon data that resemble token assignments.
- Public installed-app OAuth client identifiers, not a user's access or refresh token.
- Legacy shared desktop OAuth client credentials distributed by upstream, not a user's credentials; the current
  Antigravity integration discovers or accepts configured client credentials instead of embedding those values.
- The Firebase project identifier embedded in the public Windsurf frontend, not a user's session credential.
- The upstream Sparkle **public** verification key, not a private signing key.

`.gitleaksignore` records only these exact historical fingerprints. It does not allowlist test directories,
providers or future commits. New secrets still fail the GitHub privacy check. Firebase's key role is explained
in [the official documentation](https://firebase.google.com/docs/projects/api-keys).

Tracked files, historical patches, the repository's public issue and comments, and publication surfaces are
checked separately. A scanner result is not a guarantee against every kind of personal data. Screenshots and
fixture identities require review as well. Git author metadata is public; use a GitHub noreply address for new
commits. Existing inherited author metadata is not rewritten.

## Cleanup policy

The cleanup follows [Ponytail's audit and review approach](https://github.com/DietrichGebert/ponytail): trace
callers and dynamic references before removal; reuse native controls; keep validation, accessibility,
credential isolation and data-loss handling. Ponytail is not an application dependency or an installed hook.

Old, unreferenced PR logs and screenshots are removed from the current tree. Git history keeps recoverable
copies. Future proof directories and audit output are ignored. Removing tracked files does not erase their
historical versions or automatically shrink the clone's Git history.

The current source tree drops from 57.63 MiB to approximately 48.56 MiB (about 16% smaller). Cleanup removes
95 obsolete proof files and the confetti implementation. Referenced screenshots were inspected separately;
they contain synthetic/example accounts or redacted data. Legacy pane helpers with test callers remain for
compatibility instead of deleting their coverage to improve the size counter.

Confetti's implementation and Vortex dependency are removed. Provider authentication, local session discovery,
system metrics, optional provider plugins and the user-owned Telegram integration remain available.

Source checkout size, release application size and local build caches are measured separately. Local `.build`
files and application bundles are not published source files. No tests, licenses or required provider assets
are removed merely to reduce a size counter.
