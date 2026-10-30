#!/bin/sh
# Headless mod test: compiles the app's Foundation-only mod host files with a
# macOS test harness and runs every bundled mod against live data from
# $MODS_TEST_HOST (read-only commands over ssh; see Policy in main.swift).
#
#   scripts/mods-test/run.sh                 # all mods
#   MODS_TEST_ONLY=prs scripts/mods-test/run.sh
#   MODS_TEST_VERBOSE=1 ...                  # print mod console output
#   REBUNDLE=1 ...                           # run scripts/bundle-mods.sh first
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/mods-test"
mkdir -p "$OUT"
[ "${REBUNDLE:-0}" = "1" ] && "$ROOT/scripts/bundle-mods.sh"

SRC="$ROOT/App/Sources/Mods"
xcrun swiftc -swift-version 5 -O -parse-as-library \
  -module-name ModsTest \
  "$SRC/ModEngine.swift" "$SRC/ModNode.swift" "$SRC/ModModel.swift" "$SRC/ModSVG.swift" \
  "$ROOT/scripts/mods-test/main.swift" \
  -o "$OUT/mods-test"
exec "$OUT/mods-test" "$ROOT"
