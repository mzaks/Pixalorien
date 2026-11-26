#!/bin/sh
# Build the distributable Pixalorien: one self-contained executable
# for macOS (Apple Silicon) in dist/, with the fonts, pictures and
# music inside it and no Homebrew libraries to install. Also makes
# dist/Pixalorien.app with the game icon (a bare executable cannot
# carry a Finder icon) and zips both forms with the licences.
#
# Needs: Homebrew LLVM 22 and raylib (as for developing: its headers),
# cmake, git, python3. The ent-lang compiler next door (../ent-lang) is
# built into build/ on the first run, and with it a static OpenMP
# runtime and raylib, for MACOSX_DEPLOYMENT_TARGET (their source is
# fetched once; Homebrew's are for the macOS they were built on, and a
# game linked with them asks for that one); later runs reuse all three,
# while they are for the same macOS.
#
#   tools/build_release.sh          parallel build (all cores)
#   tools/build_release.sh single   single-core build, for comparing
#                                   (dist/Pixalorien-singlecore)
#   tools/build_release.sh traced   single-core, timed per system
#                                   (dist/Pixalorien-traced; run it
#                                   via dist/run-traced.command)
#
# Signed and notarised for Gatekeeper where these are set (else signed
# for this Mac only, as before):
#   DEVELOPER_ID    the signing identity, "Developer ID Application:
#                   Name (TEAMID)" (security find-identity -v -p
#                   codesigning): both forms signed with it, with the
#                   hardened runtime and a secure timestamp;
#   NOTARY_PROFILE  a notarytool keychain profile (xcrun notarytool
#                   store-credentials NAME --apple-id .. --team-id ..):
#                   both zips sent to Apple's notary service and waited
#                   for, the app stapled (a bare executable cannot be:
#                   Gatekeeper asks Apple for its ticket when it opens);
#   APP_VERSION     the app's version (default 1.0).
#
# $ENT_SRC says where ent-lang is (default: ../ent-lang), $LLVM_TAG
# the LLVM release to take OpenMP from (default: llvmorg-22.1.8, to
# match Homebrew's LLVM 22).
set -eu
# Run on every Apple Silicon Mac, not only this one's macOS.
export MACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET:-11.0}
cd "$(dirname "$0")/.."

ENT_SRC=${ENT_SRC:-../ent-lang}
. tools/ent_version.sh
LLVM_TAG=${LLVM_TAG:-llvmorg-22.1.8}
RAYLIB_TAG=${RAYLIB_TAG:-6.0}
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

# The newest macOS any object of a static library was built for (its
# LC_BUILD_VERSION's minos).
lib_macos() {
  otool -l "$1" | awk '$1 == "minos" { print $2 }' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1
}
# Whether a library is there and for no newer macOS than the game.
lib_ok() {
  [ -f "$1" ] && [ "$(printf '%s\n%s\n' "$(lib_macos "$1")" "$MACOSX_DEPLOYMENT_TARGET" \
    | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$MACOSX_DEPLOYMENT_TARGET" ]
}

# --- a static OpenMP runtime ------------------------------------------
# `ent build --parallel` links Homebrew's libomp.dylib, which other
# Macs do not have; libomp.a linked instead (tools/static_cc.py)
# makes the game depend on system libraries only.
LIBOMP_A="$PWD/$BUILD/libomp.a"
if ! lib_ok "$LIBOMP_A"; then
  rm -rf "$BUILD/libomp-build"
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
    -DCMAKE_CXX_COMPILER="$LLVM/bin/clang++" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET"
  cmake --build "$BUILD/libomp-build" -j
  cp "$BUILD/libomp-build/runtime/src/libomp.a" "$LIBOMP_A"
fi

# --- raylib, as a library to link in ------------------------------------
# (Its own GLFW inside, not Homebrew's.)
LIBRAYLIB_A=${LIBRAYLIB_A:-$PWD/$BUILD/libraylib.a}
if ! lib_ok "$LIBRAYLIB_A"; then
  echo "building static raylib ($RAYLIB_TAG) for macOS $MACOSX_DEPLOYMENT_TARGET..."
  if [ ! -d "$BUILD/raylib" ]; then
    git clone --depth 1 --branch "$RAYLIB_TAG" \
      https://github.com/raysan5/raylib "$BUILD/raylib"
  fi
  rm -rf "$BUILD/raylib-build"
  cmake -S "$BUILD/raylib" -B "$BUILD/raylib-build" \
    -DCMAKE_BUILD_TYPE=Release -DPLATFORM=Desktop -DBUILD_EXAMPLES=OFF \
    -DBUILD_SHARED_LIBS=OFF -DUSE_EXTERNAL_GLFW=OFF \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET"
  cmake --build "$BUILD/raylib-build" -j
  cp "$BUILD/raylib-build/raylib/libraylib.a" "$LIBRAYLIB_A"
fi
for lib in "$LIBOMP_A" "$LIBRAYLIB_A"; do
  if ! lib_ok "$lib"; then
    echo "error: $lib is for macOS $(lib_macos "$lib"), the game for $MACOSX_DEPLOYMENT_TARGET" >&2
    exit 1
  fi
done

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
ENT_BIN="$ENT_BIN_DIR" ENT_CACHE="$PWD/$BUILD/ent-cache" \
LIBOMP_A="$LIBOMP_A" LIBRAYLIB_A="$LIBRAYLIB_A" \
ENT_CC="$PWD/tools/static_cc.py" ENT_PARALLEL_MIN=64 \
  "$ENT_SRC/tools/ent" build --embed $PARALLEL $TRACE --no-cache \
  pixalorien.ent -o "$OUT"

# Signed: for Gatekeeper by a Developer ID (the hardened runtime, which
# the game needs no exceptions from: no JIT, no libraries of others'),
# else ad hoc, for this Mac.
sign() {
  if [ -n "${DEVELOPER_ID:-}" ]; then
    codesign --force --options runtime --timestamp -s "$DEVELOPER_ID" "$@"
  else
    codesign --force -s - "$@"
  fi
}
if [ -n "${NOTARY_PROFILE:-}" ] && [ -z "${DEVELOPER_ID:-}" ]; then
  echo "error: NOTARY_PROFILE without DEVELOPER_ID: Apple notarises only what a Developer ID signed" >&2
  exit 1
fi
sign "$OUT"

if otool -L "$OUT" | grep -q homebrew; then
  echo "error: $OUT still depends on Homebrew libraries:" >&2
  otool -L "$OUT" | grep homebrew >&2
  exit 1
fi

if [ "$OUT" = dist/Pixalorien ]; then
  # The app: the same executable, with the icon (art/app-icon-mac.png,
  # made from art/app-icon.png by art/mac_icon.py: on Apple's grid, a
  # squircle with a shadow) in the form Finder shows. Its launcher steps into the home folder
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
    sips -z "$1" "$1" art/app-icon-mac.png --out "$ICONSET/$2" >/dev/null
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
  <key>CFBundleShortVersionString</key><string>APP_VERSION</string>
  <key>CFBundleVersion</key><string>APP_VERSION</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
  sed -i '' "s/APP_VERSION/${APP_VERSION:-1.0}/g" "$APP/Contents/Info.plist"
  # (The code inside first, the bundle last: no --deep.)
  sign "$APP/Contents/MacOS/Pixalorien-real"
  sign "$APP/Contents/MacOS/Pixalorien"
  sign "$APP"
  codesign --verify --strict "$APP"
  cp LICENSE ASSETS-LICENSE.md dist/
  zips() {
    rm -f dist/Pixalorien-macos-arm64.zip dist/Pixalorien-macos-arm64-app.zip
    (cd dist && zip -q -X Pixalorien-macos-arm64.zip Pixalorien LICENSE ASSETS-LICENSE.md)
    (cd dist && ditto -c -k --keepParent Pixalorien.app app.zip && zip -q -X app.zip LICENSE ASSETS-LICENSE.md \
      && mv app.zip Pixalorien-macos-arm64-app.zip)
  }
  zips
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    for z in Pixalorien-macos-arm64.zip Pixalorien-macos-arm64-app.zip; do
      echo "notarising $z (minutes)..."
      xcrun notarytool submit "dist/$z" --keychain-profile "$NOTARY_PROFILE" --wait \
        --output-format json > "$BUILD/notary.json"
      if ! grep -q '"status" *: *"Accepted"' "$BUILD/notary.json"; then
        echo "error: $z not notarised:" >&2
        cat "$BUILD/notary.json" >&2
        id=$(sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p' "$BUILD/notary.json")
        [ -n "$id" ] && xcrun notarytool log "$id" --keychain-profile "$NOTARY_PROFILE" >&2
        exit 1
      fi
    done
    # The ticket in the app, so it opens offline too; zipped again with it.
    xcrun stapler staple "$APP"
    zips
    spctl -a -t exec -vv "$APP"
  fi
  rm dist/LICENSE dist/ASSETS-LICENSE.md
  echo "done: dist/Pixalorien, dist/Pixalorien.app (and both zips)"
else
  echo "done: $OUT"
fi
otool -L "$OUT" | head -n 4
ls -lh dist/
