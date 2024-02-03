#ifndef __ZIG_ROMFS_H
#define __ZIG_ROMFS_H

#include <stdio.h>////
#include <stdint.h>////
struct mm_map_entry_s {////
  uint8_t length;
  uint8_t offset;
  uint8_t rm_xipbase;
  uint8_t *vaddr;
};
int nxrmutex_init(FAR rmutex_t *rmutex);////
int nxrmutex_destroy(FAR rmutex_t *rmutex);////
int nxrmutex_lock(FAR rmutex_t *rmutex);////
int nxrmutex_unlock(FAR rmutex_t *rmutex);////
FAR void *kmm_zalloc(size_t size);////

#endif  // __ZIG_ROMFS_H
