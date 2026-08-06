# Privacy

QuotaView for Codex is local-only and makes no network requests.

It writes only one-way session/turn hashes, the final workspace folder name,
coarse tool category, lifecycle event, UTC timestamp, installation identifier,
sequence number, plugin version, and bridge health. It never writes prompts,
commands, full paths, file contents, tool inputs/outputs, model responses,
reasoning, account identifiers, tokens, cookies, or credentials.

The newest 512 event records are retained in the plugin data directory. The
QuotaView app can read them only after the user selects that directory in the
macOS read-only folder picker. The plugin does not inspect QuotaView purchase
state and does not access the QuotaView sandbox container.
