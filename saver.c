// The writing thread of saver.ent (see there): a checkpoint is a
// copy of the world's parts as they stand, made where the game
// stands; the file is written from the copy by a thread of its own,
// so a slow disk stalls that thread, not the game. Implemented
// against the generated ent_world.h like devices/world.c, whose
// ent_world_save does the writing (from the copy, which has the
// world's layout byte for byte).

#include "ent_world.h"

#ifdef __EMSCRIPTEN__

// On a web page there are no threads: the checkpoint is written where
// the game stands, at once (into the page's memory, Emscripten's MEMFS,
// so it takes milliseconds, not a disk's time). And the folder runs/ is
// the browser's own (IndexedDB, Emscripten's IDBFS): read in when the
// game starts and written out after a run is saved, so the runs are
// still there when the page is opened again.

#include <emscripten.h>
#include <string.h>

void ent_saver_save_world_bg(ent_world *world) {
  static char path[sizeof(((ent_text126 *)0)->bytes) + 1];
  const ent_text126 *file = ent_world_Saved_file(world);
  memcpy(path, file->bytes, file->length);
  path[file->length] = 0;
  *ent_world_Saved_ok(world) = ent_world_save(world, path);
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

void ent_saver_keep_runs_open(ent_world *world) {
  (void)world;
  saver_keep_open();
}

void ent_saver_keep_runs(ent_world *world) {
  (void)world;
  saver_keep_write();
}

#else

void ent_saver_keep_runs_open(ent_world *world) { (void)world; }

void ent_saver_keep_runs(ent_world *world) { (void)world; }

#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>

// 0: idle, 1: writing, 2: written, 3: failed.
static _Atomic int saver_state;
static pthread_t saver_thread;
static int saver_started;
static char *saver_copy;
static char saver_path[sizeof(((ent_text126 *)0)->bytes) + 1];

static void *saver_write(void *unused) {
  (void)unused;
  bool ok = ent_world_save((const ent_world *)saver_copy, saver_path);
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
  const ent_text126 *file = ent_world_Saved_file(world);
  memcpy(saver_path, file->bytes, file->length);
  saver_path[file->length] = 0;
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
