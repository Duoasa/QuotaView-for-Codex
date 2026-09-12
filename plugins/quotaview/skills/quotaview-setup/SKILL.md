---
name: quotaview-setup
description: Pair, diagnose, refresh, or disconnect the QuotaView plugin bridge; explain its local data and permissions.
---

# QuotaView for Codex setup

This plugin writes a minimal local usage snapshot and activity stream for the
QuotaView macOS app. It asks the official `codex app-server` process for
read-only account rate-limit and token-usage summaries. Codex owns sign-in and
network access; the plugin never reads auth files or makes direct HTTP requests.
It never writes prompts, command text, tool input/output, file paths or
contents, model responses, reasoning, account identifiers, email, tokens,
cookies, credentials, reset-credit inventory, or raw app-server responses.

## Choose the requested action

Use only the action the user requested. Pairing is not a prerequisite for status,
privacy, or refresh requests. Existing authorization for an action remains valid;
complete its available checks without a second generic confirmation. Actual Codex
Hook trust and macOS folder consent must still be completed by the user.
For the stored-data contract, read [privacy](references/privacy.md) only as needed.

## Connect QuotaView

1. Explain that the user will approve both Codex Hook trust and a macOS
   read-only folder picker. These are separate permissions.
2. Run:

   ```sh
   "${PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT}}}/scripts/quotaview-bridge" --pair
   ```

3. Tell the user to confirm the `PLUGIN_DATA` folder in QuotaView.
4. Do not edit `~/.codex`, install a helper, or bypass Hook trust.

## Check the connection

Run:

```sh
"${PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT}}}/scripts/quotaview-bridge" --diagnose
```

Report only the protocol version, plugin version, whether a local event and
sanitized usage snapshot exist, and that authentication is managed by official
Codex. Do not print the full data path or file contents.

If QuotaView says “Waiting for Event,” use the diagnosis to narrow the missing condition. Ask the user only about items that tools cannot establish, instead of repeating the full checklist:

- the plugin is installed and enabled;
- Hooks are enabled and trusted in Codex;
- QuotaView has read-only access to the selected `PLUGIN_DATA` folder;
- the user is signed in through official Codex;
- a new Codex task or prompt was started after setup.

To request an immediate sanitized usage refresh, run:

```sh
QUOTAVIEW_USAGE_REFRESH_FORCE=1 \
"${PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT}}}/scripts/quotaview-bridge" --refresh-usage
```

During normal Codex activity, `SessionStart` and `Stop` also refresh the usage
snapshot in-process when its previous write is at least five minutes old.
Frequent lifecycle events are merged into that five-minute window.

Do not print `usage.json` or any app-server response.

## Completion

Report the requested action's result and any actual remaining system consent or
new-event requirement. A successful command alone does not prove that QuotaView
is displaying events; do not claim pairing or live activity without evidence.
If consent is pending, complete independent diagnosis and give the exact next step.

## Disconnect or uninstall

Tell the user to disconnect the folder in QuotaView first, then disable or
uninstall the plugin in Codex. Do not delete the plugin data directory on the
user's behalf. QuotaView purchase state is managed only by the App Store and is
not stored in this plugin.
