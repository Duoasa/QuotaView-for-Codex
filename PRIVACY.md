# Privacy

QuotaView for Codex stores its output locally and makes no direct HTTP
requests. For quota display, it launches the official `codex app-server`
process and calls only `account/rateLimits/read` and `account/usage/read`.
Codex owns authentication and any network access used to answer those calls;
the plugin never reads Codex authentication files or tokens.

It writes only one-way session/turn hashes, the final workspace folder name,
coarse tool category, lifecycle event, UTC timestamp, installation identifier,
sequence number, plugin version, and bridge health. It never writes prompts,
commands, full paths, file contents, tool inputs/outputs, model responses,
reasoning, account identifiers, email, tokens, cookies, credentials,
reset-credit inventory, or raw app-server responses.

The sanitized `usage.json` contains only the plan type, primary and optional
Spark rate-window percentage/duration/reset times, normal Credits balance
flags, limit-reached state, lifetime tokens, up to the newest 190 daily token
buckets, timestamps, protocol versions, source label, and plugin installation
identifier.

The newest 512 event records are retained in the plugin data directory. The
QuotaView app can read them only after the user selects that directory in the
macOS read-only folder picker. The plugin does not inspect QuotaView purchase
state and does not access the QuotaView sandbox container.
