# QuotaView for Codex

Preview Codex plugin for QuotaView on macOS. It uses official Codex read-only
app-server methods to write a sanitized usage snapshot, and observes supported
Codex lifecycle Hooks for the activity island. QuotaView reads the plugin data
directory only after the user grants read-only access in a macOS system picker.

This repository is the Preview Git Marketplace channel. It is not an OpenAI
official plugin and does not change Codex approvals, Hook trust, or sandboxing.

## Install the Preview marketplace

The published `v1.0.0-preview.1` release supports sanitized activity events.
The usage-snapshot capability in this working tree is the unreleased
`1.0.0-preview.4` candidate. Until a new fixed tag is published, the commands
below are suitable for Island testing but must not be represented as providing
the new quota snapshot.

```sh
codex plugin marketplace add Duoasa/QuotaView-for-Codex --ref v1.0.0-preview.1
codex plugin add quotaview@quotaview-preview
```

For local plugin development, replace the first command with:

```sh
codex plugin marketplace add /path/to/QuotaView-for-Codex
```

Use the local checkout when validating the `preview.4` usage path.

Enable Hooks in Codex if required, review and trust the plugin Hooks, then use
the starter prompt “Connect QuotaView to Codex.” QuotaView will open a
macOS folder picker; select the plugin's `PLUGIN_DATA` folder shown by Codex.

Sign in through official Codex. A validated usage snapshot enables QuotaView's
quota display, while the first validated event enables live Codex Island
status. The public plugin contains no license check or payment flow.

While Codex is active, `SessionStart` and `Stop` Hooks refresh the sanitized
usage snapshot in-process. Refreshes are merged into a five-minute window so
frequent tasks do not repeatedly start `codex app-server`. QuotaView's menu
refresh rereads the latest local snapshot and events; a true forced upstream
refresh remains an explicit plugin command.

## Supported Preview events

- `SessionStart`
- `SessionEnd`
- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `Stop`

Other reducer states remain reserved in bridge protocol v1 and will be added
only when Codex exposes stable plugin Hook events for them.

## Data contract

The plugin writes `bridge.json`, `status.json`, `usage.json`, and monotonic JSON
files under `events/`. The usage file is an allowlisted projection of official
Codex read-only results: plan type, primary rate window, normal Credits balance,
limit state, lifetime tokens, and the newest daily token bucket. Event files
store only hashed session/turn identifiers, the last workspace folder name, a
coarse tool category, event type, timestamps, and bridge health. It stores no
prompt text, command text, full path, files, tool payloads, model output,
reasoning, account identifiers, email, token, cookie, credential, reset-credit
inventory, or raw app-server response.

See [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md).

## Requirements

- macOS 14 or later
- a Codex build with plugin Hooks enabled
- QuotaView 1.0.0 or later
- manual Hook trust in Codex
- sign-in through official Codex
- manual read-only directory authorization in QuotaView

## Uninstall

Disconnect the plugin data folder in QuotaView, then disable or uninstall
`quotaview` in Codex. Neither QuotaView nor the plugin deletes Codex settings or
other user files.

## Contributor release checks

The release workflow is documented in [RELEASING.md](RELEASING.md). Local
candidate validation includes an isolated install/uninstall/reinstall check;
fixed tags are packaged twice and must produce byte-identical source assets.
The tag workflow uploads a verified CI artifact but never creates a GitHub
Release automatically.
