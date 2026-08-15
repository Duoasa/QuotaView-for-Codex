#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h:h}"
bridge="${repo_root}/plugins/quotaview/scripts/quotaview-bridge"
mock_codex="${repo_root}/tests/fixtures/mock-codex-app-server"
plugin_version="$(/usr/bin/plutil -extract version raw -o - \
    "${repo_root}/plugins/quotaview/.codex-plugin/plugin.json")"
test_root="$(mktemp -d /private/tmp/quotaview-plugin-test.XXXXXX)"
trap '/bin/rm -rf -- "${test_root}"' EXIT

# The manifest explicitly declares the plugin-root hooks file. Hook commands
# run from the active workspace, so they must resolve through PLUGIN_ROOT.
[[ -f "${repo_root}/plugins/quotaview/hooks.json" ]]
[[ ! -e "${repo_root}/plugins/quotaview/hooks/hooks.json" ]]
/usr/bin/python3 -m json.tool \
    "${repo_root}/plugins/quotaview/hooks.json" >/dev/null
[[ "$(/usr/bin/plutil -extract hooks raw -o - \
    "${repo_root}/plugins/quotaview/.codex-plugin/plugin.json")" \
    == "./hooks.json" ]]
[[ "$(/usr/bin/plutil -extract hooks.SessionStart.0.hooks.0.timeout \
    raw -o - "${repo_root}/plugins/quotaview/hooks.json")" == "30" ]]
[[ "$(/usr/bin/plutil -extract hooks.Stop.0.hooks.0.timeout \
    raw -o - "${repo_root}/plugins/quotaview/hooks.json")" == "30" ]]
[[ "$(/usr/bin/plutil -extract interface.logo raw -o - \
    "${repo_root}/plugins/quotaview/.codex-plugin/plugin.json")" \
    == "./assets/logo.png" ]]
[[ "$(/usr/bin/plutil -extract interface.logoDark raw -o - \
    "${repo_root}/plugins/quotaview/.codex-plugin/plugin.json")" \
    == "./assets/logo.png" ]]
[[ "$(/usr/bin/plutil -extract interface.composerIcon raw -o - \
    "${repo_root}/plugins/quotaview/.codex-plugin/plugin.json")" \
    == "./assets/composer-icon.png" ]]
[[ "$(/usr/bin/plutil -extract description raw -o - \
    "${repo_root}/plugins/quotaview/.codex-plugin/plugin.json")" \
    == *"compatible apps"* ]]
[[ "$(/usr/bin/plutil -extract interface.longDescription raw -o - \
    "${repo_root}/plugins/quotaview/.codex-plugin/plugin.json")" \
    == *"any compatible client"* ]]
[[ -f "${repo_root}/plugins/quotaview/assets/logo.png" ]]
[[ -f "${repo_root}/plugins/quotaview/assets/composer-icon.png" ]]
[[ "$(/usr/bin/sips -g pixelWidth \
    "${repo_root}/plugins/quotaview/assets/logo.png" 2>/dev/null \
    | /usr/bin/awk '/pixelWidth/ {print $2}')" == "512" ]]
[[ "$(/usr/bin/sips -g pixelWidth \
    "${repo_root}/plugins/quotaview/assets/composer-icon.png" 2>/dev/null \
    | /usr/bin/awk '/pixelWidth/ {print $2}')" == "64" ]]
if ! /usr/bin/grep -q '\${PLUGIN_ROOT}/scripts/quotaview-bridge' \
    "${repo_root}/plugins/quotaview/hooks.json"; then
    print -u2 "Plugin hooks must resolve the bridge through PLUGIN_ROOT."
    exit 1
fi
if /usr/bin/grep -q '"command": "\./scripts/' \
    "${repo_root}/plugins/quotaview/hooks.json"; then
    print -u2 "Plugin hook commands must not depend on the session cwd."
    exit 1
fi

emit_event() {
    local event_name="$1"
    local tool_name="${2:-}"
    PLUGIN_DATA="${test_root}" \
    PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
    QUOTAVIEW_DISABLE_USAGE_REFRESH=1 \
        "${bridge}" "${event_name}" <<JSON
{"session_id":"private-session","turn_id":"private-turn","cwd":"/Users/example/QuotaView","tool_name":"${tool_name}","prompt":"must-not-leak","tool_input":{"command":"must-not-leak"}}
JSON
}

emit_event SessionStart
emit_event UserPromptSubmit
emit_event PreToolUse apply_patch
emit_event PostToolUse apply_patch
stop_output="$(emit_event Stop)"
[[ "${stop_output}" == "{}" ]]

# SessionStart and Stop refresh usage in-process so Codex cannot reap a
# detached refresh child when the lifecycle hook exits.
automatic_root="${test_root}/automatic-refresh"
mock_request_log="${test_root}/mock-app-server-requests.jsonl"
automatic_stop_output="$(
    PLUGIN_DATA="${automatic_root}" \
    PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
    CODEX_EXECUTABLE="${mock_codex}" \
    MOCK_CODEX_REQUEST_LOG="${mock_request_log}" \
        "${bridge}" Stop <<JSON
{"session_id":"automatic-session","turn_id":"automatic-turn","cwd":"/Users/example/QuotaView"}
JSON
)"
[[ "${automatic_stop_output}" == "{}" ]]
[[ -f "${automatic_root}/events/000000000001.json" ]]
[[ -f "${automatic_root}/usage.json" ]]
if ! /usr/bin/grep -Fq "\"version\":\"${plugin_version}\"" \
    "${mock_request_log}"; then
    print -u2 "The app-server client version must match the plugin manifest."
    exit 1
fi

# The usage path talks only to the official app-server protocol and persists
# an allowlisted projection instead of the raw response.
PLUGIN_DATA="${test_root}" \
PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
CODEX_EXECUTABLE="${mock_codex}" \
QUOTAVIEW_USAGE_REFRESH_FORCE=1 \
    "${bridge}" --refresh-usage
[[ -f "${test_root}/usage.json" ]]
[[ "$('/usr/bin/plutil' -extract usageSchemaVersion raw -o - \
    "${test_root}/usage.json")" == "1" ]]
[[ "$('/usr/bin/plutil' -extract primary.usedPercent raw -o - \
    "${test_root}/usage.json")" == "17" ]]
[[ "$('/usr/bin/plutil' -extract spark.usedPercent raw -o - \
    "${test_root}/usage.json")" == "29" ]]
[[ "$('/usr/bin/plutil' -extract spark.windowDurationMins raw -o - \
    "${test_root}/usage.json")" == "10080" ]]
[[ "$('/usr/bin/plutil' -extract lifetimeTokens raw -o - \
    "${test_root}/usage.json")" == "123456" ]]
[[ "$('/usr/bin/plutil' -extract recentDailyTokens raw -o - \
    "${test_root}/usage.json")" == "456" ]]
[[ "$('/usr/bin/plutil' -extract recentDailyDate raw -o - \
    "${test_root}/usage.json")" == "2026-08-08" ]]
[[ "$('/usr/bin/plutil' -extract dailyUsageBuckets raw -o - \
    "${test_root}/usage.json")" == "2" ]]
[[ "$('/usr/bin/plutil' -extract dailyUsageBuckets.0.tokens raw -o - \
    "${test_root}/usage.json")" == "123" ]]
[[ "$('/usr/bin/plutil' -extract dailyUsageBuckets.1.startDate raw -o - \
    "${test_root}/usage.json")" == "2026-08-08" ]]
[[ "$('/usr/bin/plutil' -extract capabilities raw -o - \
    "${test_root}/bridge.json")" == "2" ]]
if /usr/bin/grep -E \
    'must-not-copy|email|availableCount|resetCredit|longestStreak' \
    "${test_root}/usage.json"; then
    print -u2 "Raw or disallowed app-server data leaked into usage.json."
    exit 1
fi

# Lifecycle hooks may fire frequently. Automatic usage refreshes are merged
# into a five-minute window, while an expired snapshot refreshes immediately.
recent_epoch=$(( $(/bin/date +%s) - 120 ))
/usr/bin/touch -t "$(/bin/date -r "${recent_epoch}" +%Y%m%d%H%M.%S)" \
    "${test_root}/usage.json"
recent_mtime="$(/usr/bin/stat -f '%m' "${test_root}/usage.json")"
PLUGIN_DATA="${test_root}" \
PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
CODEX_EXECUTABLE="${mock_codex}" \
    "${bridge}" --refresh-usage
[[ "$(/usr/bin/stat -f '%m' "${test_root}/usage.json")" \
    == "${recent_mtime}" ]]

expired_epoch=$(( $(/bin/date +%s) - 360 ))
/usr/bin/touch -t "$(/bin/date -r "${expired_epoch}" +%Y%m%d%H%M.%S)" \
    "${test_root}/usage.json"
expired_mtime="$(/usr/bin/stat -f '%m' "${test_root}/usage.json")"
PLUGIN_DATA="${test_root}" \
PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
CODEX_EXECUTABLE="${mock_codex}" \
    "${bridge}" --refresh-usage
[[ "$(/usr/bin/stat -f '%m' "${test_root}/usage.json")" \
    -gt "${expired_mtime}" ]]

# Current Codex plugin variables take precedence over compatibility aliases.
official_data_root="${test_root}/official-data"
legacy_data_root="${test_root}/legacy-data"
PLUGIN_DATA="${official_data_root}" \
PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
CODEX_PLUGIN_DATA="${legacy_data_root}" \
CODEX_PLUGIN_ROOT="/invalid-codex-plugin-root" \
CLAUDE_PLUGIN_DATA="${legacy_data_root}" \
CLAUDE_PLUGIN_ROOT="/invalid-claude-plugin-root" \
    "${bridge}" --diagnose >/dev/null
[[ -f "${official_data_root}/bridge.json" ]]
[[ ! -e "${legacy_data_root}" ]]

# Older Codex hosts can still use the documented compatibility aliases.
compatibility_data_root="${test_root}/compatibility-data"
CLAUDE_PLUGIN_DATA="${compatibility_data_root}" \
CLAUDE_PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
    "${bridge}" --diagnose >/dev/null
[[ -f "${compatibility_data_root}/bridge.json" ]]

event_count="$(
    /usr/bin/find "${test_root}/events" -type f -name '[0-9]*.json' \
        | /usr/bin/wc -l \
        | /usr/bin/tr -d ' '
)"
[[ "${event_count}" == "5" ]]
[[ -f "${test_root}/events/000000000001.json" ]]
[[ -f "${test_root}/events/000000000005.json" ]]
[[ "$(/usr/bin/stat -f '%Lp' "${test_root}")" == "700" ]]
[[ "$(/usr/bin/stat -f '%Lp' "${test_root}/events")" == "700" ]]
[[ "$(/usr/bin/stat -f '%Lp' "${test_root}/bridge.json")" == "600" ]]
[[ "$(/usr/bin/stat -f '%Lp' \
    "${test_root}/events/000000000001.json")" == "600" ]]

latest_sequence="$(
    /usr/bin/plutil -extract latestSequence raw -o - \
        "${test_root}/status.json"
)"
[[ "${latest_sequence}" == "5" ]]

tool_category="$(
    /usr/bin/plutil -extract activity.toolCategory raw -o - \
        "${test_root}/events/000000000003.json"
)"
[[ "${tool_category}" == "fileEdit" ]]

if /usr/bin/grep -R -E \
    'private-session|private-turn|must-not-leak|/Users/example' \
    "${test_root}"; then
    print -u2 "Sensitive hook input leaked into bridge data."
    exit 1
fi

if /usr/bin/find "${test_root}" -name '.*.json' -print -quit \
    | /usr/bin/grep -q .; then
    print -u2 "An atomic-write temporary file was left behind."
    exit 1
fi

# A hook that does not own the sequence lock must never remove another
# writer's lock during cleanup.
/bin/mkdir "${test_root}/.sequence.lock"
emit_event Stop
[[ -d "${test_root}/.sequence.lock" ]]
/bin/rmdir "${test_root}/.sequence.lock"

# A plugin update refreshes the advertised version while preserving the
# installation identifier and bridge creation time.
installation_before="$(
    /usr/bin/plutil -extract installationIdentifier raw -o - \
        "${test_root}/bridge.json"
)"
created_before="$(
    /usr/bin/plutil -extract createdAt raw -o - \
        "${test_root}/bridge.json"
)"
/usr/bin/plutil -replace pluginVersion -string 0.0.0 \
    "${test_root}/bridge.json"
PLUGIN_DATA="${test_root}" \
PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
    "${bridge}" --diagnose >/dev/null
[[ "$(/usr/bin/plutil -extract pluginVersion raw -o - \
    "${test_root}/bridge.json")" == "${plugin_version}" ]]
[[ "$(/usr/bin/plutil -extract installationIdentifier raw -o - \
    "${test_root}/bridge.json")" == "${installation_before}" ]]
[[ "$(/usr/bin/plutil -extract createdAt raw -o - \
    "${test_root}/bridge.json")" == "${created_before}" ]]

# Tampered local handshake metadata is repaired before it reaches QuotaView.
/usr/bin/plutil -replace createdAt -string invalid-date \
    "${test_root}/bridge.json"
/usr/bin/printf '%s\n' 'invalid"identifier' \
    > "${test_root}/.installation-id"
PLUGIN_DATA="${test_root}" \
PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
    "${bridge}" --diagnose >/dev/null
repaired_installation="$(
    /usr/bin/plutil -extract installationIdentifier raw -o - \
        "${test_root}/bridge.json"
)"
[[ "${repaired_installation}" != 'invalid"identifier' ]]
[[ "${#repaired_installation}" -ge 8 ]]
[[ "$(/usr/bin/plutil -extract createdAt raw -o - \
    "${test_root}/bridge.json")" != "invalid-date" ]]

/usr/bin/printf '%s\n' "QuotaView bridge tests passed."
