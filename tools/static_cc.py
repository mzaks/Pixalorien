#!/usr/bin/env python3
"""The host compiler, with the link made self-contained (macOS).

Used by tools/build_release.sh as ENT_CC. Compile steps (-c) pass
through to the real `cc`. The link step is rewritten:

  - `-lraylib` becomes the static libraylib.a ($LIBRAYLIB_A, else
    Homebrew's) plus the system frameworks raylib needs;
  - the Homebrew libomp.dylib that `ent build --parallel` links (with
    an rpath into Homebrew) becomes the static libomp.a in $LIBOMP_A.

The result depends only on system libraries, so it runs on a Mac
without Homebrew. (The game's files are in the binary itself:
`asset` in pixalorien.ent, `ent build --embed`.)
"""
import os
import subprocess
import sys

REAL_CC = "/usr/bin/cc"
LIBOMP_A = os.environ.get("LIBOMP_A", "")
LIBRAYLIB_A = os.environ.get(
    "LIBRAYLIB_A", "/opt/homebrew/lib/libraylib.a")
FRAMEWORKS = [
    "-framework", "Cocoa",
    "-framework", "IOKit",
    "-framework", "CoreVideo",
    "-framework", "OpenGL",
    "-framework", "CoreAudio",
    "-framework", "AudioToolbox",
]

args = sys.argv[1:]
if "-c" in args:
    sys.exit(subprocess.call([REAL_CC] + args))

if not os.path.isfile(LIBRAYLIB_A):
    sys.exit(f"static_cc: no static raylib at {LIBRAYLIB_A} "
             "($LIBRAYLIB_A says another)")

# Only a --parallel link names libomp.dylib; substitute the static
# runtime there, and keep OpenMP out of a single-core link entirely.
saw_omp = any(arg.endswith("libomp.dylib") for arg in args)
if saw_omp and (not LIBOMP_A or not os.path.isfile(LIBOMP_A)):
    sys.exit("static_cc: $LIBOMP_A does not name a static libomp.a "
             "(tools/build_release.sh builds one)")

out = []
for arg in args:
    if arg == "-lraylib" or arg.endswith("libomp.dylib"):
        continue
    if arg.startswith("-Wl,-rpath,"):
        continue
    out.append(arg)
if saw_omp:
    out.append(LIBOMP_A)
else:
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
out += [LIBRAYLIB_A] + FRAMEWORKS
sys.exit(subprocess.call([REAL_CC] + out))
