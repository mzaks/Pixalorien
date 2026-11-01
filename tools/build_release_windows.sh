#!/bin/sh
# Build the distributable Pixalorien for Windows (x86-64, Windows 10
# and later) on Linux: dist/Pixalorien-windows-x86_64.zip, a folder
# with Pixalorien.exe (the fonts, pictures and music inside it, raylib
# linked in, the app icon on it), libomp.dll (the OpenMP runtime its
# threads run on) and the licences. Unzipped anywhere, the .exe runs
# from there; it writes its saved worlds where it runs.
#
# Needs: ent-lang built next door (../ent-lang), llvm-mingw
# (https://github.com/mstorsjo/llvm-mingw, its ucrt build for Linux,
# unpacked at $LLVM_MINGW, default ~/.local/opt/llvm-mingw), cmake,
# make, git, magick (for the icon) and zip. raylib is built from source
# on the first run and reused later. Wine, if there, tries the .exe.
#
#   tools/build_release_windows.sh          parallel build (all cores)
#   tools/build_release_windows.sh single   single-core build
#                                           (Pixalorien-singlecore.exe)
#
# $ENT_SRC says where ent-lang is (default: ../ent-lang), $RAYLIB_TAG
# raylib's release (default: 6.0); $LIBRAYLIB_A names one already
# built, to use instead.
set -eu
cd "$(dirname "$0")/.."

ENT_SRC=${ENT_SRC:-../ent-lang}
RAYLIB_TAG=${RAYLIB_TAG:-6.0}
LLVM_MINGW=${LLVM_MINGW:-$HOME/.local/opt/llvm-mingw}
BUILD=build/release-windows
JOBS=$(nproc 2>/dev/null || echo 4)
mkdir -p "$BUILD" dist

CC="$LLVM_MINGW/bin/x86_64-w64-mingw32-clang"
if [ ! -x "$CC" ]; then
  echo "error: no $CC (set LLVM_MINGW)" >&2
  exit 1
fi
PATH="$LLVM_MINGW/bin:$PATH"
export PATH

# --- raylib, as a library to link in ------------------------------------
LIBRAYLIB_A=${LIBRAYLIB_A:-$PWD/$BUILD/libraylib.a}
if [ ! -f "$LIBRAYLIB_A" ]; then
  echo "building static raylib ($RAYLIB_TAG) for Windows..."
  if [ ! -d "$BUILD/raylib" ]; then
    git clone --depth 1 --branch "$RAYLIB_TAG" \
      https://github.com/raysan5/raylib "$BUILD/raylib"
  fi
  cmake -S "$BUILD/raylib" -B "$BUILD/raylib-build" \
    -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="$CC" -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
    -DPLATFORM=Desktop -DBUILD_EXAMPLES=OFF -DBUILD_SHARED_LIBS=OFF
  cmake --build "$BUILD/raylib-build" -j"$JOBS"
  cp "$BUILD/raylib-build/raylib/libraylib.a" "$LIBRAYLIB_A"
fi

# --- OpenMP: llvm-mingw's, a DLL that goes next to the .exe ----------------
LIBOMP_A="$LLVM_MINGW/x86_64-w64-mingw32/lib/libomp.dll.a"
LIBOMP_DLL="$LLVM_MINGW/x86_64-w64-mingw32/bin/libomp.dll"

# --- the icon, as an object linked into the .exe ---------------------------
ICON="$BUILD/icon.o"
if [ ! -f "$ICON" ] || [ art/app-icon-mac.png -nt "$ICON" ]; then
  magick art/app-icon-mac.png -define icon:auto-resize=256,128,64,48,32,16 \
    "$BUILD/pixalorien.ico"
  printf '1 ICON "pixalorien.ico"\n' > "$BUILD/icon.rc"
  (cd "$BUILD" && x86_64-w64-mingw32-windres icon.rc -O coff -o icon.o)
fi

# --- the game -------------------------------------------------------------
case "${1:-parallel}" in
  parallel) PARALLEL=--parallel; NAME=Pixalorien ;;
  single)   PARALLEL="";        NAME=Pixalorien-singlecore ;;
  *) echo "usage: tools/build_release_windows.sh [parallel|single]" >&2; exit 2 ;;
esac
PACK=dist/Pixalorien-windows
mkdir -p "$PACK"
OUT="$PACK/$NAME.exe"

echo "building $OUT..."
ENT_CACHE="$PWD/$BUILD/ent-cache" \
LIBOMP_A="$LIBOMP_A" LIBRAYLIB_A="$LIBRAYLIB_A" WINDOWS_ICON="$PWD/$ICON" \
ENT_CC="$PWD/tools/static_cc.py" ENT_REAL_CC="$CC" \
RAYLIB_INCLUDE="${RAYLIB_INCLUDE:-$PWD/$BUILD/raylib/src}" ENT_PARALLEL_MIN=64 \
  "$ENT_SRC/tools/ent" build --windows --embed $PARALLEL --no-cache \
  pixalorien.ent -o "$OUT"
llvm-strip "$OUT"
if [ -n "$PARALLEL" ]; then
  cp "$LIBOMP_DLL" "$PACK/"
fi

# Only what every Windows from 10 on has (and libomp.dll, next to it).
if llvm-objdump -p "$OUT" | sed -n 's/.*DLL Name: //p' | grep -v -i -x \
    'kernel32.dll\|user32.dll\|gdi32.dll\|shell32.dll\|winmm.dll\|opengl32.dll\|advapi32.dll\|ole32.dll\|api-ms-win-crt-.*\.dll\|libomp.dll'; then
  echo "error: $OUT loads more than the system's DLLs (those above)" >&2
  exit 1
fi

cp LICENSE ASSETS-LICENSE.md "$PACK/"
rm -f dist/Pixalorien-windows-x86_64.zip
(cd dist && zip -qr -X Pixalorien-windows-x86_64.zip Pixalorien-windows)
echo "done: $OUT, dist/Pixalorien-windows-x86_64.zip"
