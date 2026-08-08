#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
repo_root="${script_dir:h}"
git_ref="${1:-}"
output_dir="${2:-}"

fail() {
    print -u2 "QuotaView plugin release asset check failed: $1"
    exit 2
}

if [[ -z "${git_ref}" || -z "${output_dir}" || -n "${3:-}" ]]; then
    print -u2 "Usage: ${0:t} GIT_TAG /absolute/output/directory"
    exit 64
fi

[[ "${output_dir}" == /* ]] \
    || fail "the output directory must be absolute"

tag_object="$(git -C "${repo_root}" rev-parse --verify "${git_ref}^{tag}")" \
    || fail "Git ref '${git_ref}' is not an annotated tag"
commit="$(git -C "${repo_root}" rev-parse --verify "${git_ref}^{commit}")" \
    || fail "Git ref '${git_ref}' does not resolve to a commit"
manifest="$(
    git -C "${repo_root}" show \
        "${git_ref}:plugins/quotaview/.codex-plugin/plugin.json"
)" || fail "the fixed ref does not contain the plugin manifest"
plugin_version="$(
    /usr/bin/printf '%s' "${manifest}" \
        | /usr/bin/plutil -extract version raw -o - - 2>/dev/null
)" || fail "the fixed ref has an invalid plugin version"
expected_tag="v${plugin_version}"
[[ "${git_ref}" == "${expected_tag}" ]] \
    || fail "tag '${git_ref}' must exactly match manifest version '${expected_tag}'"
hooks_relative_path="plugins/quotaview/hooks.json"
if [[ "${plugin_version}" == "1.0.0-preview.1" ]]; then
    hooks_relative_path="plugins/quotaview/hooks/hooks.json"
fi

asset_base="QuotaView-for-Codex-${git_ref}"
asset_name="${asset_base}.tar.gz"
temporary_root="$(
    /usr/bin/mktemp -d /private/tmp/quotaview-plugin-release.XXXXXX
)"
trap '/bin/rm -rf -- "${temporary_root}"' EXIT

first_archive="${temporary_root}/first.tar.gz"
second_archive="${temporary_root}/second.tar.gz"
for archive_path in "${first_archive}" "${second_archive}"; do
    git -C "${repo_root}" archive \
        --format=tar.gz \
        --prefix="${asset_base}/" \
        --output="${archive_path}" \
        "${git_ref}"
done
/usr/bin/cmp -s "${first_archive}" "${second_archive}" \
    || fail "two archives generated from the same ref are not byte-identical"

extract_root="${temporary_root}/extracted"
/bin/mkdir -p "${extract_root}"
/usr/bin/tar -xzf "${first_archive}" -C "${extract_root}"
package_root="${extract_root}/${asset_base}"
[[ -d "${package_root}" ]] || fail "the archive prefix is incorrect"

for required_path in \
    ".agents/plugins/marketplace.json" \
    "plugins/quotaview/.codex-plugin/plugin.json" \
    "${hooks_relative_path}" \
    "plugins/quotaview/scripts/quotaview-bridge" \
    "plugins/quotaview/skills/quotaview-setup/SKILL.md" \
    "tests/test-bridge.zsh" \
    "README.md" \
    "PRIVACY.md" \
    "SECURITY.md" \
    "TERMS.md" \
    "LICENSE"; do
    [[ -f "${package_root}/${required_path}" ]] \
        || fail "release archive is missing ${required_path}"
done

[[ -x "${package_root}/plugins/quotaview/scripts/quotaview-bridge" ]] \
    || fail "the bridge writer lost its executable bit"
[[ -x "${package_root}/tests/test-bridge.zsh" ]] \
    || fail "the bridge test lost its executable bit"

for json_file in \
    "${package_root}/.agents/plugins/marketplace.json" \
    "${package_root}/plugins/quotaview/.codex-plugin/plugin.json" \
    "${package_root}/${hooks_relative_path}"; do
    /usr/bin/python3 -m json.tool "${json_file}" >/dev/null \
        || fail "release archive contains invalid JSON: ${json_file:t}"
done

if /usr/bin/find "${package_root}" \
    \( -name '.git' -o -name '.DS_Store' -o -name 'data' \
       -o -name '*.pyc' -o -name '__pycache__' \) \
    -print -quit | /usr/bin/grep -q .; then
    fail "release archive contains generated, repository, or local data"
fi
if /usr/bin/find "${package_root}" -type l -print -quit \
    | /usr/bin/grep -q .; then
    fail "release archive contains a symbolic link"
fi
if /usr/bin/find "${package_root}" -type f \
    \( -name '*.dylib' -o -name '*.so' -o -name '*.a' -o -name '*.o' \
       -o -name '*.bin' -o -name '*.exe' -o -name '*.wasm' \) \
    -print -quit | /usr/bin/grep -q .; then
    fail "release archive contains a compiled or binary payload"
fi

(
    cd "${package_root}"
    zsh tests/test-bridge.zsh >/dev/null
) || fail "the extracted bridge test failed"

/bin/mkdir -p "${output_dir}"
output_path="${output_dir}/${asset_name}"
/bin/cp -f "${first_archive}" "${output_path}"
asset_size="$(/usr/bin/stat -f '%z' "${output_path}")"
asset_sha="$(/usr/bin/shasum -a 256 "${output_path}" | /usr/bin/awk '{print $1}')"

print "QuotaView plugin release asset checks passed."
print "Tag: ${git_ref}"
print "Tag object: ${tag_object}"
print "Commit: ${commit}"
print "Plugin version: ${plugin_version}"
print "Asset: ${output_path}"
print "Size: ${asset_size} bytes"
print "SHA-256: ${asset_sha}"
