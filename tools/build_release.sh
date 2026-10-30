#!/bin/sh
# Build the distributable Pixalorien: one self-contained executable
# for macOS (Apple Silicon) in dist/, with the fonts, pictures and
# music inside it and no Homebrew libraries to install. Also zips it
# with the licences as dist/Pixalorien-macos-arm64.zip.
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
  cp LICENSE ASSETS-LICENSE.md dist/
  (cd dist && zip -q -X Pixalorien-macos-arm64.zip Pixalorien LICENSE ASSETS-LICENSE.md)
  rm dist/LICENSE dist/ASSETS-LICENSE.md
  echo "done: dist/Pixalorien (and dist/Pixalorien-macos-arm64.zip)"
else
  echo "done: $OUT"
fi
otool -L "$OUT" | head -n 4
ls -lh dist/
