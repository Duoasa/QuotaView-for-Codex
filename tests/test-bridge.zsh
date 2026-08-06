#!/bin/zsh

set -euo pipefail

repo_root="${0:A:h:h}"
bridge="${repo_root}/plugins/quotaview/scripts/quotaview-bridge"
test_root="$(mktemp -d /private/tmp/quotaview-plugin-test.XXXXXX)"
trap '/bin/rm -rf -- "${test_root}"' EXIT

emit_event() {
    local event_name="$1"
    local tool_name="${2:-}"
    PLUGIN_DATA="${test_root}" \
    CODEX_PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
        "${bridge}" "${event_name}" <<JSON
{"session_id":"private-session","turn_id":"private-turn","cwd":"/Users/example/QuotaView","tool_name":"${tool_name}","prompt":"must-not-leak","tool_input":{"command":"must-not-leak"}}
JSON
}

emit_event SessionStart
emit_event UserPromptSubmit
emit_event PreToolUse apply_patch
emit_event PostToolUse apply_patch
emit_event Stop

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
CODEX_PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
    "${bridge}" --diagnose >/dev/null
[[ "$(/usr/bin/plutil -extract pluginVersion raw -o - \
    "${test_root}/bridge.json")" == "1.0.0-preview.1" ]]
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
CODEX_PLUGIN_ROOT="${repo_root}/plugins/quotaview" \
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
