# QuotaView for Codex

Preview Codex plugin for the QuotaView macOS activity island. It observes
supported Codex lifecycle Hooks and writes a bounded, sanitized event stream to
the plugin data directory. QuotaView reads that directory only after the user
grants read-only access in a macOS system picker.

This repository is the Preview Git Marketplace channel. It is not an OpenAI
official plugin and does not change Codex approvals, Hook trust, or sandboxing.

## Install the Preview marketplace

```sh
codex plugin marketplace add Duoasa/QuotaView-for-Codex --ref v1.0.0-preview.1
codex plugin add quotaview@quotaview-preview
```

For local plugin development, replace the first command with:

```sh
codex plugin marketplace add /path/to/QuotaView-for-Codex
```

Enable Hooks in Codex if required, review and trust the plugin Hooks, then use
the starter prompt “Connect the QuotaView Codex Island.” QuotaView will open a
macOS folder picker; select the plugin's `PLUGIN_DATA` folder shown by Codex.

The first validated event changes QuotaView from “Waiting for Event” to
“Connected.” The QuotaView App Store purchase controls whether events render the
island; the public plugin itself contains no license check or payment flow.

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

The plugin writes `bridge.json`, `status.json`, and monotonic JSON files under
`events/`. It stores only hashed session/turn identifiers, the last workspace
folder name, a coarse tool category, event type, timestamps, and bridge health.
It stores no prompt text, command text, full path, files, tool payloads, model
output, reasoning, account data, token, cookie, or credential.

See [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md).

## Requirements

- macOS 14 or later
- a Codex build with plugin Hooks enabled
- QuotaView 1.0.0 or later
- manual Hook trust in Codex
- manual read-only directory authorization in QuotaView

## Uninstall

Disconnect the plugin data folder in QuotaView, then disable or uninstall
`quotaview` in Codex. Neither QuotaView nor the plugin deletes Codex settings or
other user files.
