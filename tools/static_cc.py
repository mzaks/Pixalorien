#!/usr/bin/env python3
"""The host compiler, with the link made self-contained (macOS, Linux).

Used by tools/build_release.sh and tools/build_release_linux.sh as
ENT_CC. Compile steps (-c) pass
through to the real `cc`. The link step is rewritten:

  - `-lraylib` becomes the static libraylib.a ($LIBRAYLIB_A, else
    Homebrew's) plus the system libraries raylib needs (frameworks on
    a Mac);
  - the libomp.dylib (libomp.so) that `ent build --parallel` links,
    with an rpath into Homebrew (the LLVM toolchain), becomes the
    static libomp.a in $LIBOMP_A.

The result depends only on system libraries, so it runs on a Mac
without Homebrew, and on Linux on the C library alone (raylib's
GLFW loads X11 and OpenGL when the window opens). (The game's files are in the binary itself:
`asset` in pixalorien.ent, `ent build --embed`.)
"""
import os
import subprocess
import sys

# (On Linux the release build names a compiler for an old C library:
# $ENT_REAL_CC, with raylib's headers in $RAYLIB_INCLUDE.)
REAL_CC = os.environ.get("ENT_REAL_CC", "/usr/bin/cc")
RAYLIB_INCLUDE = os.environ.get("RAYLIB_INCLUDE", "")
LIBOMP_A = os.environ.get("LIBOMP_A", "")
LIBRAYLIB_A = os.environ.get(
    "LIBRAYLIB_A", "/opt/homebrew/lib/libraylib.a")
LINUX = sys.platform.startswith("linux")
SYSTEM = ["-lpthread", "-ldl", "-lrt", "-lm"] if LINUX else [
    "-framework", "Cocoa",
    "-framework", "IOKit",
    "-framework", "CoreVideo",
    "-framework", "OpenGL",
    "-framework", "CoreAudio",
    "-framework", "AudioToolbox",
]

args = sys.argv[1:]
if "-c" in args:
    c = any(arg.endswith(".c") for arg in args)
    more = ["-idirafter", RAYLIB_INCLUDE] if RAYLIB_INCLUDE and c else []
    sys.exit(subprocess.call([REAL_CC] + args + more))

if not os.path.isfile(LIBRAYLIB_A):
    sys.exit(f"static_cc: no static raylib at {LIBRAYLIB_A} "
             "($LIBRAYLIB_A says another)")

# Only a --parallel link names libomp.dylib; substitute the static
# runtime there, and keep OpenMP out of a single-core link entirely.
RUNTIME = "libomp.so" if LINUX else "libomp.dylib"
saw_omp = any(arg.endswith(RUNTIME) for arg in args)
if saw_omp and (not LIBOMP_A or not os.path.isfile(LIBOMP_A)):
    sys.exit("static_cc: $LIBOMP_A does not name a static libomp.a "
             "(tools/build_release.sh builds one)")

out = []
for arg in args:
    if arg == "-lraylib" or arg.endswith(RUNTIME):
        continue
    if arg.startswith("-Wl,-rpath,"):
        continue
    out.append(arg)
if saw_omp:
    out.append(LIBOMP_A)
elif not LINUX:
    # devices/text.c expects omp_in_parallel to be weak-undefined
    # where there is no OpenMP; Mach-O's linker refuses that, so a
    # single-core link gets the true stub (tools/omp_stub.c).
    import tempfile
    stub = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "omp_stub.c")
    obj = os.path.join(tempfile.mkdtemp(prefix="ent-omp-stub-"),
                       "omp_stub.o")
    if subprocess.call([REAL_CC, "-c", stub, "-o", obj]):
        sys.exit("static_cc: could not build tools/omp_stub.c")
    out.append(obj)
out += [LIBRAYLIB_A] + SYSTEM
sys.exit(subprocess.call([REAL_CC] + out))
