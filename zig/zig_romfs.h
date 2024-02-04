//// Custom Definitions for Zig ROM FS
#ifndef __ZIG_ROMFS_H
#define __ZIG_ROMFS_H

#define CODE
#define DEBUGASSERT(cond) { if (!(cond)) { printf( "*** Assert Failed at " __FILE__ ":%d - " #cond "\n", __LINE__); exit(-1); } }
#define FAR
#define NAME_MAX 255
#define PATH_MAX 255

// Open flag settings for open()
#define O_RDONLY    (1 << 0)        /* Open for read access (only) */
#define O_WRONLY    (1 << 1)        /* Open for write access (only) */

// For mtd_ioctl()
#define MTDIOC_GEOMETRY 1
#define BIOC_XIPBASE 2

#include <stdio.h>
#include <stdint.h>

// Needed by inode.h and fs.h
typedef int posix_spawn_file_actions_t;
typedef int rmutex_t;
typedef int spinlock_t;

// Needed by inode.h
struct mtd_geometry_s {
  uint32_t blocksize;     /* Size of one read/write block. */
  uint32_t erasesize;     /* Size of one erase blocks -- must be a multiple of blocksize. */
  uint32_t neraseblocks;  /* Number of erase blocks */
  char     model[NAME_MAX + 1]; /* NULL-terminated string representing the device model */
};

// Needed by inode.h and fs.h
struct mm_map_entry_s {
  void *vaddr;
  size_t length;
  off_t offset;
};

// Needed by romfs_bind and romfs_open
#include "fs.h"
#include "inode.h"

// From fs_romfs.c
extern struct inode *romfs_blkdriver;
extern void *romfs_handle;

// From fs_romfs.c
int romfs_bind(struct inode *blkdriver, const void *data, void **handle);
int romfs_open(struct file *filep, const char *relpath, int oflags, mode_t mode);

// From tcc-wasm.zig
int nxrmutex_init(rmutex_t *rmutex);
int nxrmutex_destroy(rmutex_t *rmutex);
int nxrmutex_lock(rmutex_t *rmutex);
int nxrmutex_unlock(rmutex_t *rmutex);

// From tcc-wasm.zig
void *kmm_zalloc(size_t size);
int mtd_ioctl(struct mtd_dev_s *dev, int cmd, unsigned long arg);
ssize_t mtd_bread(struct mtd_dev_s *dev, off_t block, size_t nsectors, uint8_t *buf);

#endif  // __ZIG_ROMFS_H
