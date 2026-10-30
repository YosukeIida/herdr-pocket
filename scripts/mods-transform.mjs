// Turns one bun ESM bundle into a script JavaScriptCore can evaluate:
//   (function(__require, __exports){ ...body... })
//
// Only the bundle's own top-level module syntax is rewritten. bun hoists every
// remaining `import` of an external module to the head of the file and emits a
// single `export { ... };` at the very end, so the rewrite looks at exactly
// those two places and never at the body (a mod may embed Python source whose
// lines start with `import`).
//
// usage: bun mods-transform.mjs <in.esm.js> <out.js>
import fs from "fs";

const [, , input, output] = process.argv;
if (!input || !output) {
  console.error("usage: mods-transform.mjs <in.esm.js> <out.js>");
  process.exit(2);
}
const src = fs.readFileSync(input, "utf8");
const lines = src.split("\n");

// 1. The head: blank lines, comments and import statements (possibly multi-line).
const head = [];
let i = 0;
let pending = null;
for (; i < lines.length; i++) {
  const line = lines[i];
  if (pending !== null) {
    pending += "\n" + line;
    if (/;\s*$/.test(line) || /from\s*["'][^"']+["']\s*;?\s*$/.test(line)) {
      head.push(rewriteImport(pending));
      pending = null;
    }
    continue;
  }
  const trimmed = line.trim();
  if (trimmed === "" || trimmed.startsWith("//")) {
    head.push(line);
    continue;
  }
  if (/^import[\s{*"']/.test(trimmed)) {
    if (/from\s*["'][^"']+["']\s*;?\s*$/.test(trimmed) || /^import\s*["'][^"']+["']\s*;?$/.test(trimmed)) {
      head.push(rewriteImport(trimmed));
    } else {
      pending = trimmed;
    }
    continue;
  }
  break;
}
if (pending !== null) throw new Error("unterminated import at the head of " + input);

// 2. The tail: the last non-blank line(s) must be the export statement.
let end = lines.length;
while (end > i && lines[end - 1].trim() === "") end--;
let exportStart = end;
let tail = [];
// The export block may span several lines: `export {\n  a,\n  b as default\n};`
for (let j = end - 1; j >= i; j--) {
  if (/^export\s*\{/.test(lines[j].trim())) {
    exportStart = j;
    break;
  }
  if (end - j > 50) break;
}
if (exportStart < end) {
  const stmt = lines.slice(exportStart, end).join("\n");
  const m = stmt.match(/^export\s*\{([\s\S]*?)\}\s*;?\s*$/);
  if (!m) throw new Error("unrecognised export statement at the end of " + input);
  tail = m[1].split(",").map((s) => s.trim()).filter(Boolean).map((s) => {
    const [local, exported] = s.split(/\s+as\s+/);
    return `__exports[${JSON.stringify(exported ?? local)}] = ${local};`;
  });
} else {
  exportStart = end;
}

// bun does not always hoist every external import to the head (e.g. when a
// sub-module's code is emitted before its imports). ESM imports are hoisted
// semantically, so move any column-0 import of an EXTERNAL module found in the
// body up to the head. Only `import ... from "<external>";` at column 0 is
// touched, never other text (a mod may embed Python `import x` lines in strings).
const EXTERNALS = ["herdr", "gpui-kit", "gpui-base"];
const extFrom = new RegExp(`from\\s*["'](${EXTERNALS.join("|")})["']\\s*;?\\s*$`);
const body = [];
for (let j = i; j < exportStart; j++) {
  const line = lines[j];
  if (/^import\s*[{*\w]/.test(line)) {
    let stmt = line;
    let k = j;
    while (!extFrom.test(stmt) && k + 1 < exportStart && k - j < 20 && !/;\s*$/.test(lines[k])) {
      k++;
      stmt += "\n" + lines[k];
    }
    if (extFrom.test(stmt)) {
      head.push(rewriteImport(stmt));
      j = k;
      continue;
    }
  }
  body.push(line);
}
// Guard: nothing in the body may still be ESM syntax at column 0 outside strings.
// (A cheap check: an `export` keyword at column 0 would be a bundler surprise.)
if (body.some((l) => /^export\s/.test(l))) throw new Error("unexpected export inside the body of " + input);

const out = `(function(__require, __exports){\n"use strict";\n${head.join("\n")}\n${body.join("\n")}\n${tail.join("\n")}\n})`;
fs.writeFileSync(output, out);

function rewriteImport(stmt) {
  const flat = stmt.replace(/\s+/g, " ").trim();
  let m = flat.match(/^import\s*\{([^}]*)\}\s*from\s*["']([^"']+)["'];?$/);
  if (m) {
    const names = m[1].split(",").map((s) => s.trim()).filter(Boolean)
      .map((s) => s.replace(/\s+as\s+/, ": ")).join(", ");
    return `const {${names}} = __require(${JSON.stringify(m[2])});`;
  }
  m = flat.match(/^import\s*\*\s*as\s+(\w+)\s+from\s*["']([^"']+)["'];?$/);
  if (m) return `const ${m[1]} = __require(${JSON.stringify(m[2])});`;
  m = flat.match(/^import\s+(\w+)\s*(?:,\s*\{([^}]*)\})?\s*from\s*["']([^"']+)["'];?$/);
  if (m) {
    const out = [`const ${m[1]} = __require(${JSON.stringify(m[3])}).default;`];
    if (m[2]) {
      const names = m[2].split(",").map((s) => s.trim()).filter(Boolean).map((s) => s.replace(/\s+as\s+/, ": ")).join(", ");
      out.push(`const {${names}} = __require(${JSON.stringify(m[3])});`);
    }
    return out.join(" ");
  }
  m = flat.match(/^import\s*["']([^"']+)["'];?$/);
  if (m) return `__require(${JSON.stringify(m[1])});`;
  throw new Error("unsupported import: " + flat);
}
