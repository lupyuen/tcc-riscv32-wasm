// C Integration for Zig ROM FS
#include "zig_romfs.h"

// Mount Inode for ROM FS
struct inode romfs_mounting_inode;

// Block Driver for ROM FS
struct inode romfs_blkdriver_inode;
struct inode *romfs_blkdriver = &romfs_blkdriver_inode;

// Mount Point for ROM FS
void *romfs_mountpt = NULL;

// Return a Mount Inode for ROM FS, initialised with the Mount Point
// TODO: Support multiple Mount Nodes
struct inode *create_mount_inode(void *romfs_mountpt0) {
  romfs_mounting_inode.i_private = romfs_mountpt0;
  return &romfs_mounting_inode;
}
