#!/usr/bin/env bash
#  Build and Test TCC for WebAssembly

## TODO: Set PATH
export PATH=/workspaces/bookworm/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$PATH
export PATH=/workspaces/bookworm/zig-linux-x86_64-0.12.0-dev.2341+92211135f:$PATH

set -e  #  Exit when any command fails
set -x  #  Echo commands

## Compile TCC from C to WebAssembly
function build_wasm {

  ## Zig Compiler options for TCC
  tcc_options=" \
    -c \
    -target wasm32-freestanding \
    -dynamic \
    -rdynamic \
    -lc \
    -DTCC_TARGET_RISCV64 \
    -DCONFIG_TCC_CROSSPREFIX="\"riscv64-\""  \
    -DCONFIG_TCC_CRTPREFIX="\"/usr/riscv64-linux-gnu/lib\"" \
    -DCONFIG_TCC_LIBPATHS="\"{B}:/usr/riscv64-linux-gnu/lib\"" \
    -DCONFIG_TCC_SYSINCLUDEPATHS="\"{B}/include:/usr/riscv64-linux-gnu/include\""   \
    -DTCC_GITHASH="\"main:b3d10a35\"" \
    -Wall \
    -O2 \
    -Wdeclaration-after-statement \
    -fno-strict-aliasing \
    -Wno-pointer-sign \
    -Wno-sign-compare \
    -Wno-unused-result \
    -Wno-format-truncation \
    -Wno-stringop-truncation \
    -I. \
    "

  ## Zig Compiler options for NuttX ROM FS
  ## Note: All `static` functions become public
  nuttx_options=" \
    -DBIOC_XIPBASE=2 \
    -DCODE= \
    -DCONFIG_FS_ROMFS_CACHE_FILE_NSECTORS=1 \
    -DDEBUGASSERT=assert \
    -DDTYPE_DIRECTORY=DT_DIR \
    -DDTYPE_FILE=DT_REG \
    -DDTYPE_LINK=DT_LNK \
    -DERROR=-1 \
    -DFAR= \
    -DFIOC_FILEPATH=1 \
    -DNAME_MAX=255 \
    -DOK=0 \
    -DMTD_BREAD=mtd_bread \
    -DMTD_IOCTL=mtd_ioctl \
    -DMTDIOC_GEOMETRY=3 \
    -DPATH_MAX=255 \
    -DROMFS_MAGIC=0x7275 \
    \
    -Dferr=printf \
    -Dfinfo=printf \
    -Dfwarn=printf \
    -Dkmm_free=free \
    -Dkmm_malloc=malloc \
    -Dkmm_zalloc=zalloc \
    -Dposix_spawn_file_actions_t=int \
    -Drmutex_t=int \
    -Dspinlock_t=int \
    -Dstatic= \
    \
    -DEPERM=1 \
    -DENOENT=2 \
    -DEINTR=4 \
    -DEIO=5 \
    -DENXIO=6 \
    -DEAGAIN=11 \
    -DENOMEM=12 \
    -DEACCES=13 \
    -DEBUSY=16 \
    -DEEXIST=17 \
    -DENODEV=19 \
    -DENOTDIR=20 \
    -DEISDIR=21 \
    -DEINVAL=22 \
    -DENOTTY=25 \
    -DEPIPE=32 \
    -DEDOM=33 \
    -DERANGE=34 \
    -DENOSYS=38 \
    -DELOOP=40 \
    -DECONNREFUSED=111 \
    -DENOTSUP=138 \
    -DEWOULDBLOCK=140 \
    "

  ## Compile fs_romfs.c to WebAssembly
  zig cc \
    $nuttx_options \
    $tcc_options \
    zig/fs_romfs.c

  ## Compile fs_romfsutil.c to WebAssembly
  zig cc \
    $nuttx_options \
    $tcc_options \
    zig/fs_romfsutil.c

  ## Compile tcc.c to WebAssembly
  zig cc \
    $tcc_options \
    tcc.c

  ## Dump our Compiled WebAssembly
  # wasm-objdump -h tcc.o
  # wasm-objdump -x tcc.o >/tmp/tcc.txt

  ## Compile our Zig App `tcc-wasm.zig` for WebAssembly
  ## and link with TCC compiled for WebAssembly
  zig build-exe \
    -target wasm32-freestanding \
    -rdynamic \
    -lc \
    -fno-entry \
    -freference-trace \
    --verbose-cimport \
    --export=compile_program \
    zig/tcc-wasm.zig \
    fs_romfs.o \
    fs_romfsutil.o \
    tcc.o

  ## Dump our Linked WebAssembly
  # wasm-objdump -h tcc-wasm.wasm
  # wasm-objdump -x tcc-wasm.wasm >/tmp/tcc-wasm.txt

  ## Copy the Linked TCC WebAssembly to the Web Server
  cp tcc-wasm.wasm docs/

  ## Run our Linked WebAssembly
  node zig/test.js
  node zig/test.js | grep "TODO"

  ## Translate tcc.c to Zig
  # zig translate-c \
  #   -target wasm32-freestanding \
  #   -rdynamic \
  #   -lc \
  #   tcc.c \
  #   -DTCC_TARGET_RISCV64 \
  #   -DCONFIG_TCC_CROSSPREFIX="\"riscv64-\""  \
  #   -DCONFIG_TCC_CRTPREFIX="\"/usr/riscv64-linux-gnu/lib\"" \
  #   -DCONFIG_TCC_LIBPATHS="\"{B}:/usr/riscv64-linux-gnu/lib\"" \
  #   -DCONFIG_TCC_SYSINCLUDEPATHS="\"{B}/include:/usr/riscv64-linux-gnu/include\""   \
  #   -DTCC_GITHASH="\"main:b3d10a35\"" \
  #   -I. \
  #   >/tmp/tcc.zig
}

## Test TCC WebAssembly with NuttX QEMU
function test_wasm {
  node zig/test-nuttx.js

  pushd ../nuttx
  cp /tmp/a.out ../apps/bin/
  riscv-none-elf-objdump \
    --syms --source --reloc --demangle --line-numbers --wide \
    --debugging \
    ../apps/bin/a.out
  read -p "Press Enter..."
  # script /tmp/a.log \
    qemu-system-riscv64 \
      -semihosting \
      -M virt,aclint=on \
      -cpu rv64 \
      -smp 8 \
      -bios none \
      -kernel nuttx \
      -nographic
  riscv-none-elf-objdump \
    --syms --source --reloc --demangle --line-numbers --wide \
    --debugging \
    ../apps/bin/a.out
  popd
}

## Go to TCC Folder
pushd ..

## Compile TCC from C to WebAssembly
build_wasm

## Test TCC WebAssembly with NuttX QEMU
test_wasm

## Return to Zig Folder
popd
