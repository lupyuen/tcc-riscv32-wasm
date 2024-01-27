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

1.  Borrow from [foundation-libc](https://github.com/ZigEmbeddedGroup/foundation-libc) and [ziglibc](https://github.com/marler8997/ziglibc)

1.  [Fix malloc()](https://github.com/lupyuen/tcc-riscv32-wasm/commit/e7c76474deb52acadd3540dec0589ab98ae243a9#diff-5ecd8d41f5376644e9c3f17c9eac540841ff6f7c00bca34d7811b54e0b9bd7a0)

1.  [Add getenv()](https://github.com/lupyuen/tcc-riscv32-wasm/commit/c230681899503ea4fe37a3c7ff0031f7018e2e2d)

1.  [Add String Functions](https://github.com/lupyuen/tcc-riscv32-wasm/commit/4ea06f7602471a65539c65c746bfa65c6d1d4184)

1.  [Add open()](https://github.com/lupyuen/tcc-riscv32-wasm/commit/c0095568c3595c09345936b74616b528c99b364e)

1.  [Add sem_init, sem_wait, puts](https://github.com/lupyuen/tcc-riscv32-wasm/commit/99d1d4a19a2530d1972222d0cdea1c52771f537c)

1.  [Increase malloc buffer](https://github.com/lupyuen/tcc-riscv32-wasm/commit/765bc8b1313d579f9e8975ec57e949408385ae6e)

1.  [Add sscanf](https://github.com/lupyuen/tcc-riscv32-wasm/commit/abf18acd6053b852363afa9adefcc81501f334ed)

1.  [Add vsnprintf and fflush](https://github.com/lupyuen/tcc-riscv32-wasm/commit/c76b671e771d6ba4bb62230e1546aeb3e8637850)

1.  [Add fprintf](https://github.com/lupyuen/tcc-riscv32-wasm/commit/36d591ea197eb87eb5f14e9632512cfecc99cbaf)

1.  [Add read](https://github.com/lupyuen/tcc-riscv32-wasm/commit/7fe054b38cb52a289f1f512ba1e4ab07823b2ca4)

1.  [Add sprintf, snprintf](https://github.com/lupyuen/tcc-riscv32-wasm/commit/dd0161168815d570259e08d4bf0370a363e6e6e7)

1.  [Add close, sem_post, unlink](https://github.com/lupyuen/tcc-riscv32-wasm/commit/812eaa10d36bd29b6f4efcc35b09f4899f880d5b)

1.  [Add fdopen](https://github.com/lupyuen/tcc-riscv32-wasm/commit/7380fe18d6d109abb55b473b7b7e53749f92a32b)

1.  [Add fwrite](https://github.com/lupyuen/tcc-riscv32-wasm/commit/865eaa7970193cc1d3d3dbdfb2b1314971cc1d1c)

1.  [Add fputc](https://github.com/lupyuen/tcc-riscv32-wasm/commit/679d28b1020098d5e4e81f4646611f26270374a7)

1.  [Add fclose](https://github.com/lupyuen/tcc-riscv32-wasm/commit/455724992a92bcc2c6294a0a93612c5a616c1013)

When we run it: TCC compiles `hello.c` and writes to `a.out` yay!

```text
+ node zig/test.js
compile_program
open: path=hello.c, oflag=0, return fd=3
sem_init: sem=tcc-wasm.sem_t@107628, pshared=0, value=1
sem_wait: sem=tcc-wasm.sem_t@107628
TODO: setjmp
TODO: sscanf: str=0.9.27, format=%d.%d.%d
TODO: vsnprintf: size=128, format=#define __TINYC__ %d
TODO: vsnprintf: return str=#define __TINYC__ %d
TODO: vsnprintf: size=107, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=94, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=81, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=196, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=183, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=170, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=157, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=144, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=131, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=118, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=105, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=92, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=335, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=322, format=#define __SIZEOF_POINTER__ %d
TODO: vsnprintf: return str=#define __SIZEOF_POINTER__ %d
TODO: vsnprintf: size=292, format=#define __SIZEOF_LONG__ %d
TODO: vsnprintf: return str=#define __SIZEOF_LONG__ %d
TODO: vsnprintf: size=265, format=#define %s%s
TODO: vsnprintf: return str=#define FIX_vsnprintf
TODO: vsnprintf: size=252, format=#define __STDC_VERSION__ %dL
TODO: vsnprintf: return str=#define __STDC_VERSION__ %dL
TODO: vsnprintf: size=497, format=#define __BASE_FILE__ "%s"
TODO: vsnprintf: return str=#define __BASE_FILE__ "%s"
TODO: vsnprintf: size=128, format=In file included from %s:%d:
TODO: vsnprintf: return str=In file included from %s:%d:
TODO: vsnprintf: size=99, format=%s:%d: 
TODO: vsnprintf: return str=%s:%d: 
TODO: vsnprintf: size=92, format=warning: 
TODO: vsnprintf: return str=warning: 
TODO: vsnprintf: size=83, format=%s redefined
TODO: vsnprintf: return str=%s redefined
fprintf: stream=tcc-wasm.FILE@2, format=%s
read: fd=3, nbyte=8192
read: return buf=int main(int argc, char *argv[]) {
  printf("Hello, World!!\n");
  return 0;
}
TODO: vsnprintf: size=128, format=%s:%d: 
TODO: vsnprintf: return str=%s:%d: 
TODO: vsnprintf: size=121, format=warning: 
TODO: vsnprintf: return str=warning: 
TODO: vsnprintf: size=112, format=implicit declaration of function '%s'
TODO: vsnprintf: return str=implicit declaration of function '%s'
fprintf: stream=tcc-wasm.FILE@2, format=%s
TODO: sprintf: format=L.%u
TODO: sprintf: return str=L.%u
TODO: snprintf: size=256, format=.rela%s
TODO: snprintf: return str=.rela%s
read: fd=3, nbyte=8192
read: return 0
close: fd=3
sem_post: sem=tcc-wasm.sem_t@107628
TODO: snprintf: size=1024, format=%s
TODO: snprintf: return str=%s

unlink: path=a.out
open: path=a.out, oflag=577, return fd=4
fdopen: fd=4, mode=wb, return FILE=5
fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  7F 45 4C 46 02 01 01 00  00 00 00 00 00 00 00 00  .ELF............
  0016:  01 00 F3 00 01 00 00 00  00 00 00 00 00 00 00 00  ................
  0032:  00 00 00 00 00 00 00 00  D0 01 00 00 00 00 00 00  ................
  0048:  04 00 00 00 40 00 00 00  00 00 40 00 09 00 08 00  ....@.....@.....

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  13 01 01 FE 23 3C 11 00  23 38 81 00 13 04 01 02  ....#<..#8......
  0016:  13 00 00 00 23 34 A4 FE  23 30 B4 FE 17 05 00 00  ....#4..#0......
  0032:  13 05 05 00 97 00 00 00  E7 80 00 00 1B 05 00 00  ................
  0048:  83 30 81 01 03 34 01 01  13 01 01 02 67 80 00 00  .0...4......g...

fwrite: size=1, nmemb=16, stream=tcc-wasm.FILE@5
  0000:  48 65 6C 6C 6F 2C 20 57  6F 72 6C 64 21 21 0A 00  Hello, World!!..

fwrite: size=1, nmemb=144, stream=tcc-wasm.FILE@5
  0000:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  01 00 00 00 04 00 F1 FF  ................
  0032:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  0E 00 00 00 01 00 03 00  00 00 00 00 00 00 00 00  ................
  0064:  10 00 00 00 00 00 00 00  00 00 00 00 00 00 01 00  ................
  0080:  1C 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0096:  09 00 00 00 12 00 01 00  00 00 00 00 00 00 00 00  ................
  0112:  40 00 00 00 00 00 00 00  13 00 00 00 12 00 00 00  @...............
  0128:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=26, stream=tcc-wasm.FILE@5
  0000:  00 68 65 6C 6C 6F 2E 63  00 6D 61 69 6E 00 4C 2E  .hello.c.main.L.
  0016:  25 75 00 70 72 69 6E 74  66 00                    %u.printf.

fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fwrite: size=1, nmemb=72, stream=tcc-wasm.FILE@5
  0000:  1C 00 00 00 00 00 00 00  17 00 00 00 02 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  20 00 00 00 00 00 00 00  ........ .......
  0032:  18 00 00 00 03 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  24 00 00 00 00 00 00 00  13 00 00 00 05 00 00 00  $...............
  0064:  00 00 00 00 00 00 00 00                           ........

fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fwrite: size=1, nmemb=61, stream=tcc-wasm.FILE@5
  0000:  00 2E 74 65 78 74 00 2E  64 61 74 61 00 2E 64 61  ..text..data..da
  0016:  74 61 2E 72 6F 00 2E 62  73 73 00 2E 73 79 6D 74  ta.ro..bss..symt
  0032:  61 62 00 2E 73 74 72 74  61 62 00 2E 72 65 6C 61  ab..strtab..rela
  0048:  25 73 00 2E 73 68 73 74  72 74 61 62 00           %s..shstrtab.

fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fputc: c=0x00, stream=tcc-wasm.FILE@5
fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0032:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  01 00 00 00 01 00 00 00  06 00 00 00 00 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  40 00 00 00 00 00 00 00  ........@.......
  0032:  40 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  @...............
  0048:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  07 00 00 00 01 00 00 00  03 00 00 00 00 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  80 00 00 00 00 00 00 00  ................
  0032:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  0D 00 00 00 01 00 00 00  03 00 00 00 00 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  80 00 00 00 00 00 00 00  ................
  0032:  10 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  16 00 00 00 08 00 00 00  03 00 00 00 00 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  90 00 00 00 00 00 00 00  ................
  0032:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  1B 00 00 00 02 00 00 00  00 00 00 00 00 00 00 00  ................
  0016:  00 00 00 00 00 00 00 00  90 00 00 00 00 00 00 00  ................
  0032:  90 00 00 00 00 00 00 00  06 00 00 00 04 00 00 00  ................
  0048:  08 00 00 00 00 00 00 00  18 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  23 00 00 00 03 00 00 00  00 00 00 00 00 00 00 00  #...............
  0016:  00 00 00 00 00 00 00 00  20 01 00 00 00 00 00 00  ........ .......
  0032:  1A 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  01 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  2B 00 00 00 04 00 00 00  00 00 00 00 00 00 00 00  +...............
  0016:  00 00 00 00 00 00 00 00  40 01 00 00 00 00 00 00  ........@.......
  0032:  48 00 00 00 00 00 00 00  05 00 00 00 01 00 00 00  H...............
  0048:  08 00 00 00 00 00 00 00  18 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  33 00 00 00 03 00 00 00  00 00 00 00 00 00 00 00  3...............
  0016:  00 00 00 00 00 00 00 00  90 01 00 00 00 00 00 00  ................
  0032:  3D 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  =...............
  0048:  01 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

close: stream=tcc-wasm.FILE@5
ret=123
```

Also published publicly here (see the JavaScript Console): https://lupyuen.github.io/tcc-riscv32-wasm/

TODO: Verify the generated `a.out`. Didn't we pass `-c` to generate as Object File?

TODO: Need to implement vsnprintf() in C? Or we hardcode the patterns?

`invalid macro name` is caused by `#define %s%s`. We should mock up a valid name for `%s%s`

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
