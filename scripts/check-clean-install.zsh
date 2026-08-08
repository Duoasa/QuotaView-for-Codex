#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
plugin_root="${repo_root}/plugins/quotaview"
marketplace_file="${repo_root}/.agents/plugins/marketplace.json"
codex_bin="${CODEX_BIN:-$(command -v codex || true)}"

fail() {
    print -u2 "QuotaView plugin clean-install check failed: $1"
    exit 2
}

[[ -x "${codex_bin}" ]] || fail "Codex CLI is unavailable"
[[ -f "${marketplace_file}" ]] || fail "Marketplace manifest is missing"
expected_version="$(
    /usr/bin/plutil -extract version raw -o - \
        "${plugin_root}/.codex-plugin/plugin.json"
)"
marketplace_name="$(
    /usr/bin/plutil -extract name raw -o - "${marketplace_file}"
)"
selector="quotaview@${marketplace_name}"

isolated_home="$(
    /usr/bin/mktemp -d /private/tmp/quotaview-codex-clean-install.XXXXXX
)"
trap '/bin/rm -rf -- "${isolated_home}"' EXIT

installed_count() {
    CODEX_HOME="${isolated_home}" "${codex_bin}" plugin list --json \
        | /usr/bin/plutil -extract installed raw -o - - 2>/dev/null
}

install_and_verify() {
    local install_result installed_version installed_path
    install_result="$(
        CODEX_HOME="${isolated_home}" \
            "${codex_bin}" plugin add "${selector}" --json
    )"
    installed_version="$(
        /usr/bin/printf '%s' "${install_result}" \
            | /usr/bin/plutil -extract version raw -o - -
    )"
    installed_path="$(
        /usr/bin/printf '%s' "${install_result}" \
            | /usr/bin/plutil -extract installedPath raw -o - -
    )"
    [[ "${installed_version}" == "${expected_version}" ]] \
        || fail "installed version '${installed_version}' does not match '${expected_version}'"
    [[ "${installed_path}" == "${isolated_home}"/* ]] \
        || fail "Codex installed outside the isolated home"
    /usr/bin/diff -qr "${plugin_root}" "${installed_path}" >/dev/null \
        || fail "installed cache differs from the candidate source"
}

[[ "$(installed_count)" == "0" ]] \
    || fail "isolated Codex home did not start empty"
CODEX_HOME="${isolated_home}" \
    "${codex_bin}" plugin marketplace add "${repo_root}" --json >/dev/null
install_and_verify
[[ "$(installed_count)" == "1" ]] \
    || fail "first installation was not enabled"

CODEX_HOME="${isolated_home}" \
    "${codex_bin}" plugin remove "${selector}" --json >/dev/null
[[ "$(installed_count)" == "0" ]] \
    || fail "isolated uninstall left an installed plugin entry"

install_and_verify
[[ "$(installed_count)" == "1" ]] \
    || fail "reinstallation was not enabled"

print "QuotaView plugin clean-install checks passed."
print "Marketplace: ${marketplace_name}"
print "Plugin version: ${expected_version}"
print "First install, uninstall, reinstall, and exact cache comparison passed."
