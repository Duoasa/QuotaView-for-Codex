# Releasing QuotaView for Codex

This repository uses immutable annotated tags and deterministic source assets.
Publishing a tag or GitHub Release remains an explicit product-owner action.

## Candidate checks

Before creating a release commit, run:

```sh
python3 -m json.tool plugins/quotaview/.codex-plugin/plugin.json >/dev/null
python3 -m json.tool plugins/quotaview/hooks.json >/dev/null
python3 -m json.tool .agents/plugins/marketplace.json >/dev/null
zsh -n plugins/quotaview/scripts/quotaview-bridge tests/test-bridge.zsh
tests/test-bridge.zsh
scripts/check-clean-install.zsh
git diff --check
```

The clean-install check uses a new temporary `CODEX_HOME`. It does not modify
the current user's marketplace, plugin cache, trust records, or plugin data.

## Fixed release identity

Create one release commit, then create a new annotated tag whose name exactly
matches `v` plus the plugin manifest version. Never move or replace a published
tag.

```sh
git tag -a v1.0.0-preview.N -m "QuotaView for Codex 1.0.0 Preview N"
```

After the tag exists, generate and validate the custom source asset:

```sh
scripts/build-release-asset.zsh \
  v1.0.0-preview.N \
  /private/tmp/quotaview-plugin-release
```

The command archives only the fixed Git ref, generates it twice, requires
byte-identical output, validates required files and executable bits, rejects
local data and symlinks, parses all JSON, extracts the archive, and reruns the
bridge test. It prints the final byte size and SHA-256.

The tag workflow performs the same check and uploads a CI artifact. It does not
create or modify a GitHub Release. Upload the exact verified bytes only after
the product owner authorizes publication, then download the public asset and
compare its size and SHA-256 again.

## Release acceptance

A published preview is not ready for App Review Notes until all of these pass:

- anonymous HTTPS clone of the exact tag;
- official plugin and Skill validators on the fixed contents;
- public asset download and SHA-256 comparison;
- installation from a Codex home with no prior Marketplace or plugin state;
- non-bypassed Hook review and trust;
- QuotaView macOS folder-picker pairing;
- real lifecycle and tool events through the production reader;
- uninstall, reinstall, and fixed-tag upgrade;
- product-owner visual and interaction review of the Codex Island.
