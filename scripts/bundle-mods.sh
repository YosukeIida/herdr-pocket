#!/bin/sh
# Bundles the user's herdr mods into App/Resources/Mods for the iOS mod host.
#
#   App/Resources/Mods/<name>.js     (function(__require, __exports){...}) for JavaScriptCore
#   App/Resources/Mods/<name>.json   mod.json + name + title
#   App/Resources/Mods/_catalog.json [{name, title}] in MODS order
#   App/Resources/Mods/_icons.json   {"mods/<folder>/<file>.svg": "<svg ...>"} for svg("...")
#
# Safe as an Xcode pre-build phase: when bun or the mod sources are missing it
# leaves the previous outputs alone and exits 0. Outputs are only rewritten when
# their bytes change, so incremental builds stay incremental.
#
# Env: MODS_SRC (default ~/.config/herdr-app/mods), MODS (space-separated list).
# The bundled outputs are gitignored: each builder ships their own mods.
set -u

# Which of your mods to bundle: $MODS, else Config/mods.txt (gitignored, one
# name per line), else none (the app then shows no mod cards).
ROOT0="$(cd "$(dirname "$0")/.." && pwd)"
# A line is "<mod folder> [<block id in the desktop layout>]".
BLOCKS=""
if [ -z "${MODS:-}" ] && [ -f "$ROOT0/Config/mods.txt" ]; then
  MODS="$(grep -v '^#' "$ROOT0/Config/mods.txt" | awk 'NF {print $1}' | tr '\n' ' ')"
  BLOCKS="$(grep -v '^#' "$ROOT0/Config/mods.txt" | awk 'NF >= 2 {print $1 "=" $2}' | tr '\n' ' ')"
fi
MODS="${MODS:-}"
# Folders whose .svg files are made available to svg("mods/<folder>/x.svg").
ICON_DIRS="${ICON_DIRS:-workspace-chrome}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${MODS_SRC:-$HOME/.config/herdr-app/mods}"
OUT="$ROOT/App/Resources/Mods"
TRANSFORM="$ROOT/scripts/mods-transform.mjs"

note() { echo "bundle-mods: $*"; }

BUN="$(command -v bun 2>/dev/null || true)"
[ -z "$BUN" ] && [ -x "$HOME/.bun/bin/bun" ] && BUN="$HOME/.bun/bin/bun"
if [ -z "$BUN" ]; then
  note "warning: bun not found; keeping the bundled copies in $OUT"
  exit 0
fi
if [ ! -d "$SRC" ]; then
  note "warning: $SRC not found; keeping the bundled copies in $OUT"
  exit 0
fi

mkdir -p "$OUT"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/herdr-mods.XXXXXX")" || exit 0
trap 'rm -rf "$TMP"' EXIT INT TERM

# Copies $1 to $2 only when the contents differ.
put() {
  if [ -f "$2" ] && cmp -s "$1" "$2"; then return 0; fi
  cp "$1" "$2" && note "wrote $(basename "$2")"
}

catalog=""
for m in $MODS; do
  dir="$SRC/$m"
  if [ ! -f "$dir/main.js" ]; then
    note "warning: $dir/main.js missing; keeping the previous $m bundle"
    [ -f "$OUT/$m.json" ] && catalog="$catalog $m"
    continue
  fi
  if ! "$BUN" build "$dir/main.js" --format=esm --target=browser \
      --external herdr --external gpui-kit --external gpui-base \
      --outfile "$TMP/$m.esm.js" >"$TMP/$m.log" 2>&1; then
    note "warning: bun build failed for $m; keeping the previous bundle"
    sed 's/^/  /' "$TMP/$m.log"
    [ -f "$OUT/$m.json" ] && catalog="$catalog $m"
    continue
  fi
  if ! "$BUN" "$TRANSFORM" "$TMP/$m.esm.js" "$TMP/$m.js" >"$TMP/$m.xlog" 2>&1; then
    note "warning: transform failed for $m; keeping the previous bundle"
    sed 's/^/  /' "$TMP/$m.xlog"
    [ -f "$OUT/$m.json" ] && catalog="$catalog $m"
    continue
  fi
  # mod.json + name + title (title falls back to the folder name).
  MOD_NAME="$m" MOD_JSON="$dir/mod.json" "$BUN" -e '
    const fs = require("fs");
    let j = {};
    try { j = JSON.parse(fs.readFileSync(process.env.MOD_JSON, "utf8")); } catch {}
    j.name = process.env.MOD_NAME;
    j.title = j.title ?? process.env.MOD_NAME;
    process.stdout.write(JSON.stringify(j, null, 2) + "\n");
  ' >"$TMP/$m.json" || { note "warning: bad mod.json for $m"; continue; }
  put "$TMP/$m.js" "$OUT/$m.js"
  put "$TMP/$m.json" "$OUT/$m.json"
  catalog="$catalog $m"
done

# _catalog.json from the per-mod json files, in MODS order.
OUT_DIR="$OUT" CATALOG="$catalog" BLOCKS="$BLOCKS" "$BUN" -e '
  const fs = require("fs"), path = require("path");
  const blocks = Object.fromEntries(process.env.BLOCKS.split(" ").filter(Boolean).map((p) => p.split("=")));
  const list = process.env.CATALOG.split(" ").filter(Boolean).map((m) => {
    const j = JSON.parse(fs.readFileSync(path.join(process.env.OUT_DIR, m + ".json"), "utf8"));
    return blocks[m] ? { name: m, title: j.title ?? m, block: blocks[m] } : { name: m, title: j.title ?? m };
  });
  process.stdout.write(JSON.stringify(list, null, 2) + "\n");
' >"$TMP/_catalog.json" && put "$TMP/_catalog.json" "$OUT/_catalog.json"

# _icons.json: every svg in ICON_DIRS and in the bundled mods' folders.
dirs=""
for d in $ICON_DIRS $MODS; do [ -d "$SRC/$d" ] && dirs="$dirs $d"; done
SRC_DIR="$SRC" DIRS="$dirs" "$BUN" -e '
  const fs = require("fs"), path = require("path");
  const out = {};
  for (const d of process.env.DIRS.split(" ").filter(Boolean)) {
    for (const f of fs.readdirSync(path.join(process.env.SRC_DIR, d)).sort()) {
      if (f.endsWith(".svg")) out[`mods/${d}/${f}`] = fs.readFileSync(path.join(process.env.SRC_DIR, d, f), "utf8").replace(/\s+/g, " ").trim();
    }
  }
  process.stdout.write(JSON.stringify(out, null, 1) + "\n");
' >"$TMP/_icons.json" && put "$TMP/_icons.json" "$OUT/_icons.json"

# _local.js: the builder's own host quirks (Config/host-local.js, gitignored).
if [ -f "$ROOT/Config/host-local.js" ]; then
  put "$ROOT/Config/host-local.js" "$OUT/_local.js"
elif [ -f "$OUT/_local.js" ]; then
  rm -f "$OUT/_local.js" && note "removed _local.js"
fi

exit 0
