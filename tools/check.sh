#!/usr/bin/env bash
# Validate the whole project headlessly. Run this before every commit.
# Exits non-zero on the first failing step.
#
#   tools/check.sh            # import, lint, format check, parse, tests, boot
#   tools/check.sh --fix      # same, but let gdformat rewrite files first
#
# Env: GODOT (default: godot), BOOT_FRAMES (default: 120)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

GODOT="${GODOT:-godot}"
BOOT_FRAMES="${BOOT_FRAMES:-120}"
# build/ holds logs and exports; .gdignore stops Godot importing anything in it.
mkdir -p build && touch build/.gdignore

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31mFAIL: %s\033[0m\n' "$*" >&2; exit 1; }
# Godot often exits 0 even after script errors, so scan its log as well.
scan_log() {
  if grep -nE '^(SCRIPT )?ERROR:|Parse Error' "$1"; then die "$2 (see $1)"; fi
}

command -v "$GODOT" >/dev/null || die "godot not found; run tools/install_godot.sh"
command -v gdlint >/dev/null || die "gdtoolkit not found; run: pip install 'gdtoolkit==4.*'"

mapfile -t GD_FILES < <(git ls-files -co --exclude-standard -- '*.gd' ':!:addons/**')

step "Import project ($("$GODOT" --version))"
"$GODOT" --headless --import --path . >build/import.log 2>&1 || { cat build/import.log; die "import crashed"; }
scan_log build/import.log "errors during import"

if [[ "${1:-}" == "--fix" ]]; then
  step "Format (gdformat)"
  gdformat "${GD_FILES[@]}"
fi

step "Lint (gdlint) and format check (gdformat --check)"
gdlint "${GD_FILES[@]}"
gdformat --check "${GD_FILES[@]}" || die "formatting differs; run tools/check.sh --fix"

step "Parse and compile every script"
"$GODOT" --headless --path . --script res://tools/validate_scripts.gd 2>&1 | tee build/validate.log
[[ ${PIPESTATUS[0]} -eq 0 ]] || die "script validation failed"

step "Unit tests (GUT)"
rm -f build/test-results.xml
set +e
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd >build/tests.log 2>&1
status=$?
set -e
grep -vE '^\s*$' build/tests.log | tail -n 15
[[ $status -eq 0 ]] || die "tests failed (full log: build/tests.log)"
# GUT exits 0 without running anything if its classes were never imported.
[[ -f build/test-results.xml ]] || die "GUT produced no results file; did it actually run?"

step "Boot main scene for $BOOT_FRAMES frames"
"$GODOT" --headless --path . --quit-after "$BOOT_FRAMES" >build/boot.log 2>&1 || { cat build/boot.log; die "game crashed on boot"; }
scan_log build/boot.log "errors while running the main scene"

printf '\n\033[32mAll checks passed.\033[0m\n'
