---
name: quotaview-setup
description: Connect, diagnose, explain, or disconnect the QuotaView for Codex local activity bridge. Use when the user asks to connect QuotaView, pair the Codex Island, check QuotaView plugin status, inspect QuotaView privacy, or troubleshoot missing island activity.
---

# QuotaView for Codex setup

This plugin writes a minimal local activity stream for the QuotaView macOS app.
It never writes prompts, command text, tool input/output, file paths or contents,
model responses, reasoning, account identifiers, tokens, cookies, or credentials.
It performs no network requests.

## Connect QuotaView

1. Explain that the user will approve both Codex Hook trust and a macOS
   read-only folder picker. These are separate permissions.
2. Run:

   ```sh
   "${CODEX_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT}}/scripts/quotaview-bridge" --pair
   ```

3. Tell the user to confirm the `PLUGIN_DATA` folder in QuotaView.
4. Do not edit `~/.codex`, install a helper, or bypass Hook trust.

## Check the connection

Run:

```sh
"${CODEX_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT}}/scripts/quotaview-bridge" --diagnose
```

Report only the protocol version, plugin version, whether a local event exists,
and that network access is disabled. Do not print the full data path or event
contents.

If QuotaView says “Waiting for Event,” ask the user to verify all four items:

- the plugin is installed and enabled;
- Hooks are enabled and trusted in Codex;
- QuotaView has read-only access to the selected `PLUGIN_DATA` folder;
- a new Codex task or prompt was started after setup.

## Explain privacy

The bridge stores only:

- one-way hashes of session and optional turn identifiers;
- the final workspace folder name, capped at 80 characters;
- a coarse tool category;
- lifecycle event, UTC timestamp, protocol version, installation ID, sequence;
- plugin health metadata.

Events remain local, are never uploaded by the plugin, and rotate after the
newest 512 records. QuotaView does not modify these files.

## Disconnect or uninstall

Tell the user to disconnect the folder in QuotaView first, then disable or
uninstall the plugin in Codex. Do not delete the plugin data directory on the
user's behalf. QuotaView purchase state is managed only by the App Store and is
not stored in this plugin.
