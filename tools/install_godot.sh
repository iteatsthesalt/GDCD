#!/usr/bin/env bash
# Install the pinned Godot editor binary (headless-capable) for Linux x86_64,
# and optionally the Web export templates.
#
#   tools/install_godot.sh                 # editor binary only
#   tools/install_godot.sh --web-templates # also Web export templates
#
# Env overrides:
#   GODOT_VERSION  version to install (default: contents of .godot-version)
#   GODOT_BIN_DIR  where to put the `godot` binary (default: /usr/local/bin if
#                  writable, else ~/.local/bin)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${GODOT_VERSION:-$(tr -d '[:space:]' < "$ROOT/.godot-version")}"
FLAVOR="stable"
MIRROR="https://downloads.godotengine.org/?version=${VERSION}&flavor=${FLAVOR}"

if [[ -z "${GODOT_BIN_DIR:-}" ]]; then
  if [[ -w /usr/local/bin ]]; then GODOT_BIN_DIR=/usr/local/bin; else GODOT_BIN_DIR="$HOME/.local/bin"; fi
fi
mkdir -p "$GODOT_BIN_DIR"
BIN="$GODOT_BIN_DIR/godot"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [[ -x "$BIN" ]] && "$BIN" --version 2>/dev/null | grep -q "^${VERSION}\.${FLAVOR}\."; then
  echo "Godot ${VERSION}-${FLAVOR} already installed at $BIN"
else
  echo "Downloading Godot ${VERSION}-${FLAVOR}..."
  curl -fsSL --retry 3 -o "$tmp/godot.zip" "${MIRROR}&slug=linux.x86_64.zip&platform=linux.64"
  python3 -m zipfile -e "$tmp/godot.zip" "$tmp/out"
  install -m 755 "$tmp/out/Godot_v${VERSION}-${FLAVOR}_linux.x86_64" "$BIN"
  echo "Installed $("$BIN" --version) at $BIN"
fi

if [[ "${1:-}" == "--web-templates" ]]; then
  TPL_DIR="$HOME/.local/share/godot/export_templates/${VERSION}.${FLAVOR}"
  if [[ -f "$TPL_DIR/web_nothreads_release.zip" ]]; then
    echo "Web export templates already present in $TPL_DIR"
  else
    echo "Downloading export templates (~1.3 GB, only Web templates are kept)..."
    curl -fsSL --retry 3 -o "$tmp/templates.tpz" "${MIRROR}&slug=export_templates.tpz&platform=templates"
    mkdir -p "$TPL_DIR"
    python3 - "$tmp/templates.tpz" "$TPL_DIR" <<'PY'
import os, sys, zipfile
src, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(src) as z:
    for name in z.namelist():
        base = os.path.basename(name)
        if base.startswith("web_") or base == "version.txt":
            with z.open(name) as f, open(os.path.join(dest, base), "wb") as out:
                out.write(f.read())
            print("  " + base)
PY
  fi
fi
