#ifndef __ZIG_ROMFS_H
#define __ZIG_ROMFS_H

//// Custom Definitions for Zig ROM FS
#include <stdio.h>
#include <stdint.h>

struct mtd_geometry_s
{
  uint32_t blocksize;     /* Size of one read/write block. */
  uint32_t erasesize;     /* Size of one erase blocks -- must be a multiple
                           * of blocksize. */
  uint32_t neraseblocks;  /* Number of erase blocks */

  /* NULL-terminated string representing the device model */

  char     model[NAME_MAX + 1];
};

struct mm_map_entry_s {
  uint8_t length;
  uint8_t offset;
  uint8_t rm_xipbase;
  uint8_t *vaddr;
};

int nxrmutex_init(FAR rmutex_t *rmutex);
int nxrmutex_destroy(FAR rmutex_t *rmutex);
int nxrmutex_lock(FAR rmutex_t *rmutex);
int nxrmutex_unlock(FAR rmutex_t *rmutex);

FAR void *kmm_zalloc(size_t size);

static ssize_t mtd_bread(FAR struct mtd_dev_s *dev,
                         off_t block,
                         size_t nsectors,
                         FAR uint8_t *buf);
static int mtd_ioctl(FAR struct mtd_dev_s *dev,
                     int cmd,
                     unsigned long arg);

#endif  // __ZIG_ROMFS_H
