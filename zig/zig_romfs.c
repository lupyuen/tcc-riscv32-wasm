#include "zig_romfs.h"

struct inode romfs_mounting_inode;
struct inode romfs_blkdriver_inode;
struct inode *romfs_blkdriver = &romfs_blkdriver_inode;
void *romfs_mountpt = NULL;

struct inode *create_mount_inode(void *romfs_mountpt0) {
  romfs_mounting_inode.i_private = romfs_mountpt0;
  return &romfs_mounting_inode;
}
