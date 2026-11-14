// The writing thread of saver.ent (see there): a checkpoint is a
// copy of the world's parts as they stand, made where the game
// stands; the file is written from the copy by a thread of its own,
// so a slow disk stalls that thread, not the game. Implemented
// against the generated ent_world.h like devices/world.c.
//
// A checkpoint is what ent_world_save writes (its head, then the parts
// of the world in use), made smaller by Zstandard (level 1, zstd/): a
// world of 32 MB is a file of about 4 MB, written in 8 ms and read in
// 4 (most of a world is noughts and runs of one cell). `load_saved`
// reads one back as ent_world_load does: into a world of its own
// first, and into the game's only if all of it came.

#include "ent_world.h"

#include "zstd/unity.c"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAVER_HEAD 0x646c726f77746e65ull
#define SAVER_PATH (sizeof(((ent_text126 *)0)->bytes) + 1)

static void saver_name(ent_world *world, char *path) {
  const ent_text126 *file = ent_world_Saved_file(world);
  memcpy(path, file->bytes, file->length);
  path[file->length] = 0;
}

// How many bytes of a part are written: all of it, or the rows in use
// (counted in `counts`), or -1 where the count is out of reach.
static int64_t saver_part(const char *counts, size_t part) {
  uint64_t bytes = ent__world_parts[part].bytes;
  uint64_t each = ent__world_parts[part].each;
  if (each) {
    int64_t rows;
    memcpy(&rows, counts + ent__world_parts[part].count, 8);
    if (rows < 0 || (uint64_t)rows > bytes / each)
      return -1;
    bytes = (uint64_t)rows * each;
  }
  return (int64_t)bytes;
}

// The writing: `n` bytes into the stream (the end of it with `end`),
// and what Zstandard has made of them out to the file.
static ZSTD_CCtx *saver_cctx;
static char *saver_out;

static bool saver_feed(FILE *file, const void *from, size_t n, int end) {
  ZSTD_inBuffer in = {from, n, 0};
  size_t room = ZSTD_CStreamOutSize();
  for (;;) {
    ZSTD_outBuffer out = {saver_out, room, 0};
    size_t left = ZSTD_compressStream2(saver_cctx, &out, &in,
                                       end ? ZSTD_e_end : ZSTD_e_continue);
    if (ZSTD_isError(left))
      return false;
    if (out.pos && fwrite(saver_out, 1, out.pos, file) != out.pos)
      return false;
    if (end ? left == 0 : in.pos == in.size)
      return true;
  }
}

static bool saver_pack(const char *arena, const char *path) {
  if (!saver_cctx) {
    saver_cctx = ZSTD_createCCtx();
    saver_out = (char *)malloc(ZSTD_CStreamOutSize());
    if (!saver_cctx || !saver_out)
      return false;
    ZSTD_CCtx_setParameter(saver_cctx, ZSTD_c_compressionLevel, 1);
  }
  ZSTD_CCtx_reset(saver_cctx, ZSTD_reset_session_only);
  FILE *file = fopen(path, "wb");
  if (!file)
    return false;
  uint64_t head[2] = {SAVER_HEAD, ENT_WORLD_FINGERPRINT};
  bool ok = saver_feed(file, head, sizeof head, 0);
  size_t parts = sizeof ent__world_parts / sizeof ent__world_parts[0];
  for (size_t part = 0; ok && part < parts; ++part) {
    int64_t bytes = saver_part(arena, part);
    ok = bytes >= 0 && (bytes == 0 || saver_feed(file, arena + ent__world_parts[part].offset, (size_t)bytes, 0));
  }
  ok = ok && saver_feed(file, NULL, 0, 1);
  return fclose(file) == 0 && ok;
}

// The reading: exactly `n` bytes of the stream into `to`. (`left` is
// what Zstandard said last: 0 where its frame has ended.)
static bool saver_take(ZSTD_DCtx *d, ZSTD_inBuffer *in, void *to, size_t n,
                       size_t *left) {
  ZSTD_outBuffer out = {to, n, 0};
  while (out.pos < out.size) {
    size_t before = in->pos, made = out.pos;
    *left = ZSTD_decompressStream(d, &out, in);
    if (ZSTD_isError(*left))
      return false;
    if (in->pos == before && out.pos == made)
      return false;
  }
  return true;
}

static bool saver_unpack(ent_world *world, const char *path) {
  FILE *file = fopen(path, "rb");
  if (!file)
    return false;
  char *packed = NULL;
  long n = -1;
  if (fseek(file, 0, SEEK_END) == 0 && (n = ftell(file)) > 0 && fseek(file, 0, SEEK_SET) == 0)
    packed = (char *)malloc((size_t)n);
  bool ok = packed && fread(packed, 1, (size_t)n, file) == (size_t)n;
  fclose(file);
  ZSTD_DCtx *d = ok ? ZSTD_createDCtx() : NULL;
  char *held = d ? (char *)malloc(ENT_WORLD_BYTES) : NULL;
  ok = held != NULL;
  ZSTD_inBuffer in = {packed, ok ? (size_t)n : 0, 0};
  uint64_t head[2];
  size_t left = 1;
  ok = ok && saver_take(d, &in, head, sizeof head, &left) && head[0] == SAVER_HEAD &&
       head[1] == ENT_WORLD_FINGERPRINT;
  size_t parts = sizeof ent__world_parts / sizeof ent__world_parts[0];
  for (size_t part = 0; ok && part < parts; ++part) {
    // (The counts are read before the parts they count.)
    int64_t bytes = saver_part(held, part);
    ok = bytes >= 0 && (bytes == 0 || saver_take(d, &in, held + ent__world_parts[part].offset, (size_t)bytes, &left));
  }
  // And nothing after: the frame at its end (where the last part did
  // not end it, a call with room for one byte more, which must take
  // none), all of the file read. (After its end Zstandard waits for
  // another frame: it is not asked again.)
  if (ok && left != 0) {
    char more;
    ZSTD_outBuffer out = {&more, 1, 0};
    left = ZSTD_decompressStream(d, &out, &in);
    ok = !ZSTD_isError(left) && out.pos == 0;
  }
  ok = ok && left == 0 && in.pos == in.size;
  if (ok)
    ent__world_parts_pass((char *)world, held, NULL, 2);
  free(held);
  ZSTD_freeDCtx(d);
  free(packed);
  return ok;
}

void ent_saver_load_saved(ent_world *world) {
  char path[SAVER_PATH];
  saver_name(world, path);
  // (`Saved` is transient: the name and this answer are not the file's.)
  *ent_world_Saved_ok(world) = saver_unpack(world, path);
}

#ifdef __EMSCRIPTEN__

// On a web page there are no threads: the checkpoint is written where
// the game stands, at once (into the page's memory, Emscripten's MEMFS,
// so it takes milliseconds, not a disk's time). And the folder runs/ is
// the browser's own (IndexedDB, Emscripten's IDBFS): read in when the
// game starts and written out after a run is saved, so the runs are
// still there when the page is opened again.

#include <emscripten.h>

void ent_saver_save_world_bg(ent_world *world) {
  char path[SAVER_PATH];
  saver_name(world, path);
  *ent_world_Saved_ok(world) = saver_pack((const char *)world, path);
}

void ent_saver_save_world_poll(ent_world *world) { (void)world; }

void ent_saver_save_world_join(ent_world *world) { (void)world; }

// (Waits, through Asyncify, for the browser's copy to be read in: the
// menu's LOAD lists the folder after.)
EM_ASYNC_JS(void, saver_keep_open, (void), {
  try { FS.mkdir("/runs"); } catch (e) {}
  try { FS.mount(IDBFS, {}, "/runs"); } catch (e) { return; }
  await new Promise(function (done) { FS.syncfs(true, function () { done(); }); });
});

EM_JS(void, saver_keep_write, (void), {
  FS.syncfs(false, function (e) { if (e) console.warn("runs/ not kept", e); });
});

bool ent_saver_web_page(void) { return true; }

void ent_saver_keep_runs_open(ent_world *world) {
  (void)world;
  saver_keep_open();
}

void ent_saver_keep_runs(ent_world *world) {
  (void)world;
  saver_keep_write();
}

#else

bool ent_saver_web_page(void) { return false; }

void ent_saver_keep_runs_open(ent_world *world) { (void)world; }

void ent_saver_keep_runs(ent_world *world) { (void)world; }

#include <pthread.h>
#include <stdatomic.h>

// 0: idle, 1: writing, 2: written, 3: failed.
static _Atomic int saver_state;
static pthread_t saver_thread;
static int saver_started;
static char *saver_copy;
static char saver_path[SAVER_PATH];

static void *saver_write(void *unused) {
  (void)unused;
  bool ok = saver_pack(saver_copy, saver_path);
  atomic_store(&saver_state, ok ? 2 : 3);
  return NULL;
}

// Takes back a finished write, if any: how it went, or -1 while one
// is still going (or none ever ran).
static int saver_reap(ent_world *world, int wait) {
  int state = atomic_load(&saver_state);
  if (state == 1 && !wait)
    return -1;
  if (state == 0)
    return -1;
  pthread_join(saver_thread, NULL);
  saver_started = 0;
  atomic_store(&saver_state, 0);
  *ent_world_Saved_ok(world) = state == 2;
  return state == 2;
}

void ent_saver_save_world_bg(ent_world *world) {
  if (atomic_load(&saver_state) == 1) {
    // Still writing the last one: this checkpoint is skipped (its
    // slot keeps the older world, which a replay can start from).
    *ent_world_Saved_ok(world) = false;
    return;
  }
  if (saver_started)
    saver_reap(world, 1);
  if (!saver_copy)
    saver_copy = (char *)malloc(ENT_WORLD_BYTES);
  if (!saver_copy) {
    *ent_world_Saved_ok(world) = false;
    return;
  }
  // The copy: the world's parts, each as much of it as is in use
  // (the pass a load makes into its held world, made of this one).
  ent__world_parts_pass(saver_copy, (const char *)world, NULL, 2);
  saver_name(world, saver_path);
  atomic_store(&saver_state, 1);
  if (pthread_create(&saver_thread, NULL, saver_write, NULL) != 0) {
    atomic_store(&saver_state, 0);
    *ent_world_Saved_ok(world) = false;
    return;
  }
  saver_started = 1;
}

void ent_saver_save_world_poll(ent_world *world) {
  if (saver_started)
    saver_reap(world, 0);
}

void ent_saver_save_world_join(ent_world *world) {
  if (saver_started)
    saver_reap(world, 1);
}

#endif
