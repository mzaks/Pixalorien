#!/bin/sh
# Build the distributable Pixalorien for Linux (x86-64): one
# self-contained executable in dist/, with the fonts, pictures and
# music inside it, raylib and OpenMP linked in, so that it needs the C
# library only (raylib's GLFW loads X11 and OpenGL, which come with the
# machine's graphics, when the window opens; on Wayland it runs through
# XWayland). All its C is compiled against the toolchain's old C
# library (glibc 2.28, its sysroot), so it runs on Linuxes from 2019 on
# (Debian 10, Ubuntu 20.04, RHEL 8), not only on one as new as this. A bare executable
# carries no icon on Linux, so besides it come
#
#   dist/Pixalorien-x86_64.AppImage   the same game as one file with
#                                     its icon and menu entry inside
#   dist/Pixalorien-linux-x86_64.tar.gz
#                                     the executable, the icon, a menu
#                                     entry and install.sh, which puts
#                                     all three under ~/.local
#
# Needs: ent-lang built next door (../ent-lang, as for developing; its
# LLVM is the one in build/toolchain, with the sysroot), cmake, make,
# git, curl, python3 and the X11 headers (to build raylib's GLFW). raylib and a static
# OpenMP runtime are built from source on the first run, appimagetool
# fetched once; later runs reuse all three.
#
#   tools/build_release_linux.sh          parallel build (all cores)
#   tools/build_release_linux.sh single   single-core build
#                                         (dist/Pixalorien-singlecore)
#
# $ENT_SRC says where ent-lang is (default: ../ent-lang), $LLVM_TAG
# the LLVM release to take OpenMP from (default: llvmorg-22.1.8, to
# match the toolchain's clang), $RAYLIB_TAG raylib's (default: 6.0);
# $LIBRAYLIB_A and $LIBOMP_A name ones already built, to use instead.
set -eu
cd "$(dirname "$0")/.."

ENT_SRC=${ENT_SRC:-../ent-lang}
LLVM_TAG=${LLVM_TAG:-llvmorg-22.1.8}
RAYLIB_TAG=${RAYLIB_TAG:-6.0}
LLVM=${LLVM_PREFIX:-$ENT_SRC/build/toolchain/.pixi/envs/default}
BUILD=build/release-linux
JOBS=$(nproc 2>/dev/null || echo 4)
mkdir -p "$BUILD" dist

# The compiler for the old C library: clang with the sysroot.
OLD_CC="$PWD/$LLVM/bin/x86_64-conda-linux-gnu-clang"
case "$LLVM" in /*) OLD_CC="$LLVM/bin/x86_64-conda-linux-gnu-clang" ;; esac
if [ ! -x "$OLD_CC" ]; then
  echo "error: no $OLD_CC (set LLVM_PREFIX)" >&2
  exit 1
fi
# The X11 headers alone, from the machine (its other headers are for
# its newer C library): GLFW needs X11's types, not its library.
mkdir -p "$BUILD/xheaders"
ln -sfn /usr/include/X11 "$BUILD/xheaders/X11"

# --- raylib, as a library to link in ------------------------------------
LIBRAYLIB_A=${LIBRAYLIB_A:-$PWD/$BUILD/libraylib.a}
if [ ! -f "$LIBRAYLIB_A" ]; then
  echo "building static raylib ($RAYLIB_TAG)..."
  if [ ! -d "$BUILD/raylib" ]; then
    git clone --depth 1 --branch "$RAYLIB_TAG" \
      https://github.com/raysan5/raylib "$BUILD/raylib"
  fi
  # (No images from the clipboard: raylib reads those through Xlib
  # itself, which would make the game need libX11 to start.)
  make -C "$BUILD/raylib/src" PLATFORM=PLATFORM_DESKTOP \
    RAYLIB_LIBTYPE=STATIC CC="$OLD_CC" \
    CUSTOM_CFLAGS="-DSUPPORT_CLIPBOARD_IMAGE=0 -idirafter $PWD/$BUILD/xheaders" \
    -j"$JOBS"
  cp "$BUILD/raylib/src/libraylib.a" "$LIBRAYLIB_A"
fi

# --- a static OpenMP runtime --------------------------------------------
# (Not for a single-core build, which has no OpenMP in it.)
# `ent build --parallel` links the toolchain's libomp.so, which other
# machines do not have; libomp.a linked instead (tools/static_cc.py).
LIBOMP_A=${LIBOMP_A:-$PWD/$BUILD/libomp.a}
if [ "${1:-parallel}" = parallel ] && [ ! -f "$LIBOMP_A" ]; then
  echo "building static libomp ($LLVM_TAG)..."
  if [ ! -d "$BUILD/llvm-src/openmp" ]; then
    git clone --depth 1 --branch "$LLVM_TAG" --filter=blob:none \
      --sparse https://github.com/llvm/llvm-project.git "$BUILD/llvm-src"
    git -C "$BUILD/llvm-src" sparse-checkout set openmp cmake
  fi
  cmake -S "$BUILD/llvm-src/openmp" -B "$BUILD/libomp-build" \
    -DCMAKE_BUILD_TYPE=Release -DLIBOMP_ENABLE_SHARED=OFF \
    -DLIBOMP_INSTALL_ALIASES=OFF -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_C_COMPILER="$OLD_CC" \
    -DCMAKE_CXX_COMPILER="$OLD_CC++"
  cmake --build "$BUILD/libomp-build" -j"$JOBS"
  cp "$BUILD/libomp-build/runtime/src/libomp.a" "$LIBOMP_A"
fi

# --- the game -------------------------------------------------------------
case "${1:-parallel}" in
  parallel) PARALLEL=--parallel; OUT=dist/Pixalorien ;;
  single)   PARALLEL="";        OUT=dist/Pixalorien-singlecore ;;
  *) echo "usage: tools/build_release_linux.sh [parallel|single]" >&2; exit 2 ;;
esac

echo "building $OUT..."
ENT_CACHE="$PWD/$BUILD/ent-cache" \
LIBOMP_A="$LIBOMP_A" LIBRAYLIB_A="$LIBRAYLIB_A" \
ENT_CC="$PWD/tools/static_cc.py" ENT_REAL_CC="$OLD_CC" \
RAYLIB_INCLUDE="${RAYLIB_INCLUDE:-$PWD/$BUILD/raylib/src}" ENT_PARALLEL_MIN=64 \
  "$ENT_SRC/tools/ent" build --embed $PARALLEL --no-cache \
  pixalorien.ent -o "$OUT"
strip "$OUT"

# Only what every Linux has: the C library (and the loader).
if ldd "$OUT" | grep -v 'linux-vdso\|ld-linux\|lib\(c\|m\|pthread\|dl\|rt\)\.so' \
    | grep -q '=>'; then
  echo "error: $OUT loads more than the C library:" >&2
  ldd "$OUT" >&2
  exit 1
fi

if [ "$OUT" = dist/Pixalorien ]; then
  # The menu entry: StartupWMClass is the window's class, which GLFW
  # takes from the window's title, so the running game gets the icon.
  DESKTOP="$BUILD/pixalorien.desktop"
  cat > "$DESKTOP" <<'ENTRY'
[Desktop Entry]
Type=Application
Name=Pixalorien
Comment=Three Pixaloriens bring a treasure back from deep under a desert planet
Exec=Pixalorien
Icon=pixalorien
Terminal=false
Categories=Game;StrategyGame;
StartupWMClass=Pixalorien
ENTRY

  # The AppImage: the executable, the icon and the entry in one file.
  APPIMAGETOOL="$BUILD/appimagetool"
  if [ ! -x "$APPIMAGETOOL" ]; then
    echo "fetching appimagetool..."
    curl -fsSL -o "$APPIMAGETOOL" \
      https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$APPIMAGETOOL"
  fi
  APPDIR="$BUILD/Pixalorien.AppDir"
  rm -rf "$APPDIR"
  mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" \
    "$APPDIR/usr/share/icons/hicolor/256x256/apps"
  cp dist/Pixalorien "$APPDIR/usr/bin/Pixalorien"
  cp "$DESKTOP" "$APPDIR/pixalorien.desktop"
  cp "$DESKTOP" "$APPDIR/usr/share/applications/"
  cp art/app-icon-mac.png "$APPDIR/pixalorien.png"
  cp art/app-icon-mac.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/pixalorien.png"
  cat > "$APPDIR/AppRun" <<'RUN'
#!/bin/sh
# In the home folder, as the Mac's app: started from a file manager
# it would be wherever the AppImage is, where its saved worlds (written
# where it runs) may not be wanted or allowed.
here=$(dirname "$(readlink -f "$0")")
cd "$HOME"
exec "$here/usr/bin/Pixalorien" "$@"
RUN
  chmod +x "$APPDIR/AppRun"
  rm -f dist/Pixalorien-x86_64.AppImage
  ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" --no-appstream \
    "$APPDIR" dist/Pixalorien-x86_64.AppImage >/dev/null

  # The archive: the executable, icon, entry, licences and install.sh.
  PACK="$BUILD/Pixalorien"
  rm -rf "$PACK"
  mkdir -p "$PACK"
  cp dist/Pixalorien LICENSE ASSETS-LICENSE.md "$PACK/"
  cp art/app-icon-mac.png "$PACK/pixalorien.png"
  cp "$DESKTOP" "$PACK/pixalorien.desktop"
  cat > "$PACK/install.sh" <<'INSTALL'
#!/bin/sh
# Puts Pixalorien in the menu, with its icon: the game in ~/.local/bin,
# the icon and the menu entry under ~/.local/share. To take it out
# again: ./install.sh remove
set -eu
here=$(cd "$(dirname "$0")" && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}
bin=$HOME/.local/bin
icon=$data/icons/hicolor/256x256/apps/pixalorien.png
entry=$data/applications/pixalorien.desktop
if [ "${1:-}" = remove ]; then
  rm -f "$bin/Pixalorien" "$icon" "$entry"
  echo "Pixalorien removed."
  exit 0
fi
mkdir -p "$bin" "$(dirname "$icon")" "$(dirname "$entry")"
cp "$here/Pixalorien" "$bin/Pixalorien"
cp "$here/pixalorien.png" "$icon"
sed "s|^Exec=.*|Exec=$bin/Pixalorien|" "$here/pixalorien.desktop" > "$entry"
command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$data/applications" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 &&
  gtk-update-icon-cache -q "$data/icons/hicolor" 2>/dev/null || true
echo "Pixalorien installed: in the menu, or $bin/Pixalorien"
INSTALL
  chmod +x "$PACK/install.sh"
  rm -f dist/Pixalorien-linux-x86_64.tar.gz
  tar -C "$BUILD" -czf dist/Pixalorien-linux-x86_64.tar.gz Pixalorien
  echo "done: dist/Pixalorien, dist/Pixalorien-x86_64.AppImage," \
    "dist/Pixalorien-linux-x86_64.tar.gz"
else
  echo "done: $OUT"
fi
ldd "$OUT"
# The newest C library it asks for: older Linuxes than that cannot run it.
objdump -T "$OUT" | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -n 1 |
  sed 's/^/needs at least /'
ls -lh dist/
