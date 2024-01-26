# TCC RISC-V Compiler compiled to WebAssembly with Zig Compiler

TODO

```bash
./configure
make help
make --trace cross-riscv64
./riscv64-tcc -v
/workspaces/bookworm/tcc-riscv32/riscv64-tcc -c /workspaces/bookworm/apps/examples/hello/hello_main.c
riscv-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  hello_main.o \
  >hello_main.S \
  2>&1

gcc
  -o riscv64-tcc.o
  -c tcc.c
  -DTCC_TARGET_RISCV64
  -DCONFIG_TCC_CROSSPREFIX="\"riscv64-\"" 
  -DCONFIG_TCC_CRTPREFIX="\"/usr/riscv64-linux-gnu/lib\""
  -DCONFIG_TCC_LIBPATHS="\"{B}:/usr/riscv64-linux-gnu/lib\""
  -DCONFIG_TCC_SYSINCLUDEPATHS="\"{B}/include:/usr/riscv64-linux-gnu/include\""  
  -DTCC_GITHASH="\"main:b3d10a35\""
  -Wall
  -O2
  -Wdeclaration-after-statement
  -fno-strict-aliasing
  -Wno-pointer-sign
  -Wno-sign-compare
  -Wno-unused-result
  -Wno-format-truncation
  -Wno-stringop-truncation
  -I. 

gcc
  -o riscv64-tcc riscv64-tcc.o
  -lm
  -lpthread
  -ldl
  -s

../riscv64-tcc -c lib-arm64.c -o riscv64-lib-arm64.o -B.. -I..
../riscv64-tcc -c stdatomic.c -o riscv64-stdatomic.o -B.. -I..
../riscv64-tcc -c atomic.S -o riscv64-atomic.o -B.. -I..
../riscv64-tcc -c dsohandle.c -o riscv64-dsohandle.o -B.. -I..
../riscv64-tcc -ar rcs ../riscv64-libtcc1.a riscv64-lib-arm64.o riscv64-stdatomic.o riscv64-atomic.o riscv64-dsohandle.o

export PATH=/workspaces/bookworm/zig-linux-x86_64-0.12.0-dev.2341+92211135f:$PATH

zig cc \
  tcc.c \
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
  -I.

/workspaces/bookworm/tcc-riscv32/a.out -v
/workspaces/bookworm/tcc-riscv32/a.out -c /workspaces/bookworm/apps/examples/hello/hello_main.c
riscv-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  hello_main.o \
  >hello_main.S \
  2>&1

## Compile TCC from C to WebAssembly
zig cc \
  -c \
  -target wasm32-freestanding \
  -dynamic \
  -rdynamic \
  -lc \
  tcc.c \
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
  -I.
sudo apt install wabt
wasm-objdump -h tcc.o
wasm-objdump -x tcc.o >/tmp/tcc.txt
```

