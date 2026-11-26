#!/bin/sh
# Build the web page (docs/play/: the game as WebAssembly, played at
# https://mzaks.github.io/Pixalorien/play/) with its loading screen
# (tools/web_page.py).
#
# Needs ent-lang at the tag in ENT_VERSION ($ENT_SRC, default
# ../ent-lang) with Emscripten and raylib for the web in its build/, and
# its compiler: $ENT_BIN, else $ENT_SRC/build/bin or build/release/ent/bin
# (as tools/build_release.sh builds it). On a Mac, ent-lang v0.1.2's
# driver gives the web linker macOS's -U flags (fixed after it, ent-lang
# b67a75f): where it still does, the page is built by the driver with
# that one line changed, run as if it were ent-lang's own (it finds
# ent-lang's devices and the page's font from where it thinks it is);
# ent-lang is not touched.
set -eu
cd "$(dirname "$0")/.."

ENT_SRC=${ENT_SRC:-../ent-lang}
. tools/ent_version.sh
ENT_SRC=$(cd "$ENT_SRC" && pwd)
if [ "$(uname)" = Darwin ]; then
  export LLVM_PREFIX=${LLVM_PREFIX:-/opt/homebrew/opt/llvm}
fi

ENT_BIN_DIR=""
for dir in "${ENT_BIN:-}" "$ENT_SRC/build/bin" "build/release/ent/bin"; do
  if [ -n "$dir" ] && [ -x "$dir/ent-opt" ]; then ENT_BIN_DIR=$(cd "$dir" && pwd); break; fi
done
if [ -z "$ENT_BIN_DIR" ]; then
  echo "error: no ent-lang compiler (ENT_BIN=..., or tools/build_release.sh builds one)" >&2
  exit 1
fi

ENT="$ENT_SRC/tools/ent"
if [ "$(uname)" = Darwin ] && ! grep -q 'and not arguments.windows and not arguments.web:' "$ENT"; then
  T="$PWD/build/web-ent"
  rm -rf "$T" && mkdir -p "$T"
  sed 's/    if sys.platform == "darwin" and not arguments.windows:$/    if sys.platform == "darwin" and not arguments.windows and not arguments.web:/' \
    "$ENT" > "$T/ent.py"
  grep -q 'and not arguments.web:' "$T/ent.py" || { echo "error: could not fix $ENT for --web" >&2; exit 1; }
  cat > "$T/ent" <<RUN
#!/usr/bin/env python3
import sys
sys.argv[0] = "$ENT"
code = compile(open("$T/ent.py").read(), "$ENT", "exec")
exec(code, {"__name__": "__main__", "__file__": "$ENT"})
RUN
  chmod +x "$T/ent"
  ENT="$T/ent"
fi

OUT=build/web
rm -rf "$OUT" && mkdir -p "$OUT"
echo "building the web page..."
ENT_BIN="$ENT_BIN_DIR" "$ENT" build --web pixalorien.ent -o "$OUT/index.html"
python3 tools/web_page.py "$OUT/index.html"

mkdir -p docs/play/loading
cp "$OUT"/index.html "$OUT"/index.js "$OUT"/index.wasm "$OUT"/index.data docs/play/
cp docs/fonts/Jersey10-Regular.ttf docs/fonts/Jersey10-OFL.txt docs/play/loading/
sips -Z 192 docs/img/icon.png --out docs/play/loading/icon.png >/dev/null
echo "done: docs/play/"
ls -lh docs/play docs/play/loading
