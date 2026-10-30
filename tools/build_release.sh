#!/bin/sh
# Build the distributable Pixalorien: one self-contained executable
# for macOS (Apple Silicon) in dist/, with the fonts, pictures and
# music inside it and no Homebrew libraries to install. Also makes
# dist/Pixalorien.app with the game icon (a bare executable cannot
# carry a Finder icon) and zips both forms with the licences.
#
# Needs: Homebrew LLVM 22 and raylib (as for developing), cmake, git,
# python3. The ent-lang compiler next door (../ent-lang) is built
# into build/ on the first run, and a static OpenMP runtime with it
# (its source is fetched once); later runs reuse both.
#
#   tools/build_release.sh          parallel build (all cores)
#   tools/build_release.sh single   single-core build, for comparing
#                                   (dist/Pixalorien-singlecore)
#   tools/build_release.sh traced   single-core, timed per system
#                                   (dist/Pixalorien-traced; run it
#                                   via dist/run-traced.command)
#
# $ENT_SRC says where ent-lang is (default: ../ent-lang), $LLVM_TAG
# the LLVM release to take OpenMP from (default: llvmorg-22.1.8, to
# match Homebrew's LLVM 22).
set -eu
# Run on every Apple Silicon Mac, not only this one's macOS.
export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-11.0}
cd "$(dirname "$0")/.."

ENT_SRC=${ENT_SRC:-../ent-lang}
LLVM_TAG=${LLVM_TAG:-llvmorg-22.1.8}
LLVM=/opt/homebrew/opt/llvm
BUILD=build/release
mkdir -p "$BUILD" dist

# --- the ent-lang compiler -------------------------------------------
ENT_BIN_DIR=""
for dir in "${ENT_BIN:-}" "$ENT_SRC/build/bin" "$BUILD/ent/bin"; do
  if [ -n "$dir" ] && [ -x "$dir/ent-opt" ]; then ENT_BIN_DIR=$dir; break; fi
done
if [ -z "$ENT_BIN_DIR" ]; then
  echo "building the ent-lang compiler..."
  if ! command -v lit >/dev/null 2>&1 && [ ! -x "$BUILD/venv/bin/lit" ]; then
    python3 -m venv "$BUILD/venv"
    "$BUILD/venv/bin/pip" install -q lit
  fi
  cmake -S "$ENT_SRC" -B "$BUILD/ent-build" \
    -DMLIR_DIR="$LLVM/lib/cmake/mlir" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DENT_LIT="$(command -v lit || echo "$PWD/$BUILD/venv/bin/lit")"
  cmake --build "$BUILD/ent-build" -j
  ENT_BIN_DIR="$BUILD/ent-build/bin"
fi

# --- a static OpenMP runtime ------------------------------------------
# `ent build --parallel` links Homebrew's libomp.dylib, which other
# Macs do not have; libomp.a linked instead (tools/static_cc.py)
# makes the game depend on system libraries only.
LIBOMP_A="$PWD/$BUILD/libomp.a"
if [ ! -f "$LIBOMP_A" ]; then
  echo "building static libomp ($LLVM_TAG)..."
  if [ ! -d "$BUILD/llvm-src/openmp" ]; then
    git clone --depth 1 --branch "$LLVM_TAG" --filter=blob:none \
      --sparse https://github.com/llvm/llvm-project.git "$BUILD/llvm-src"
    git -C "$BUILD/llvm-src" sparse-checkout set openmp cmake
  fi
  cmake -S "$BUILD/llvm-src/openmp" -B "$BUILD/libomp-build" \
    -DCMAKE_BUILD_TYPE=Release -DLIBOMP_ENABLE_SHARED=OFF \
    -DLIBOMP_INSTALL_ALIASES=OFF -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
    -DCMAKE_C_COMPILER="$LLVM/bin/clang" \
    -DCMAKE_CXX_COMPILER="$LLVM/bin/clang++"
  cmake --build "$BUILD/libomp-build" -j
  cp "$BUILD/libomp-build/runtime/src/libomp.a" "$LIBOMP_A"
fi

# --- the game -----------------------------------------------------------
# No --parallel, no OpenMP at all with `single`: the one core does
# everything, which can beat many cores when the stretched-out work
# between the parallel loops is short (drawing, orders).
case "${1:-parallel}" in
  parallel) PARALLEL=--parallel; TRACE="";        OUT=dist/Pixalorien ;;
  single)   PARALLEL="";        TRACE="";        OUT=dist/Pixalorien-singlecore ;;
  traced)   PARALLEL="";        TRACE="--trace"; OUT=dist/Pixalorien-traced ;;
  *) echo "usage: tools/build_release.sh [parallel|single|traced]" >&2; exit 2 ;;
esac

echo "building $OUT..."
LIBRAYLIB_A=${LIBRAYLIB_A:-/opt/homebrew/lib/libraylib.a}
ENT_BIN="$ENT_BIN_DIR" ENT_CACHE="$PWD/$BUILD/ent-cache" \
LIBOMP_A="$LIBOMP_A" LIBRAYLIB_A="$LIBRAYLIB_A" \
ENT_CC="$PWD/tools/static_cc.py" ENT_PARALLEL_MIN=64 \
  "$ENT_SRC/tools/ent" build --embed $PARALLEL $TRACE --no-cache \
  pixalorien.ent -o "$OUT"

codesign --force -s - "$OUT"

if otool -L "$OUT" | grep -q homebrew; then
  echo "error: $OUT still depends on Homebrew libraries:" >&2
  otool -L "$OUT" | grep homebrew >&2
  exit 1
fi

if [ "$OUT" = dist/Pixalorien ]; then
  # The app: the same executable, with the icon (art/app-icon.png) in
  # the form Finder shows. Its launcher steps into the home folder
  # first, as a double-clicked program starts at the root, where its
  # saved worlds could not be written.
  APP=dist/Pixalorien.app
  ICONSET="$BUILD/Pixalorien.iconset"
  rm -rf "$APP" "$ICONSET"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ICONSET"
  cp dist/Pixalorien "$APP/Contents/MacOS/Pixalorien-real"
  cc -O2 tools/app_launcher.c -o "$APP/Contents/MacOS/Pixalorien"
  chmod +x "$APP/Contents/MacOS/Pixalorien" "$APP/Contents/MacOS/Pixalorien-real"
  for spec in "16 icon_16x16.png" "32 icon_16x16@2x.png" \
              "32 icon_32x32.png" "64 icon_32x32@2x.png" \
              "128 icon_128x128.png" "256 icon_128x128@2x.png" \
              "256 icon_256x256.png" "512 icon_256x256@2x.png" \
              "512 icon_512x512.png" "1024 icon_512x512@2x.png"; do
    set -- $spec
    sips -z "$1" "$1" art/app-icon.png --out "$ICONSET/$2" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Pixalorien.icns"
  cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key><string>Pixalorien</string>
  <key>CFBundleExecutable</key><string>Pixalorien</string>
  <key>CFBundleIdentifier</key><string>org.pixalorien.game</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleIconFile</key><string>Pixalorien</string>
  <key>CFBundleName</key><string>Pixalorien</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
  codesign --force --deep -s - "$APP"
  cp LICENSE ASSETS-LICENSE.md dist/
  rm -f dist/Pixalorien-macos-arm64.zip dist/Pixalorien-macos-arm64-app.zip
  (cd dist && zip -q -X Pixalorien-macos-arm64.zip Pixalorien LICENSE ASSETS-LICENSE.md)
  (cd dist && zip -qr -X Pixalorien-macos-arm64-app.zip Pixalorien.app LICENSE ASSETS-LICENSE.md)
  rm dist/LICENSE dist/ASSETS-LICENSE.md
  echo "done: dist/Pixalorien, dist/Pixalorien.app (and both zips)"
else
  echo "done: $OUT"
fi
otool -L "$OUT" | head -n 4
ls -lh dist/
