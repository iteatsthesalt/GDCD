#!/usr/bin/env bash
# Export the "Web" preset to build/web/ (needs: tools/install_godot.sh --web-templates).
# Preview locally with:  python3 -m http.server -d build/web 8000
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

GODOT="${GODOT:-godot}"
OUT=build/web
rm -rf "$OUT" && mkdir -p "$OUT"
# .gdignore stops Godot importing the exported PNGs/JS back into the project.
touch build/.gdignore

"$GODOT" --headless --path . --import >build/import.log 2>&1
"$GODOT" --headless --path . --export-release "Web" "$OUT/index.html" 2>&1 | tee build/export.log
# Godot can exit 0 on a failed export, so check the output exists.
for f in index.html index.pck index.wasm index.js; do
  [[ -s "$OUT/$f" ]] || { echo "FAIL: export did not produce $OUT/$f" >&2; exit 1; }
done
if grep -nE '^(SCRIPT )?ERROR:' build/export.log; then
  echo "FAIL: errors during export (see build/export.log)" >&2
  exit 1
fi
touch "$OUT/.nojekyll"
echo "Web build ready in $OUT ($(du -sh "$OUT" | cut -f1))"
