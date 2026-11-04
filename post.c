// The C of post.ent (see there): a picture on the clipboard, a file
// shown in the file manager, on each of the three systems.

#include "ent_extern.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define POST_PATH 4096

// An ent text as a C string.
static void post_c(const ent_text126 *t, char *out) {
  int n = t->length < 0 ? 0 : t->length;
  memcpy(out, t->bytes, (size_t)n);
  out[n] = 0;
}

#if defined(_WIN32)

#include <windows.h>
#include <shellapi.h>

// raylib's, linked in already (windows.h has a LoadImage of its own, a
// macro).
#undef LoadImage
typedef struct {
  void *data;
  int width, height, mipmaps, format;
} PostImage;
PostImage LoadImage(const char *file);
void ImageFormat(PostImage *image, int format);
void UnloadImage(PostImage image);
void *GetWindowHandle(void);
#define POST_RGBA 7 // PIXELFORMAT_UNCOMPRESSED_R8G8B8A8

static wchar_t *post_wide(const char *s) {
  int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0);
  if (n <= 0)
    return NULL;
  wchar_t *w = (wchar_t *)malloc(sizeof(wchar_t) * (size_t)n);
  if (w)
    MultiByteToWideChar(CP_UTF8, 0, s, -1, w, n);
  return w;
}

static HGLOBAL post_global(const void *bytes, size_t n) {
  HGLOBAL g = GlobalAlloc(GMEM_MOVEABLE, n);
  if (!g)
    return NULL;
  void *p = GlobalLock(g);
  if (!p) {
    GlobalFree(g);
    return NULL;
  }
  memcpy(p, bytes, n);
  GlobalUnlock(g);
  return g;
}

// The file's bytes, as they are (for "PNG").
static unsigned char *post_bytes(const char *path, size_t *n) {
  wchar_t *w = post_wide(path);
  FILE *f = w ? _wfopen(w, L"rb") : NULL;
  free(w);
  if (!f)
    return NULL;
  fseek(f, 0, SEEK_END);
  long size = ftell(f);
  fseek(f, 0, SEEK_SET);
  unsigned char *b = size > 0 ? (unsigned char *)malloc((size_t)size) : NULL;
  if (b && fread(b, 1, (size_t)size, f) != (size_t)size) {
    free(b);
    b = NULL;
  }
  fclose(f);
  *n = b ? (size_t)size : 0;
  return b;
}

// The picture as a bitmap (CF_DIB): a header, then the rows from the
// bottom up, 3 bytes a pixel (blue, green, red), each row made a
// multiple of 4.
static unsigned char *post_dib(const char *path, size_t *n) {
  PostImage im = LoadImage(path);
  if (!im.data)
    return NULL;
  ImageFormat(&im, POST_RGBA);
  int w = im.width, h = im.height;
  size_t row = ((size_t)w * 3 + 3) & ~(size_t)3;
  *n = sizeof(BITMAPINFOHEADER) + row * (size_t)h;
  unsigned char *b = (unsigned char *)calloc(1, *n);
  if (b) {
    BITMAPINFOHEADER *bi = (BITMAPINFOHEADER *)b;
    bi->biSize = sizeof(BITMAPINFOHEADER);
    bi->biWidth = w;
    bi->biHeight = h;
    bi->biPlanes = 1;
    bi->biBitCount = 24;
    bi->biCompression = BI_RGB;
    bi->biSizeImage = (DWORD)(row * (size_t)h);
    const unsigned char *px = (const unsigned char *)im.data;
    for (int y = 0; y < h; y++) {
      unsigned char *to = b + sizeof(BITMAPINFOHEADER) + row * (size_t)(h - 1 - y);
      const unsigned char *from = px + (size_t)y * (size_t)w * 4;
      for (int x = 0; x < w; x++) {
        to[x * 3] = from[x * 4 + 2];
        to[x * 3 + 1] = from[x * 4 + 1];
        to[x * 3 + 2] = from[x * 4];
      }
    }
  }
  UnloadImage(im);
  return b;
}

bool ent_post_copy_picture(const ent_text126 *file) {
  char path[POST_PATH];
  post_c(file, path);
  size_t png_n = 0, dib_n = 0;
  unsigned char *png = post_bytes(path, &png_n);
  unsigned char *dib = png ? post_dib(path, &dib_n) : NULL;
  bool ok = false;
  if (png && dib) {
    // Another program may have it open a moment: a few tries.
    bool open = false;
    for (int i = 0; i < 10 && !open; i++) {
      open = OpenClipboard((HWND)GetWindowHandle());
      if (!open)
        Sleep(10);
    }
    if (open) {
      EmptyClipboard();
      HGLOBAL gd = post_global(dib, dib_n);
      HGLOBAL gp = post_global(png, png_n);
      // The clipboard owns what it was given; what it was not, is freed.
      bool d = gd && SetClipboardData(CF_DIB, gd);
      if (gd && !d)
        GlobalFree(gd);
      bool p = gp && SetClipboardData(RegisterClipboardFormatA("PNG"), gp);
      if (gp && !p)
        GlobalFree(gp);
      CloseClipboard();
      ok = d || p;
    }
  }
  free(png);
  free(dib);
  return ok;
}

bool ent_post_show_file(const ent_text126 *file) {
  char path[POST_PATH];
  post_c(file, path);
  for (char *c = path; *c; c++)
    if (*c == '/')
      *c = '\\';
  wchar_t *w = post_wide(path);
  if (!w)
    return false;
  wchar_t full[POST_PATH];
  bool ok = _wfullpath(full, w, POST_PATH) != NULL;
  free(w);
  if (!ok)
    return false;
  wchar_t args[POST_PATH + 16];
  _snwprintf(args, POST_PATH + 16, L"/select,\"%ls\"", full);
  args[POST_PATH + 15] = 0;
  HINSTANCE r = ShellExecuteW(NULL, L"open", L"explorer.exe", args, NULL, SW_SHOWNORMAL);
  return (INT_PTR)r > 32;
}

#elif defined(__APPLE__)

#include <dlfcn.h>
#include <limits.h>

// The Objective-C runtime, found where it is loaded (raylib's window
// brought AppKit in), so that the game links nothing more for it.
typedef void *id;
typedef void *SEL;
static id (*post_class)(const char *);
static SEL (*post_sel)(const char *);
static void *post_send;
static void *(*post_push)(void);
static void (*post_pop)(void *);

static bool post_runtime(void) {
  if (!post_send) {
    post_class = (id(*)(const char *))dlsym(RTLD_DEFAULT, "objc_getClass");
    post_sel = (SEL(*)(const char *))dlsym(RTLD_DEFAULT, "sel_registerName");
    post_push = (void *(*)(void))dlsym(RTLD_DEFAULT, "objc_autoreleasePoolPush");
    post_pop = (void (*)(void *))dlsym(RTLD_DEFAULT, "objc_autoreleasePoolPop");
    post_send = dlsym(RTLD_DEFAULT, "objc_msgSend");
  }
  return post_class && post_sel && post_push && post_pop && post_send;
}

// Messages by their shapes (objc_msgSend called as the method is).
#define SEND0(o, s) ((id(*)(id, SEL))post_send)((o), post_sel(s))
#define SEND1(o, s, a) ((id(*)(id, SEL, id))post_send)((o), post_sel(s), (a))
#define SEND_TEXT(o, s, a) ((id(*)(id, SEL, const char *))post_send)((o), post_sel(s), (a))
#define SEND2_YES(o, s, a, b) ((signed char (*)(id, SEL, id, id))post_send)((o), post_sel(s), (a), (b))

static id post_string(const char *s) { return SEND_TEXT(post_class("NSString"), "stringWithUTF8String:", s); }

// The file's whole path, as an NSString.
static id post_path(const ent_text126 *file) {
  char path[POST_PATH], full[PATH_MAX];
  post_c(file, path);
  if (!realpath(path, full))
    return NULL;
  return post_string(full);
}

bool ent_post_copy_picture(const ent_text126 *file) {
  if (!post_runtime() || !post_class("NSPasteboard"))
    return false;
  void *pool = post_push();
  bool ok = false;
  id path = post_path(file);
  id data = path ? SEND1(post_class("NSData"), "dataWithContentsOfFile:", path) : NULL;
  if (data) {
    id board = SEND0(post_class("NSPasteboard"), "generalPasteboard");
    ((long (*)(id, SEL))post_send)(board, post_sel("clearContents"));
    ok = SEND2_YES(board, "setData:forType:", data, post_string("public.png")) != 0;
    // TIFF too, which some programs take rather than PNG.
    id image = SEND1(SEND0(post_class("NSImage"), "alloc"), "initWithData:", data);
    if (image) {
      id tiff = SEND0(image, "TIFFRepresentation");
      if (tiff)
        ok = SEND2_YES(board, "setData:forType:", tiff, post_string("public.tiff")) != 0 || ok;
      SEND0(image, "release");
    }
  }
  post_pop(pool);
  return ok;
}

bool ent_post_show_file(const ent_text126 *file) {
  if (!post_runtime() || !post_class("NSWorkspace"))
    return false;
  void *pool = post_push();
  id path = post_path(file);
  if (path) {
    id url = SEND1(post_class("NSURL"), "fileURLWithPath:", path);
    id urls = SEND1(post_class("NSArray"), "arrayWithObject:", url);
    SEND1(SEND0(post_class("NSWorkspace"), "sharedWorkspace"), "activateFileViewerSelectingURLs:", urls);
  }
  post_pop(pool);
  return path != NULL;
}

#else // Linux and the like

#include <fcntl.h>
#include <limits.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

// Whether a program is on the PATH.
static bool post_found(const char *name) {
  const char *path = getenv("PATH");
  if (!path)
    return false;
  char dir[POST_PATH];
  while (*path) {
    size_t n = strcspn(path, ":");
    if (n > 0 && n + strlen(name) + 2 < sizeof dir) {
      memcpy(dir, path, n);
      dir[n] = '/';
      strcpy(dir + n + 1, name);
      if (access(dir, X_OK) == 0)
        return true;
    }
    path += n;
    if (*path == ':')
      path++;
  }
  return false;
}

// A program started with `in` as its input (or nothing), the game's own
// files closed for it, in a session of its own (so that it may stay
// after the game). Waited for up to `wait` seconds: its exit status,
// or 0 when it is still going (it is then left to go on, and taken back
// when it has ended, at the next call).
static pid_t post_left;

static int post_run(char *const argv[], const char *in, double wait) {
  if (post_left > 0 && waitpid(post_left, NULL, WNOHANG) != 0)
    post_left = 0;
  pid_t pid = fork();
  if (pid < 0)
    return -1;
  if (pid == 0) {
    int fd = open(in ? in : "/dev/null", O_RDONLY);
    int null = open("/dev/null", O_WRONLY);
    if (fd < 0 || null < 0)
      _exit(126);
    dup2(fd, 0);
    dup2(null, 1);
    dup2(null, 2);
    for (int i = 3; i < 1024; i++)
      close(i);
    setsid();
    execvp(argv[0], argv);
    _exit(127);
  }
  struct timespec step = {0, 10 * 1000 * 1000};
  for (double t = 0; t < wait; t += 0.01) {
    int status;
    if (waitpid(pid, &status, WNOHANG) == pid)
      return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
    nanosleep(&step, NULL);
  }
  post_left = pid;
  return 0;
}

bool ent_post_copy_picture(const ent_text126 *file) {
  char path[POST_PATH];
  post_c(file, path);
  if (access(path, R_OK) != 0)
    return false;
  // (Both give the picture out from a process of their own that stays
  // while it is what is pasted, and leave as soon as they have it.)
  if (getenv("WAYLAND_DISPLAY") && post_found("wl-copy")) {
    char *argv[] = {"wl-copy", "--type", "image/png", NULL};
    if (post_run(argv, path, 2.0) == 0)
      return true;
  }
  if (getenv("DISPLAY") && post_found("xclip")) {
    char *argv[] = {"xclip", "-selection", "clipboard", "-t", "image/png", "-i", NULL};
    if (post_run(argv, path, 2.0) == 0)
      return true;
  }
  return false;
}

// A path as a file:// URI, all but the plain characters as %XX.
static void post_uri(const char *full, char *out, size_t size) {
  static const char hex[] = "0123456789ABCDEF";
  size_t o = 0;
  o += (size_t)snprintf(out, size, "file://");
  for (const unsigned char *c = (const unsigned char *)full; *c && o + 4 < size; c++) {
    if ((*c >= 'a' && *c <= 'z') || (*c >= 'A' && *c <= 'Z') || (*c >= '0' && *c <= '9') ||
        strchr("/-_.~", *c)) {
      out[o++] = (char)*c;
    } else {
      out[o++] = '%';
      out[o++] = hex[*c >> 4];
      out[o++] = hex[*c & 15];
    }
  }
  out[o] = 0;
}

bool ent_post_show_file(const ent_text126 *file) {
  char path[POST_PATH], full[PATH_MAX], uri[POST_PATH * 3 + 16], items[POST_PATH * 3 + 32];
  post_c(file, path);
  if (!realpath(path, full))
    return false;
  post_uri(full, uri, sizeof uri);
  snprintf(items, sizeof items, "array:string:%s", uri);
  if (post_found("dbus-send")) {
    char *argv[] = {"dbus-send", "--session", "--print-reply", "--dest=org.freedesktop.FileManager1",
                    "--type=method_call", "/org/freedesktop/FileManager1",
                    "org.freedesktop.FileManager1.ShowItems", items, "string:", NULL};
    if (post_run(argv, NULL, 3.0) == 0)
      return true;
  }
  if (post_found("xdg-open")) {
    char *slash = strrchr(full, '/');
    if (slash && slash != full)
      *slash = 0;
    char *argv[] = {"xdg-open", full, NULL};
    return post_run(argv, NULL, 2.0) == 0;
  }
  return false;
}

#endif
