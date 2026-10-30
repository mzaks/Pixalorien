// The app bundle's main executable (tools/build_release.sh): the
// game beside it, started from the home folder — a program launched
// from Finder starts at the root, where its saved worlds could not
// be written. Nothing else: the game is the program.
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
  char path[PATH_MAX];
  uint32_t size = sizeof path;
  if (_NSGetExecutablePath(path, &size) != 0)
    return 1;
  char *slash = strrchr(path, '/');
  if (!slash)
    return 1;
  *slash = 0;
  char game[PATH_MAX];
  snprintf(game, sizeof game, "%s/Pixalorien-real", path);
  const char *home = getenv("HOME");
  if (home && chdir(home) != 0)
    return 1;
  argv[0] = game;
  execv(game, argv);
  perror("Pixalorien");
  return 1;
}
