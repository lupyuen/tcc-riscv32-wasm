//// Custom Definitions for Zig ROM FS
#ifndef __ZIG_ROMFS_H
#define __ZIG_ROMFS_H

#define FAR
#define NAME_MAX 255
#define PATH_MAX 255

// For mtd_ioctl()
#define MTDIOC_GEOMETRY 1
#define BIOC_XIPBASE 2

#include <stdio.h>
#include <stdint.h>
#include "inode.h"

typedef int rmutex_t;

struct mtd_geometry_s {
  uint32_t blocksize;     /* Size of one read/write block. */
  uint32_t erasesize;     /* Size of one erase blocks -- must be a multiple of blocksize. */
  uint32_t neraseblocks;  /* Number of erase blocks */
  char     model[NAME_MAX + 1]; /* NULL-terminated string representing the device model */
};

struct mm_map_entry_s {
  void *vaddr;
  size_t length;
  off_t offset;
};

extern struct inode *romfs_blkdriver;
extern void *romfs_handle;

int romfs_bind(struct inode *blkdriver, const void *data, void **handle);

int nxrmutex_init(rmutex_t *rmutex);
int nxrmutex_destroy(rmutex_t *rmutex);
int nxrmutex_lock(rmutex_t *rmutex);
int nxrmutex_unlock(rmutex_t *rmutex);

void *kmm_zalloc(size_t size);

ssize_t mtd_bread(struct mtd_dev_s *dev,
  off_t block,
  size_t nsectors,
  uint8_t *buf);
int mtd_ioctl(struct mtd_dev_s *dev,
  int cmd,
  unsigned long arg);

#endif  // __ZIG_ROMFS_H
