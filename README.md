# TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler

_TCC is a simple C Compiler for 64-bit RISC-V... Can we run TCC in a Web Browser?_

Let's find out! We'll compile TCC to WebAssembly with Zig Compiler.

(We'll emulate the POSIX File Access with some WebAssembly Mockups)

_Why are we doing this?_

Today we can run [Apache NuttX RTOS in a Web Browser](https://lupyuen.github.io/articles/tinyemu2) (with WebAssembly + Emscripten + 64-bit RISC-V).

What if we could allow NuttX Apps to be compiled and tested in the Web Browser?

1.  We type a C Program into a HTML Textbox...

    ```c
    int main(int argc, char *argv[]) {
      printf("Hello, World!!\n");
      return 0;
    }
    ```

1.  Run TCC in the Web Browser to compile the C Program into an ELF Executable (64-bit RISC-V)

1.  Copy the ELF Executable to the NuttX Filesystem (via WebAssembly)

1.  NuttX runs our ELF Executable inside the Web Browser

Let's verify that TCC will generate 64-bit RISC-V code...

# TCC generates 64-bit RISC-V code

We build TCC to support 64-bit RISC-V Target...

```bash
## Build TCC for 64-bit RISC-V Target
git clone https://github.com/lupyuen/tcc-riscv32-wasm
cd tcc-riscv32-wasm
./configure
make help
make --trace cross-riscv64
./riscv64-tcc -v
```

We compile this C program...

```c
## Simple C Program
int main(int argc, char *argv[]) {
  printf("Hello, World!!\n");
  return 0;
}
```

Like this...

```bash
## Compile C to 64-bit RISC-V
/workspaces/bookworm/tcc-riscv32/riscv64-tcc \
    -c \
    /workspaces/bookworm/apps/examples/hello/hello_main.c

## Dump the 64-bit RISC-V Disassembly
riscv-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  hello_main.o \
  >hello_main.S \
  2>&1
```

The RISC-V Disassembly looks valid, very similar to a [NuttX App](https://lupyuen.github.io/articles/app#inside-a-nuttx-app) (so it will probably run on NuttX)...

```text
hello_main.o:     file format elf64-littleriscv
SYMBOL TABLE:
0000000000000000 l    df *ABS*  0000000000000000 /workspaces/bookworm/apps/examples/hello/hello_m
ain.c
0000000000000000 l     O .data.ro       0000000000000010 L.0
0000000000000000 g     F .text  0000000000000040 main
0000000000000000       F *UND*  0000000000000000 printf

Disassembly of section .text:
0000000000000000 <main>:
main():
   0:   fe010113                add     sp,sp,-32
   4:   00113c23                sd      ra,24(sp)
   8:   00813823                sd      s0,16(sp)
   c:   02010413                add     s0,sp,32
  10:   00000013                nop
  14:   fea43423                sd      a0,-24(s0)
  18:   feb43023                sd      a1,-32(s0)
  1c:   00000517                auipc   a0,0x0  1c: R_RISCV_PCREL_HI20  L.0
  20:   00050513                mv      a0,a0   20: R_RISCV_PCREL_LO12_I        .text
  24:   00000097                auipc   ra,0x0  24: R_RISCV_CALL_PLT    printf
  28:   000080e7                jalr    ra # 24 <main+0x24>
  2c:   0000051b                sext.w  a0,zero
  30:   01813083                ld      ra,24(sp)
  34:   01013403                ld      s0,16(sp)
  38:   02010113                add     sp,sp,32
  3c:   00008067                ret
```

# Compile TCC with Zig Compiler

We compile TCC Compiler with the Zig Compiler. First we figure out the GCC Options...

```bash
## Show the GCC Options
$ make --trace cross-riscv64
gcc \
  -o riscv64-tcc.o \
  -c tcc.c \
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

gcc \
  -o riscv64-tcc riscv64-tcc.o \
  -lm \
  -lpthread \
  -ldl \
  -s \

## Probably won't need this for now
../riscv64-tcc -c lib-arm64.c -o riscv64-lib-arm64.o -B.. -I..
../riscv64-tcc -c stdatomic.c -o riscv64-stdatomic.o -B.. -I..
../riscv64-tcc -c atomic.S -o riscv64-atomic.o -B.. -I..
../riscv64-tcc -c dsohandle.c -o riscv64-dsohandle.o -B.. -I..
../riscv64-tcc -ar rcs ../riscv64-libtcc1.a riscv64-lib-arm64.o riscv64-stdatomic.o riscv64-atomic.o riscv64-dsohandle.o
```

We copy the above GCC Options and we compile TCC with Zig Compiler...

```bash
## Compile TCC with Zig Compiler
export PATH=/workspaces/bookworm/zig-linux-x86_64-0.12.0-dev.2341+92211135f:$PATH
./configure
make --trace cross-riscv64
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

## Test our TCC compiled with Zig Compiler
/workspaces/bookworm/tcc-riscv32/a.out -v

/workspaces/bookworm/tcc-riscv32/a.out -c \
  /workspaces/bookworm/apps/examples/hello/hello_main.c

riscv-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  hello_main.o \
  >hello_main.S \
  2>&1
```

Yep it works OK!

# Compile TCC to WebAssembly with Zig Compiler

Now we compile TCC to WebAssembly.

Zig Compiler doesn't like it, so we [Patch the longjmp / setjmp](https://github.com/lupyuen/tcc-riscv32-wasm/commit/e30454a0eb9916f820d58a7c3e104eeda67988d8). (We probably won't need it unless TCC hits Compiler Errors)

```bash
## Compile TCC from C to WebAssembly
./configure
make --trace cross-riscv64
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

## Dump our Compiled WebAssembly
sudo apt install wabt
wasm-objdump -h tcc.o
wasm-objdump -x tcc.o >/tmp/tcc.txt
```

Yep TCC compiles OK to WebAssembly with Zig Compiler!

# Missing Functions in TCC WebAssembly

We check the Compiled WebAssembly. These POSIX Functions are missing from the Compiled WebAssembly...

```text
$ wasm-objdump -x tcc.o >/tmp/tcc.txt
$ cat /tmp/tcc.txt

Import[75]:
 - memory[0] pages: initial=2 <- env.__linear_memory
 - global[0] i32 mutable=1 <- env.__stack_pointer
 - func[0] sig=1 <env.strcmp> <- env.strcmp
 - func[1] sig=12 <env.memset> <- env.memset
 - func[2] sig=1 <env.getcwd> <- env.getcwd
 - func[3] sig=1 <env.strcpy> <- env.strcpy
 - func[4] sig=2 <env.unlink> <- env.unlink
 - func[5] sig=0 <env.free> <- env.free
 - func[6] sig=6 <env.snprintf> <- env.snprintf
 - func[7] sig=2 <env.getenv> <- env.getenv
 - func[8] sig=2 <env.strlen> <- env.strlen
 - func[9] sig=12 <env.sem_init> <- env.sem_init
 - func[10] sig=2 <env.sem_wait> <- env.sem_wait
 - func[11] sig=1 <env.realloc> <- env.realloc
 - func[12] sig=12 <env.memmove> <- env.memmove
 - func[13] sig=2 <env.malloc> <- env.malloc
 - func[14] sig=12 <env.fprintf> <- env.fprintf
 - func[15] sig=2 <env.puts> <- env.puts
 - func[16] sig=0 <env.exit> <- env.exit
 - func[17] sig=2 <env.sem_post> <- env.sem_post
 - func[18] sig=1 <env.strchr> <- env.strchr
 - func[19] sig=1 <env.strrchr> <- env.strrchr
 - func[20] sig=6 <env.vsnprintf> <- env.vsnprintf
 - func[21] sig=1 <env.printf> <- env.printf
 - func[22] sig=2 <env.fflush> <- env.fflush
 - func[23] sig=12 <env.memcpy> <- env.memcpy
 - func[24] sig=12 <env.memcmp> <- env.memcmp
 - func[25] sig=12 <env.sscanf> <- env.sscanf
 - func[26] sig=1 <env.fputs> <- env.fputs
 - func[27] sig=2 <env.close> <- env.close
 - func[28] sig=12 <env.open> <- env.open
 - func[29] sig=18 <env.lseek> <- env.lseek
 - func[30] sig=12 <env.read> <- env.read
 - func[31] sig=12 <env.strtol> <- env.strtol
 - func[32] sig=2 <env.atoi> <- env.atoi
 - func[33] sig=19 <env.strtoull> <- env.strtoull
 - func[34] sig=12 <env.strtoul> <- env.strtoul
 - func[35] sig=1 <env.strstr> <- env.strstr
 - func[36] sig=1 <env.fopen> <- env.fopen
 - func[37] sig=12 <env.sprintf> <- env.sprintf
 - func[38] sig=2 <env.fclose> <- env.fclose
 - func[39] sig=12 <env.fseek> <- env.fseek
 - func[40] sig=2 <env.ftell> <- env.ftell
 - func[41] sig=6 <env.fread> <- env.fread
 - func[42] sig=6 <env.fwrite> <- env.fwrite
 - func[43] sig=2 <env.remove> <- env.remove
 - func[44] sig=1 <env.gettimeofday> <- env.gettimeofday
 - func[45] sig=1 <env.fdopen> <- env.fdopen
 - func[46] sig=12 <env.strncpy> <- env.strncpy
 - func[47] sig=24 <env.__extendsftf2> <- env.__extendsftf2
 - func[48] sig=25 <env.__extenddftf2> <- env.__extenddftf2
 - func[49] sig=9 <env.__floatunditf> <- env.__floatunditf
 - func[50] sig=3 <env.__floatunsitf> <- env.__floatunsitf
 - func[51] sig=26 <env.__trunctfsf2> <- env.__trunctfsf2
 - func[52] sig=27 <env.__trunctfdf2> <- env.__trunctfdf2
 - func[53] sig=28 <env.__netf2> <- env.__netf2
 - func[54] sig=29 <env.__fixunstfdi> <- env.__fixunstfdi
 - func[55] sig=30 <env.__subtf3> <- env.__subtf3
 - func[56] sig=30 <env.__multf3> <- env.__multf3
 - func[57] sig=28 <env.__eqtf2> <- env.__eqtf2
 - func[58] sig=30 <env.__divtf3> <- env.__divtf3
 - func[59] sig=30 <env.__addtf3> <- env.__addtf3
 - func[60] sig=2 <env.strerror> <- env.strerror
 - func[61] sig=1 <env.fputc> <- env.fputc
 - func[62] sig=1 <env.strcat> <- env.strcat
 - func[63] sig=12 <env.strncmp> <- env.strncmp
 - func[64] sig=31 <env.ldexp> <- env.ldexp
 - func[65] sig=32 <env.strtof> <- env.strtof
 - func[66] sig=8 <env.strtold> <- env.strtold
 - func[67] sig=33 <env.strtod> <- env.strtod
 - func[68] sig=2 <env.time> <- env.time
 - func[69] sig=2 <env.localtime> <- env.localtime
 - func[70] sig=13 <env.qsort> <- env.qsort
 - func[71] sig=19 <env.strtoll> <- env.strtoll
 - table[0] type=funcref initial=4 <- env.__indirect_function_table
```

TODO: How to fix these missing POSIX Functions for WebAssembly (Web Browser)

TODO: Do we need all of them? Maybe we run in a Web Browser and see what crashes? [Similar to this](https://lupyuen.github.io/articles/lvgl3)

# Test the TCC WebAssembly with NodeJS

We link our Compiled WebAssembly `tcc.o` with our Zig App: [zig/tcc-wasm.zig](zig/tcc-wasm.zig)

```bash
## Compile our Zig App `tcc-wasm.zig` for WebAssembly
## and link with TCC compiled for WebAssembly
zig build-exe \
  --verbose-cimport \
  -target wasm32-freestanding \
  -rdynamic \
  -lc \
  -fno-entry \
  --export=compile_program \
  zig/tcc-wasm.zig \
  tcc.o

## Dump our Linked WebAssembly
wasm-objdump -h tcc-wasm.wasm
wasm-objdump -x tcc-wasm.wasm >/tmp/tcc-wasm.txt

## Run our Linked WebAssembly
## Shows: ret=123
node zig/test.js
```

Yep it runs OK and prints `123`, with our NodeJS Script: [zig/test.js](zig/test.js)

```javascript
const fs = require('fs');
const source = fs.readFileSync("./tcc-wasm.wasm");
const typedArray = new Uint8Array(source);

WebAssembly.instantiate(typedArray, {
  env: {
    print: (result) => { console.log(`The result is ${result}`); }
  }}).then(result => {
  const compile_program = result.instance.exports.compile_program;
  const ret = compile_program();
  console.log(`ret=${ret}`);
});
```

# Test the TCC WebAssembly in a Web Browser

We test the TCC WebAssembly in a Web Browser with [docs/index.html](docs/index.html) and [docs/tcc.js](docs/tcc.js)...

```bash
## Start the Web Server
cargo install simple-http-server
simple-http-server ./docs &

## Copy the Linked TCC WebAssembly to the Web Server
cp tcc-wasm.wasm docs/
```

Browse to...

```text
http://localhost:8000/index.html
```

Open the JavaScript Console. Yep our TCC WebAssembly runs OK in a Web Browser!

```text
main: start
ret=123
main: end
```

Also published publicly here (see the JavaScript Console): https://lupyuen.github.io/tcc-riscv32-wasm/

# Fix the Missing Functions

When we call `main()` in our Zig App: [zig/tcc-wasm.zig](zig/tcc-wasm.zig)

We see many many Undefined Symbols...

```text
+ zig build-exe --verbose-cimport -target wasm32-freestanding -rdynamic -lc -fno-entry --export=compile_program zig/tcc-wasm.zig tcc.o
error: wasm-ld: tcc.o: undefined symbol: realloc
error: wasm-ld: tcc.o: undefined symbol: free
error: wasm-ld: tcc.o: undefined symbol: snprintf
[...many many more...]
```

So we stubbed them in our Zig App: [zig/tcc-wasm.zig](zig/tcc-wasm.zig)

```zig
/// Fix the Missing Variables
pub export var errno: c_int = 0;
pub export var stdout: c_int = 1;
pub export var stderr: c_int = 2;

/// Fix the Missing Functions
pub export fn atoi(_: c_int) c_int {
    @panic("TODO: atoi");
}
pub export fn close(_: c_int) c_int {
    @panic("TODO: close");
}
[...many many more...]
```

Then we...

- Borrow from [foundation-libc](https://github.com/ZigEmbeddedGroup/foundation-libc) and [ziglibc](https://github.com/marler8997/ziglibc)

- [Fixed malloc()](https://github.com/lupyuen/tcc-riscv32-wasm/commit/e7c76474deb52acadd3540dec0589ab98ae243a9#diff-5ecd8d41f5376644e9c3f17c9eac540841ff6f7c00bca34d7811b54e0b9bd7a0)

- [Added getenv()](https://github.com/lupyuen/tcc-riscv32-wasm/commit/c230681899503ea4fe37a3c7ff0031f7018e2e2d)

- [Added String Functions](https://github.com/lupyuen/tcc-riscv32-wasm/commit/4ea06f7602471a65539c65c746bfa65c6d1d4184)

- [Added open()](https://github.com/lupyuen/tcc-riscv32-wasm/commit/c0095568c3595c09345936b74616b528c99b364e)

When we run it, open() tries to open `hello.c` yay!

```text
+ node zig/test.js
compile_program
open: path=hello.c, oflag=0, return fd=3
wasm://wasm/0064055a:1
RuntimeError: unreachable
    at signature_mismatch:sem_init (wasm://wasm/0064055a:wasm-function[27]:0x61c)
    at tcc_compile (wasm://wasm/0064055a:wasm-function[69]:0xe267)
    at tcc_add_file_internal (wasm://wasm/0064055a:wasm-function[109]:0x23eba)
    at tcc_add_file (wasm://wasm/0064055a:wasm-function[110]:0x24833)
    at main (wasm://wasm/0064055a:wasm-function[131]:0x2959c)
    at compile_program (wasm://wasm/0064055a:wasm-function[262]:0x4e3f6)
    at /workspaces/bookworm/tcc-riscv32-wasm/zig/test.js:52:15
```

Also published publicly here (see the JavaScript Console): https://lupyuen.github.io/tcc-riscv32-wasm/

TODO: Implement sem_init()

# Analysis of Missing Functions

TCC calls surprisingly few External Functions! We might get it running on WebAssembly. Here's our analysis of the Missing Functions: [zig/tcc-wasm.zig](zig/tcc-wasm.zig)

## Semaphore Functions

TODO: Borrow from where?

- sem_init, sem_post, sem_wait

## Standard Library

TODO: Borrow qsort from where?

- exit, qsort

## Time Functions

TODO: Borrow from where?

- time, gettimeofday, localtime

## Math Functions

TODO: Borrow from where?

- ldexp

## Varargs Functions

Will be tricky to implement in Zig

- printf, snprintf, sprintf, vsnprintf
- sscanf

## Filesystem Functions

Will mock up these functions for WebAssembly

- getcwd
- remove, unlink

## File I/O Functions

Will mock up these functions for WebAssembly. We will read only 1 simple C Source File, and produce only 1 Object File. No header files, no libraries. (Should be mockable)

- open, fopen, fdopen, 
- close, fclose
- fprintf, fputc, fputs
- read, fread
- fwrite
- fflush
- fseek, ftell, lseek
- puts

## String Functions

Borrow from [foundation-libc](https://github.com/ZigEmbeddedGroup/foundation-libc) and [ziglibc](https://github.com/marler8997/ziglibc)

- atoi
- strcat, strchr, strcmp
- strncmp, strncpy, strrchr
- strstr, strtod, strtof
- strtol, strtold, strtoll
- strtoul, strtoull
- strerror
