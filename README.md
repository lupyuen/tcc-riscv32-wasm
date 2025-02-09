![TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler](https://lupyuen.github.io/images/romfs-title.png)

[(Try the __Online Demo__)](https://lupyuen.github.io/tcc-riscv32-wasm/romfs)

[(Watch the __Demo on YouTube__)](https://youtu.be/sU69bUyrgN8)

# TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler

Read the articles...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

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

![TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler](https://lupyuen.github.io/images/tcc-title.png)

[(Try the __Online Demo__)](https://lupyuen.github.io/tcc-riscv32-wasm/)

# TCC generates 64-bit RISC-V code

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

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

The RISC-V Disassembly looks valid, very similar to a [NuttX App](https://lupyuen.github.io/articles/app#inside-a-nuttx-app) (so it will probably run on NuttX): [hello_main.S](https://gist.github.com/lupyuen/46ffc9481c79e36274c0980f9d58f806)

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

See the Object File: [hello_main.o](https://gist.github.com/lupyuen/ac600d793a60b1e7f6ac95918580f266)

# Compile TCC with Zig Compiler

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

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

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

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

![Compile TCC to WebAssembly with Zig Compiler](https://lupyuen.github.io/images/tcc-zig.jpg)

# Missing Functions in TCC WebAssembly

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

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

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

We link our Compiled WebAssembly `tcc.o` with our Zig App: [zig/tcc-wasm.zig](zig/tcc-wasm.zig)

```bash
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

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

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

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

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

1.  [Add fputs](https://github.com/lupyuen/tcc-riscv32-wasm/commit/547759dcf9b991c3b49737e24133b45c47dfd378)

1.  [Change `L.%u` to `L.0`, `.rela%s` to `.rela.text`](https://github.com/lupyuen/tcc-riscv32-wasm/commit/3c8e4337a66e77d06877f7b1606db71139560104)

1.  [Dump the `a.out` file](https://github.com/lupyuen/tcc-riscv32-wasm/commit/a6602a602293addfeb9ce548b9a3aacb62127c5f)

# TCC WebAssembly runs OK in a Web Browser!

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

When we run it in a [Web Browser](https://lupyuen.github.io/tcc-riscv32-wasm/): TCC compiles `hello.c` and writes to `a.out` yay!

```text
+ node zig/test.js
compile_program
open: path=hello.c, oflag=0, return fd=3
sem_init: sem=tcc-wasm.sem_t@107678, pshared=0, value=1
sem_wait: sem=tcc-wasm.sem_t@107678
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
TODO: sprintf: return str=L.0
TODO: snprintf: size=256, format=.rela%s
TODO: snprintf: return str=.rela.text
read: fd=3, nbyte=8192
read: return 0
close: fd=3
sem_post: sem=tcc-wasm.sem_t@107678
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
  0112:  40 00 00 00 00 00 00 00  12 00 00 00 12 00 00 00  @...............
  0128:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=25, stream=tcc-wasm.FILE@5
  0000:  00 68 65 6C 6C 6F 2E 63  00 6D 61 69 6E 00 4C 2E  .hello.c.main.L.
  0016:  30 00 70 72 69 6E 74 66  00                       0.printf.

fputc: c=0x00, stream=tcc-wasm.FILE@5
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
fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  00 2E 74 65 78 74 00 2E  64 61 74 61 00 2E 64 61  ..text..data..da
  0016:  74 61 2E 72 6F 00 2E 62  73 73 00 2E 73 79 6D 74  ta.ro..bss..symt
  0032:  61 62 00 2E 73 74 72 74  61 62 00 2E 72 65 6C 61  ab..strtab..rela
  0048:  2E 74 65 78 74 00 2E 73  68 73 74 72 74 61 62 00  .text..shstrtab.

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
  0032:  19 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0048:  01 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  2B 00 00 00 04 00 00 00  00 00 00 00 00 00 00 00  +...............
  0016:  00 00 00 00 00 00 00 00  40 01 00 00 00 00 00 00  ........@.......
  0032:  48 00 00 00 00 00 00 00  05 00 00 00 01 00 00 00  H...............
  0048:  08 00 00 00 00 00 00 00  18 00 00 00 00 00 00 00  ................

fwrite: size=1, nmemb=64, stream=tcc-wasm.FILE@5
  0000:  36 00 00 00 03 00 00 00  00 00 00 00 00 00 00 00  6...............
  0016:  00 00 00 00 00 00 00 00  90 01 00 00 00 00 00 00  ................
  0032:  40 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  @...............
  0048:  01 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

close: stream=tcc-wasm.FILE@5
a.out: 1040 bytes
  0000:  7F 45 4C 46 02 01 01 00  00 00 00 00 00 00 00 00  .ELF............
  0016:  01 00 F3 00 01 00 00 00  00 00 00 00 00 00 00 00  ................
  0032:  00 00 00 00 00 00 00 00  D0 01 00 00 00 00 00 00  ................
  0048:  04 00 00 00 40 00 00 00  00 00 40 00 09 00 08 00  ....@.....@.....
  0064:  13 01 01 FE 23 3C 11 00  23 38 81 00 13 04 01 02  ....#<..#8......
  0080:  13 00 00 00 23 34 A4 FE  23 30 B4 FE 17 05 00 00  ....#4..#0......
  0096:  13 05 05 00 97 00 00 00  E7 80 00 00 1B 05 00 00  ................
  0112:  83 30 81 01 03 34 01 01  13 01 01 02 67 80 00 00  .0...4......g...
  0128:  48 65 6C 6C 6F 2C 20 57  6F 72 6C 64 21 21 0A 00  Hello, World!!..
  0144:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0160:  00 00 00 00 00 00 00 00  01 00 00 00 04 00 F1 FF  ................
  0176:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0192:  0E 00 00 00 01 00 03 00  00 00 00 00 00 00 00 00  ................
  0208:  10 00 00 00 00 00 00 00  00 00 00 00 00 00 01 00  ................
  0224:  1C 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0240:  09 00 00 00 12 00 01 00  00 00 00 00 00 00 00 00  ................
  0256:  40 00 00 00 00 00 00 00  12 00 00 00 12 00 00 00  @...............
  0272:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0288:  00 68 65 6C 6C 6F 2E 63  00 6D 61 69 6E 00 4C 2E  .hello.c.main.L.
  0304:  30 00 70 72 69 6E 74 66  00 00 00 00 00 00 00 00  0.printf........
  0320:  1C 00 00 00 00 00 00 00  17 00 00 00 02 00 00 00  ................
  0336:  00 00 00 00 00 00 00 00  20 00 00 00 00 00 00 00  ........ .......
  0352:  18 00 00 00 03 00 00 00  00 00 00 00 00 00 00 00  ................
  0368:  24 00 00 00 00 00 00 00  13 00 00 00 05 00 00 00  $...............
  0384:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0400:  00 2E 74 65 78 74 00 2E  64 61 74 61 00 2E 64 61  ..text..data..da
  0416:  74 61 2E 72 6F 00 2E 62  73 73 00 2E 73 79 6D 74  ta.ro..bss..symt
  0432:  61 62 00 2E 73 74 72 74  61 62 00 2E 72 65 6C 61  ab..strtab..rela
  0448:  2E 74 65 78 74 00 2E 73  68 73 74 72 74 61 62 00  .text..shstrtab.
  0464:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0480:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0496:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0512:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0528:  01 00 00 00 01 00 00 00  06 00 00 00 00 00 00 00  ................
  0544:  00 00 00 00 00 00 00 00  40 00 00 00 00 00 00 00  ........@.......
  0560:  40 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  @...............
  0576:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0592:  07 00 00 00 01 00 00 00  03 00 00 00 00 00 00 00  ................
  0608:  00 00 00 00 00 00 00 00  80 00 00 00 00 00 00 00  ................
  0624:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0640:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0656:  0D 00 00 00 01 00 00 00  03 00 00 00 00 00 00 00  ................
  0672:  00 00 00 00 00 00 00 00  80 00 00 00 00 00 00 00  ................
  0688:  10 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0704:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0720:  16 00 00 00 08 00 00 00  03 00 00 00 00 00 00 00  ................
  0736:  00 00 00 00 00 00 00 00  90 00 00 00 00 00 00 00  ................
  0752:  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0768:  08 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0784:  1B 00 00 00 02 00 00 00  00 00 00 00 00 00 00 00  ................
  0800:  00 00 00 00 00 00 00 00  90 00 00 00 00 00 00 00  ................
  0816:  90 00 00 00 00 00 00 00  06 00 00 00 04 00 00 00  ................
  0832:  08 00 00 00 00 00 00 00  18 00 00 00 00 00 00 00  ................
  0848:  23 00 00 00 03 00 00 00  00 00 00 00 00 00 00 00  #...............
  0864:  00 00 00 00 00 00 00 00  20 01 00 00 00 00 00 00  ........ .......
  0880:  19 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0896:  01 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................
  0912:  2B 00 00 00 04 00 00 00  00 00 00 00 00 00 00 00  +...............
  0928:  00 00 00 00 00 00 00 00  40 01 00 00 00 00 00 00  ........@.......
  0944:  48 00 00 00 00 00 00 00  05 00 00 00 01 00 00 00  H...............
  0960:  08 00 00 00 00 00 00 00  18 00 00 00 00 00 00 00  ................
  0976:  36 00 00 00 03 00 00 00  00 00 00 00 00 00 00 00  6...............
  0992:  00 00 00 00 00 00 00 00  90 01 00 00 00 00 00 00  ................
  1008:  40 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  @...............
  1024:  01 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  ................

ret=1040
```

Also published publicly here (see the JavaScript Console): https://lupyuen.github.io/tcc-riscv32-wasm/

TODO: Check our WebAssembly with [Modsurfer](https://github.com/dylibso/modsurfer)

TODO: Need to implement vsnprintf() in C? Or we hardcode the patterns?

TODO: Didn't we pass the TCC Option `-c` to generate as Object File? Why is the output `a.out`?

Note: `invalid macro name` is caused by `#define %s%s`. We should mock up a valid name for `%s%s`

![TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler](https://lupyuen.github.io/images/tcc-title.png)

[_(Try the __Online Demo__)_](https://lupyuen.github.io/tcc-riscv32-wasm/)

# Verify the TCC Output

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

Let's verify the generated `a.out`.

We copy the above `a.out` Hex Dump into a Text File: [a.txt](https://gist.github.com/lupyuen/fd78742847b146c6eea5dfcff0d932f7)

Then we decompile it...

```bash
## Convert a.txt to a.out
cat a.txt \
  | cut --bytes=10-58 \
  | xxd -revert -plain \
  >a.out

## Decompile the a.out to RISC-V Disassembly a.S
riscv-none-elf-objdump \
  --syms --source --reloc --demangle --line-numbers --wide \
  --debugging \
  a.out \
  >a.S \
  2>&1
```

And the Decompiled RISC-V Disassembly looks correct! [a.S](https://gist.github.com/lupyuen/9a9fe3a7c061503f33752221dcb0992c)

```text
main():
   0:	fe010113          	add	sp,sp,-32
   4:	00113c23          	sd	ra,24(sp)
   8:	00813823          	sd	s0,16(sp)
   c:	02010413          	add	s0,sp,32
  10:	00000013          	nop
  14:	fea43423          	sd	a0,-24(s0)
  18:	feb43023          	sd	a1,-32(s0)
  1c:	00000517          	auipc	a0,0x0	1c: R_RISCV_PCREL_HI20	L.0
  20:	00050513          	mv	a0,a0	20: R_RISCV_PCREL_LO12_I	.text
  24:	00000097          	auipc	ra,0x0	24: R_RISCV_CALL_PLT	printf
  28:	000080e7          	jalr	ra # 24 <main+0x24>
  2c:	0000051b          	sext.w	a0,zero
  30:	01813083          	ld	ra,24(sp)
  34:	01013403          	ld	s0,16(sp)
  38:	02010113          	add	sp,sp,32
  3c:	00008067          	ret
```

Very similar to [hello_main.S](https://gist.github.com/lupyuen/46ffc9481c79e36274c0980f9d58f806)

So yes TCC runs correctly in a Web Browser. With some limitations and lots of hacking! Yay!

![TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler](https://lupyuen.github.io/images/tcc-web.png)

[_(Try the __Online Demo__)_](https://lupyuen.github.io/tcc-riscv32-wasm/)

# Fix the Varargs Functions

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

_Why is fprintf particularly problematic?_

Here's the fearsome thing about __fprintf__ and friends: __sprintf, snprintf, vsnprintf__...

- __C Format Strings__ are difficult to parse

- __Variable Number of Untyped Arguments__ might create Bad Pointers

Hence we hacked up an implementation of __String Formatting__ that's safer, simpler and so-barebones-you-can-make-_soup-tulang_.

![Fix the Varargs Functions](https://lupyuen.github.io/images/tcc-format.jpg)

_Soup tulang? Tell me more..._

Our Zig Wrapper uses __Pattern Matching__ to match the __C Formats__ and substitute the __Zig Equivalent__: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/main/zig/tcc-wasm.zig#L191-L209)

```zig
/// Pattern Matching for String Formatting: We will match these patterns when formatting strings
const format_patterns = [_]FormatPattern{
    // Format a Single `%d`, like `#define __TINYC__ %d`
    FormatPattern{ .c_spec = "%d", .zig_spec = "{}", .type0 = c_int, .type1 = null },

    // Format a Single `%u`, like `L.%u`
    FormatPattern{ .c_spec = "%u", .zig_spec = "{}", .type0 = c_int, .type1 = null },

    // Format a Single `%s`, like `#define __BASE_FILE__ "%s"` or `.rela%s`
    FormatPattern{ .c_spec = "%s", .zig_spec = "{s}", .type0 = [*:0]const u8, .type1 = null },

    // Format Two `%s`, like `#define %s%s\n`
    FormatPattern{ .c_spec = "%s%s", .zig_spec = "{s}{s}", .type0 = [*:0]const u8, .type1 = [*:0]const u8 },

    // Format `%s:%d`, like `%s:%d: `
    FormatPattern{ .c_spec = "%s:%d", .zig_spec = "{s}:{}", .type0 = [*:0]const u8, .type1 = c_int },
};
```

We use `comptime` functions in Zig to implement the C String Formatting: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/main/zig/tcc-wasm.zig#L276-L326)

```zig
/// CompTime Function to format a string by Pattern Matching.
/// Format a Single Specifier, like `#define __BASE_FILE__ "%s"`
/// If the Spec matches the Format: Return the number of bytes written to `str`, excluding terminating null.
/// Else return 0.
fn format_string1(
    ap: *std.builtin.VaList,
    str: [*]u8,
    size: size_t,
    format: []const u8, // Like `#define %s%s\n`
    comptime c_spec: []const u8, // Like `%s%s`
    comptime zig_spec: []const u8, // Like `{s}{s}`
    comptime T0: type, // Like `[*:0]const u8`
) usize {
    // Count the Format Specifiers: `%`
    const spec_cnt = std.mem.count(u8, c_spec, "%");
    const format_cnt = std.mem.count(u8, format, "%");

    // Check the Format Specifiers: `%`
    if (format_cnt != spec_cnt or // Quit if the number of specifiers are different
        !std.mem.containsAtLeast(u8, format, 1, c_spec)) // Or if the specifiers are not found
    {
        return 0;
    }

    // Fetch the args
    const a = @cVaArg(ap, T0);
    if (T0 == c_int) {
        debug("format_string1: size={}, format={s}, a={}", .{ size, format, a });
    } else {
        debug("format_string1: size={}, format={s}, a={s}", .{ size, format, a });
    }

    // Format the string. TODO: Check for overflow
    var buf: [100]u8 = undefined; // Limit to 100 chars
    const buf_slice = std.fmt.bufPrint(&buf, zig_spec, .{a}) catch {
        wasmlog.Console.log("*** format_string1 error: buf too small", .{});
        @panic("*** format_string1 error: buf too small");
    };

    // Replace the Format Specifier
    var buf2 = std.mem.zeroes([100]u8); // Limit to 100 chars
    _ = std.mem.replace(u8, format, c_spec, buf_slice, &buf2);

    // Return the string
    const len = std.mem.indexOfScalar(u8, &buf2, 0).?;
    @memcpy(str[0..len], buf2[0..len]);
    str[len] = 0;
    return len;
}
```

Previously without `comptime`, the implementation of C String Formatting gets very lengthy: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/8df0b4f64d188ff5936225dc545e8387ca512b8d/zig/tcc-wasm.zig#L188-L401)

```zig
export fn vsnprintf(str: [*:0]u8, size: size_t, format: [*:0]const u8, ...) c_int {
    // Count the Format Specifiers: `%`
    const format_slice = std.mem.span(format);
    const format_cnt = std.mem.count(u8, format_slice, "%");

    // TODO: Catch overflow
    if (format_cnt == 0) {
        // If no Format Specifiers: Return the Format, like `warning: `
        debug("vsnprintf: size={}, format={s}, format_cnt={}", .{ size, format, format_cnt });
        _ = memcpy(str, format, strlen(format));
        str[strlen(format)] = 0;
    } else if (format_cnt == 2 and std.mem.containsAtLeast(u8, format_slice, 1, "%s%s")) {
        // Format Two `%s`, like `#define %s%s\n`
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const s0 = @cVaArg(&ap, [*:0]const u8);
        const s1 = @cVaArg(&ap, [*:0]const u8);
        debug("vsnprintf: size={}, format={s}, s0={s}, s1={s}", .{ size, format, s0, s1 });

        // Format the string
        const format2 = "{s}{s}"; // Equivalent to C: `%s%s`
        var buf: [100]u8 = undefined; // Limit to 100 chars
        const buf_slice = std.fmt.bufPrint(&buf, format2, .{ s0, s1 }) catch {
            wasmlog.Console.log("*** vsnprintf error: buf too small", .{});
            @panic("*** vsnprintf error: buf too small");
        };

        // Replace the Format Specifier
        var buf2 = std.mem.zeroes([100]u8); // Limit to 100 chars
        _ = std.mem.replace(u8, format_slice, "%s%s", buf_slice, &buf2);

        // Return the string
        const len = std.mem.indexOfScalar(u8, &buf2, 0).?;
        _ = memcpy(str, &buf2, @intCast(len));
        str[len] = 0;
    } else if (format_cnt == 2 and std.mem.containsAtLeast(u8, format_slice, 1, "%s:%d")) {
      // ...
```

Plus lots lots more of tedious coding! It's a lot simpler now with `comptime` Format Patterns.

Now we can handle all String Formatting correctly in TCC...

```text
+ node zig/test.js
compile_program: start
compile_program: options=["-c","hello.c"]
compile_program: code=
    int main(int argc, char *argv[]) {
      printf("Hello, World!!\n");
      return 0;
    }

compile_program: options[0]=-c
compile_program: options[1]=hello.c
open: path=hello.c, oflag=0, return fd=3
sem_init: sem=tcc-wasm.sem_t@10cfe8, pshared=0, value=1
sem_wait: sem=tcc-wasm.sem_t@10cfe8
TODO: setjmp
TODO: sscanf: str=0.9.27, format=%d.%d.%d
format_string1: size=128, format=#define __TINYC__ %d, a=1991381505
vsnprintf: return str=#define __TINYC__ 1991381505
format_string2: size=99, format=#define %s%s, a0=__riscv, a1= 1
vsnprintf: return str=#define __riscv 1
format_string2: size=81, format=#define %s%s, a0=__riscv_xlen 64, a1=
vsnprintf: return str=#define __riscv_xlen 64
format_string2: size=185, format=#define %s%s, a0=__riscv_flen 64, a1=
vsnprintf: return str=#define __riscv_flen 64
format_string2: size=161, format=#define %s%s, a0=__riscv_div, a1= 1
vsnprintf: return str=#define __riscv_div 1
format_string2: size=139, format=#define %s%s, a0=__riscv_mul, a1= 1
vsnprintf: return str=#define __riscv_mul 1
format_string2: size=117, format=#define %s%s, a0=__riscv_fdiv, a1= 1
vsnprintf: return str=#define __riscv_fdiv 1
format_string2: size=94, format=#define %s%s, a0=__riscv_fsqrt, a1= 1
vsnprintf: return str=#define __riscv_fsqrt 1
format_string2: size=326, format=#define %s%s, a0=__riscv_float_abi_double, a1= 1
vsnprintf: return str=#define __riscv_float_abi_double 1
format_string2: size=291, format=#define %s%s, a0=__linux__, a1= 1
vsnprintf: return str=#define __linux__ 1
format_string2: size=271, format=#define %s%s, a0=__linux, a1= 1
vsnprintf: return str=#define __linux 1
format_string2: size=253, format=#define %s%s, a0=__unix__, a1= 1
vsnprintf: return str=#define __unix__ 1
format_string2: size=234, format=#define %s%s, a0=__unix, a1= 1
vsnprintf: return str=#define __unix 1
format_string2: size=217, format=#define %s%s, a0=__CHAR_UNSIGNED__, a1= 1
vsnprintf: return str=#define __CHAR_UNSIGNED__ 1
format_string1: size=189, format=#define __SIZEOF_POINTER__ %d, a=8
vsnprintf: return str=#define __SIZEOF_POINTER__ 8
format_string1: size=160, format=#define __SIZEOF_LONG__ %d, a=8
vsnprintf: return str=#define __SIZEOF_LONG__ 8
format_string2: size=134, format=#define %s%s, a0=__STDC__, a1= 1
vsnprintf: return str=#define __STDC__ 1
format_string1: size=115, format=#define __STDC_VERSION__ %dL, a=199901
vsnprintf: return str=#define __STDC_VERSION__ 199901L
format_string1: size=356, format=#define __BASE_FILE__ "%s", a=hello.c
vsnprintf: return str=#define __BASE_FILE__ "hello.c"
read: fd=3, nbyte=8192
read: return buf=
    int main(int argc, char *argv[]) {
      printf("Hello, World!!\n");
      return 0;
    }
  
format_string2: size=128, format=%s:%d: , a0=hello.c, a1=3
vsnprintf: return str=hello.c:3: 
format_string0: size=117, format=warning: 
vsnprintf: return str=warning: 
format_string1: size=108, format=implicit declaration of function '%s', a=printf
vsnprintf: return str=implicit declaration of function 'printf'
format_string1: size=0, format=%s, a=hello.c:3: warning: implicit declaration of function 'printf'
fprintf: stream=tcc-wasm.FILE@2
hello.c:3: warning: implicit declaration of function 'printf'
format_string1: size=0, format=L.%u, a=0
sprintf: return str=L.0
format_string1: size=256, format=.rela%s, a=.text
snprintf: return str=.rela.text
read: fd=3, nbyte=8192
read: return buf=
close: fd=3
sem_post: sem=tcc-wasm.sem_t@10cfe8
format_string1: size=1024, format=%s, a=hello.c
snprintf: return str=hello.c
unlink: path=hello.o
open: path=hello.o, oflag=577, return fd=4
fdopen: fd=4, mode=wb, return FILE=5
...
close: stream=tcc-wasm.FILE@5
a.out: 1040 bytes
```

[(See the Complete Log)](https://gist.github.com/lupyuen/3e650bd6ad72b2e8ee8596858bc94f36)

TODO: Implement sscanf: `str=0.9.27, format=%d.%d.%d`

# Test TCC Output with NuttX

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

_TCC in WebAssembly has compiled our C Program into the ELF Binary `a.out`. What happens when we run it on NuttX?_

Let's run the TCC Output `a.out` on NuttX! We copy `a.out` to NuttX Apps Filesystem...

```bash
mv ~/Downloads/a.out ~/riscv/apps/bin/
chmod +x ~/riscv/apps/bin/*
file  ~/riscv/apps/bin/a.out
ls -l ~/riscv/apps/bin
```

Which shows...

```text
$ file  ~/riscv/apps/bin/a.out
~/riscv/apps/bin/a.out: ELF 64-bit LSB relocatable, UCB RISC-V, version 1 (SYSV), not stripped

$ ls -l ~/riscv/apps/bin
total 4744
-rwxr-xr-x@ 1   1040 Jan 29 09:24 a.out
-rwxr-xr-x  1 200176 Jan 29 09:05 getprime
-rwxr-xr-x  1 119560 Jan 29 09:05 hello
-rwxr-xr-x  1 697368 Jan 29 09:05 init
-rwxr-xr-x  1 703840 Jan 29 09:05 ostest
-rwxr-xr-x  1 694648 Jan 29 09:05 sh
```

In NuttX we enable Binary Loader Logging: `make menuconfig` then select...

- Build Setup > Debug Options > Binary Loader Debug Features > Enable "Binary Loader Error, Warnings and Info"

Then we boot NuttX on QEMU (64-bit RISC-V) and run `a.out` on NuttX...

```text
nsh> a.out
load_absmodule: Loading /system/bin/a.out
elf_loadbinary: Loading file: /system/bin/a.out
elf_init: filename: /system/bin/a.out loadinfo: 0x8020afa8
elf_read: Read 64 bytes from offset 0
elf_dumploadinfo: LOAD_INFO:
elf_dumploadinfo:   textalloc:    00000000
elf_dumploadinfo:   dataalloc:    00000000
elf_dumploadinfo:   textsize:     0
elf_dumploadinfo:   datasize:     0
elf_dumploadinfo:   textalign:    0
elf_dumploadinfo:   dataalign:    0
elf_dumploadinfo:   filelen:      1040
elf_dumploadinfo:   symtabidx:    0
elf_dumploadinfo:   strtabidx:    0

elf_dumploadinfo: ELF Header:
elf_dumploadinfo:   e_ident:      7f 45 4c 46
elf_dumploadinfo:   e_type:       0001
elf_dumploadinfo:   e_machine:    00f3
elf_dumploadinfo:   e_version:    00000001
elf_dumploadinfo:   e_entry:      00000000
elf_dumploadinfo:   e_phoff:      0
elf_dumploadinfo:   e_shoff:      464
elf_dumploadinfo:   e_flags:      00000004
elf_dumploadinfo:   e_ehsize:     64
elf_dumploadinfo:   e_phentsize:  0
elf_dumploadinfo:   e_phnum:      0
elf_dumploadinfo:   e_shentsize:  64
elf_dumploadinfo:   e_shnum:      9
elf_dumploadinfo:   e_shstrndx:   8

elf_load: loadinfo: 0x8020afa8
elf_loadphdrs: No programs(?)
elf_read: Read 576 bytes from offset 464
elf_loadfile: Loaded sections:
elf_read: Read 64 bytes from offset 64
elf_loadfile: 1. 00000000->c0000000
elf_read: Read 0 bytes from offset 128
elf_loadfile: 2. 00000000->c0101000
elf_read: Read 16 bytes from offset 128
elf_loadfile: 3. 00000000->c0101000
elf_loadfile: 4. 00000000->c0101010

elf_dumploadinfo: LOAD_INFO:
elf_dumploadinfo:   textalloc:    c0000000
elf_dumploadinfo:   dataalloc:    c0101000
elf_dumploadinfo:   textsize:     64
elf_dumploadinfo:   datasize:     16
elf_dumploadinfo:   textalign:    8
elf_dumploadinfo:   dataalign:    8
elf_dumploadinfo:   filelen:      1040
elf_dumploadinfo:   symtabidx:    0
elf_dumploadinfo:   strtabidx:    0

elf_dumploadinfo: ELF Header:
elf_dumploadinfo:   e_ident:      7f 45 4c 46
elf_dumploadinfo:   e_type:       0001
elf_dumploadinfo:   e_machine:    00f3
elf_dumploadinfo:   e_version:    00000001
elf_dumploadinfo:   e_entry:      00000000
elf_dumploadinfo:   e_phoff:      0
elf_dumploadinfo:   e_shoff:      464
elf_dumploadinfo:   e_flags:      00000004
elf_dumploadinfo:   e_ehsize:     64
elf_dumploadinfo:   e_phentsize:  0
elf_dumploadinfo:   e_phnum:      0
elf_dumploadinfo:   e_shentsize:  64
elf_dumploadinfo:   e_shnum:      9
elf_dumploadinfo:   e_shstrndx:   8

elf_dumploadinfo: Sections 0:
elf_dumploadinfo:   sh_name:      00000000
elf_dumploadinfo:   sh_type:      00000000
elf_dumploadinfo:   sh_flags:     00000000
elf_dumploadinfo:   sh_addr:      00000000
elf_dumploadinfo:   sh_offset:    0
elf_dumploadinfo:   sh_size:      0
elf_dumploadinfo:   sh_link:      0
elf_dumploadinfo:   sh_info:      0
elf_dumploadinfo:   sh_addralign: 0
elf_dumploadinfo:   sh_entsize:   0

elf_dumploadinfo: Sections 1:
elf_dumploadinfo:   sh_name:      00000001
elf_dumploadinfo:   sh_type:      00000001
elf_dumploadinfo:   sh_flags:     00000006
elf_dumploadinfo:   sh_addr:      c0000000
elf_dumploadinfo:   sh_offset:    64
elf_dumploadinfo:   sh_size:      64
elf_dumploadinfo:   sh_link:      0
elf_dumploadinfo:   sh_info:      0
elf_dumploadinfo:   sh_addralign: 8
elf_dumploadinfo:   sh_entsize:   0

elf_dumploadinfo: Sections 2:
elf_dumploadinfo:   sh_name:      00000007
elf_dumploadinfo:   sh_type:      00000001
elf_dumploadinfo:   sh_flags:     00000003
elf_dumploadinfo:   sh_addr:      c0101000
elf_dumploadinfo:   sh_offset:    128
elf_dumploadinfo:   sh_size:      0
elf_dumploadinfo:   sh_link:      0
elf_dumploadinfo:   sh_info:      0
elf_dumploadinfo:   sh_addralign: 8
elf_dumploadinfo:   sh_entsize:   0

elf_dumploadinfo: Sections 3:
elf_dumploadinfo:   sh_name:      0000000d
elf_dumploadinfo:   sh_type:      00000001
elf_dumploadinfo:   sh_flags:     00000003
elf_dumploadinfo:   sh_addr:      c0101000
elf_dumploadinfo:   sh_offset:    128
elf_dumploadinfo:   sh_size:      16
elf_dumploadinfo:   sh_link:      0
elf_dumploadinfo:   sh_info:      0
elf_dumploadinfo:   sh_addralign: 8
elf_dumploadinfo:   sh_entsize:   0

elf_dumploadinfo: Sections 4:
elf_dumploadinfo:   sh_name:      00000016
elf_dumploadinfo:   sh_type:      00000008
elf_dumploadinfo:   sh_flags:     00000003
elf_dumploadinfo:   sh_addr:      c0101010
elf_dumploadinfo:   sh_offset:    144
elf_dumploadinfo:   sh_size:      0
elf_dumploadinfo:   sh_link:      0
elf_dumploadinfo:   sh_info:      0
elf_dumploadinfo:   sh_addralign: 8
elf_dumploadinfo:   sh_entsize:   0

elf_dumploadinfo: Sections 5:
elf_dumploadinfo:   sh_name:      0000001b
elf_dumploadinfo:   sh_type:      00000002
elf_dumploadinfo:   sh_flags:     00000000
elf_dumploadinfo:   sh_addr:      00000000
elf_dumploadinfo:   sh_offset:    144
elf_dumploadinfo:   sh_size:      144
elf_dumploadinfo:   sh_link:      6
elf_dumploadinfo:   sh_info:      4
elf_dumploadinfo:   sh_addralign: 8
elf_dumploadinfo:   sh_entsize:   24

elf_dumploadinfo: Sections 6:
elf_dumploadinfo:   sh_name:      00000023
elf_dumploadinfo:   sh_type:      00000003
elf_dumploadinfo:   sh_flags:     00000000
elf_dumploadinfo:   sh_addr:      00000000
elf_dumploadinfo:   sh_offset:    288
elf_dumploadinfo:   sh_size:      25
elf_dumploadinfo:   sh_link:      0
elf_dumploadinfo:   sh_info:      0
elf_dumploadinfo:   sh_addralign: 1
elf_dumploadinfo:   sh_entsize:   0

elf_dumploadinfo: Sections 7:
elf_dumploadinfo:   sh_name:      0000002b
elf_dumploadinfo:   sh_type:      00000004
elf_dumploadinfo:   sh_flags:     00000000
elf_dumploadinfo:   sh_addr:      00000000
elf_dumploadinfo:   sh_offset:    320
elf_dumploadinfo:   sh_size:      72
elf_dumploadinfo:   sh_link:      5
elf_dumploadinfo:   sh_info:      1
elf_dumploadinfo:   sh_addralign: 8
elf_dumploadinfo:   sh_entsize:   24

elf_dumploadinfo: Sections 8:
elf_dumploadinfo:   sh_name:      00000036
elf_dumploadinfo:   sh_type:      00000003
elf_dumploadinfo:   sh_flags:     00000000
elf_dumploadinfo:   sh_addr:      00000000
elf_dumploadinfo:   sh_offset:    400
elf_dumploadinfo:   sh_size:      64
elf_dumploadinfo:   sh_link:      0
elf_dumploadinfo:   sh_info:      0
elf_dumploadinfo:   sh_addralign: 1
elf_dumploadinfo:   sh_entsize:   0

elf_read: Read 72 bytes from offset 320
elf_read: Read 24 bytes from offset 192
elf_symvalue: Other: 00000000+c0101000=c0101000
up_relocateadd: PCREL_HI20 at c000001c [00000517] to sym=0x80209030 st_value=c0101000
_calc_imm: offset=1052644: hi=257 lo=-28
elf_read: Read 24 bytes from offset 216
elf_symvalue: Other: 0000001c+c0000000=c000001c
up_relocateadd: PCREL_LO12_I at c0000020 [00050513] to sym=0x80209070 st_value=c000001c
_calc_imm: offset=1052644: hi=257 lo=-28
elf_read: Read 24 bytes from offset 264
elf_read: Read 32 bytes from offset 306
elf_symvalue: SHN_UNDEF: Exported symbol "printf" not found
elf_relocateadd: Section 7 reloc 2: Failed to get value of symbol[5]: -2
elf_loadbinary: Failed to bind symbols program binary: -2
exec_internal: ERROR: Failed to load program 'a.out': -2
nsh: a.out: command not found
nsh> 
```

It says `printf` is missing. Let's fix it...

For Reference: Here's the log for an ELF that loads properly on NuttX: [NuttX ELF Loader Log](https://gist.github.com/lupyuen/847f7adee50499cac5212f2b95d19cd3)

# How NuttX Build links a NuttX App

_`printf` is missing from our TCC Output `a.out`. How does NuttX Build link a NuttX App?_

Let's find out...

```bash
cd apps
rm bin/hello
make --trace import
```

We see the Linker Command that produces the `hello` app...

```text
riscv-none-elf-ld \
  --oformat elf64-littleriscv \
  -e _start \
  -Bstatic \
  -Tapps/import/scripts/gnu-elf.ld \
  -Lapps/import/libs \
  -L "xpack-riscv-none-elf-gcc-13.2.0-2/bin/../lib/gcc/riscv-none-elf/13.2.0/rv64imafdc_zicsr/lp64d" apps/import/startup/crt0.o  hello_main.c.workspaces.bookworm.apps.examples.hello.o \
  --start-group \
  -lmm \
  -lc \
  -lproxies \
  -lgcc apps/libapps.a xpack-riscv-none-elf-gcc-13.2.0-2/bin/../lib/gcc/riscv-none-elf/13.2.0/rv64imafdc_zicsr/lp64d/libgcc.a \
  --end-group \
  -o  apps/bin/hello
```

This says that NuttX Build links NuttX Apps with these libraries...

- `crt0.o`: Start Code [`_start`](https://github.com/apache/nuttx/blob/master/arch/risc-v/src/common/crt0.c#L144-L194)

- `-lmm`: Mmmmm?

- `-lc`: C Library

- `-lproxies`: [NuttX Proxy Functions](https://lupyuen.github.io/articles/app#nuttx-app-calls-nuttx-kernel) for NuttX System Calls

- `-lgcc libgcc.a`: GCC Library

Which are located at `apps/import/libs`...

```text
$ ls -l apps/import/libs
total 18776
-rwxr-xr-x 1 3132730 Jan 29 02:12 libapps.a
-rw-r--r-- 1    1064 Jan 29 01:18 libarch.a
-rw-r--r-- 1 8946828 Jan 29 01:18 libc.a
-rw-r--r-- 1 1462710 Sep 24 08:10 libgcc.a
-rw-r--r-- 1 1276866 Jan 29 01:18 libm.a
-rw-r--r-- 1 1304366 Jan 29 01:18 libmm.a
-rw-r--r-- 1 3086312 Jan 29 01:18 libproxies.a
```

Let's run TCC to link `a.out` with the above libraries...

# Fix Missing `printf` in NuttX App

We run TCC to link `a.out` with the above libraries...

```bash
tcc-riscv32-wasm/riscv64-tcc \
  -nostdlib \
  apps/import/startup/crt0.o \
  apps/bin/a.out \
  apps/import/libs/libmm.a \
  apps/import/libs/libc.a \
  apps/import/libs/libproxies.a \
  apps/import/libs/libgcc.a
```

It says...

```text
tcc: error: Unknown relocation type for got: 60
```

When we remove `libproxies.a`, we don't see the Unknown Relocation Type...

```text
$ tcc-riscv32-wasm/riscv64-tcc \
  -nostdlib \
  apps/import/startup/crt0.o \
  apps/bin/a.out \
  apps/import/libs/libmm.a \
  apps/import/libs/libc.a \
  apps/import/libs/libgcc.a

tcc: error: undefined symbol '_exit'
tcc: error: undefined symbol '_assert'
tcc: error: undefined symbol 'nxsem_destroy'
tcc: error: undefined symbol 'gettid'
tcc: error: undefined symbol 'nxsem_wait'
tcc: error: undefined symbol 'nxsem_trywait'
tcc: error: undefined symbol 'clock_gettime'
tcc: error: undefined symbol 'nxsem_clockwait'
tcc: error: undefined symbol 'nxsem_post'
tcc: error: undefined symbol 'write'
tcc: error: undefined symbol 'lseek'
tcc: error: undefined symbol 'nx_pthread_exit'
```

Why is `libproxies.a` using Relocation Type 60? We dump the Proxy Object File...

```bash
riscv-none-elf-readelf --wide -all nuttx/syscall/PROXY_write.o
```

TODO: Check the [ELF Dump](https://gist.github.com/lupyuen/cb0484ec055a7a7dfa34b8a8a34244ee)

Let's link the Proxy Functions ourselves...

```bash
tcc-riscv32-wasm/riscv64-tcc \
  -nostdlib \
  apps/bin/a.out \
  nuttx/syscall/PROXY__exit.o \
  nuttx/syscall/PROXY__assert.o \
  nuttx/syscall/PROXY_nxsem_destroy.o \
  nuttx/syscall/PROXY_gettid.o \
  nuttx/syscall/PROXY_nxsem_wait.o \
  nuttx/syscall/PROXY_nxsem_trywait.o \
  nuttx/syscall/PROXY_clock_gettime.o \
  nuttx/syscall/PROXY_nxsem_clockwait.o \
  nuttx/syscall/PROXY_nxsem_post.o \
  nuttx/syscall/PROXY_write.o \
  nuttx/syscall/PROXY_lseek.o \
  nuttx/syscall/PROXY_nx_pthread_exit.o \
  apps/import/startup/crt0.o \
  apps/import/libs/libmm.a \
  apps/import/libs/libc.a \
  apps/import/libs/libgcc.a
```

_Does it work?_

Arg nope...

```text
tcc: error: Unknown relocation type for got: 60
```

Now Unknown Relocation Type is coming from `libc.a`. If we remove `libc.a`...

```text
$ tcc-riscv32-wasm/riscv64-tcc \
  -nostdlib \
  apps/import/startup/crt0.o \
  apps/bin/a.out \
  nuttx/syscall/PROXY__exit.o \
  nuttx/syscall/PROXY__assert.o \
  nuttx/syscall/PROXY_nxsem_destroy.o \
  nuttx/syscall/PROXY_gettid.o \
  nuttx/syscall/PROXY_nxsem_wait.o \
  nuttx/syscall/PROXY_nxsem_trywait.o \
  nuttx/syscall/PROXY_clock_gettime.o \
  nuttx/syscall/PROXY_nxsem_clockwait.o \
  nuttx/syscall/PROXY_nxsem_post.o \
  nuttx/syscall/PROXY_write.o \
  nuttx/syscall/PROXY_lseek.o \
  nuttx/syscall/PROXY_nx_pthread_exit.o \
  apps/import/libs/libmm.a

tcc: error: undefined symbol 'printf'
tcc: error: undefined symbol 'exit'
```

_What if we call `write` directly? (Since `write` is a Proxy to NuttX System Call) And stub out `exit`?_

```c
int write(int fildes, const void *buf, int nbyte);

int main(int argc, char *argv[]) {
  const char msg[] = "Hello, World!!\\n";
  write(1, msg, sizeof(msg));
  return 0;
}

void exit(int status) {
  const char msg[] = "TODO: exit\\n";
  write(1, msg, sizeof(msg));
}
```

Still the same sigh...

```text
tcc: error: Unknown relocation type for got: 60
```

Let's skip everything, we link only `a.out`. Since the other modules are causing the Unknown Relocation Type.

We discovered that `a.out` must be Relocatable Code, otherwise it crashes in NuttX. So we add `-r` to TCC Compiler Options in our modified [test.js](https://github.com/lupyuen/tcc-riscv32-wasm/blob/main/zig/test.js#L48-L64)...

```javascript
  // Allocate a String for passing the Compiler Options to Zig
  const options = ["-c", "-r", "hello.c"];
  const options_ptr = allocateString(JSON.stringify(options));

  // Allocate a String for passing Program Code to Zig
  const code_ptr = allocateString(`
    int main(int argc, char *argv[]) {
      return 0;
    }
  `);

  // Call TCC to compile a program
  const ptr = wasm.instance.exports
    .compile_program(options_ptr, code_ptr);
  console.log(`ptr=${ptr}`);
```

And we run `a.out` on NuttX. Now we get an [Instruction Page Fault](https://gist.github.com/lupyuen/a715e4e77c011d610d0b418e97f8bf5d)...

```text
NuttShell (NSH) NuttX-12.4.0
nsh> a.out
...
binfmt_copyargv: args=2 argsize=23
exec_module: Initialize the user heap (heapsize=528384)
riscv_exception: EXCEPTION: Instruction page fault. MCAUSE: 000000000000000c, EPC: 000000008000ad8a, MTVAL: 000000008000ad8a
riscv_exception: PANIC!!! Exception = 000000000000000c
_assert: Current Version: NuttX  12.4.0 f8b0b06b978 Jan 29 2024 01:16:20 risc-v
_assert: Assertion failed panic: at file: common/riscv_exception.c:85 task: /system/bin/init process: /system/bin/init 0xc000001a
up_dump_register: EPC: 000000008000ad8a
```

_Where is the Exception Program Counter 0x8000ad8a?_

0x8000ad8a is actually in NuttX Kernel...

```text
up_task_start():
nuttx/arch/risc-v/src/common/riscv_task_start.c:65
void up_task_start(main_t taskentry, int argc, char *argv[]) {
    8000ad7a:	1141                	add	sp,sp,-16
    8000ad7c:	86b2                	mv	a3,a2
nuttx/arch/risc-v/src/common/riscv_task_start.c:68
  /* Let sys_call3() do all of the work */

  sys_call3(SYS_task_start, (uintptr_t)taskentry, (uintptr_t)argc,
    8000ad7e:	862e                	mv	a2,a1
    8000ad80:	85aa                	mv	a1,a0
    8000ad82:	4511                	li	a0,4
nuttx/arch/risc-v/src/common/riscv_task_start.c:65
    8000ad84:	e406                	sd	ra,8(sp)
nuttx/arch/risc-v/src/common/riscv_task_start.c:68
  sys_call3(SYS_task_start, (uintptr_t)taskentry, (uintptr_t)argc,
    8000ad86:	875f50ef          	jal	800005fa <sys_call0>
nuttx/arch/risc-v/src/common/riscv_task_start.c:71
            (uintptr_t)argv);
  PANIC();
    8000ad8a:	0000e617          	auipc	a2,0xe
```

Maybe NuttX Kernel crashed because our NuttX App terminated without calling `exit()`?

We're guessing: NuttX Apps should NOT simply `ret` to the caller. They should call the NuttX System Call `__exit` to terminate peacefully.

[(As mentioned in `_start`)](https://github.com/apache/nuttx/blob/master/arch/risc-v/src/common/crt0.c#L144-L194)

_But is our NuttX App actually started?_

Let's tweak our code to loop forever, see whether our app actually gets started...

```javascript
  // Allocate a String for passing Program Code to Zig
  const code_ptr = allocateString(`
    int main(int argc, char *argv[]) {
      for (;;) {}
      return 0;
    }
  `);

  // Call TCC to compile a program
  const ptr = wasm.instance.exports
    .compile_program(options_ptr, code_ptr);
  console.log(`ptr=${ptr}`);
```

Yep NuttX hangs when starting our app! Which means our TCC Compiled App is actually started by NuttX yay!

```text
NuttShell (NSH) NuttX-12.4.0
nsh> a.out
...
load_absmodule: Successfully loaded module /system/bin/a.out
binfmt_dumpmodule: Module:
binfmt_dumpmodule:   entrypt:   0xc0000000
binfmt_dumpmodule:   mapped:    0 size=0
binfmt_dumpmodule:   alloc:     0 0 0
binfmt_dumpmodule:   addrenv:   0x80209b80
binfmt_dumpmodule:   stacksize: 2048
binfmt_dumpmodule:   unload:    0
exec_module: Executing a.out
binfmt_copyargv: args=1 argsize=6
binfmt_copyargv: args=2 argsize=23
exec_module: Initialize the user heap (heapsize=528384)
< ...NuttX Hangs... >
```

(NuttX seems to be starting the first thing that appears in `a.out`)

TODO: Unknown Relocation Type may be due to [Thread Local Storage](https://lists.gnu.org/archive/html/tinycc-devel/2020-06/msg00000.html) generated by GCC Compiler?

# ECALL for NuttX System Call

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

_TCC fails to link our NuttX App because of Unknown Relocation Type for printf(). How else can we print something in our NuttX App?_

We can make a [NuttX System Call (ECALL)](https://lupyuen.github.io/articles/app#nuttx-app-calls-nuttx-kernel) to `write(fd, buf, buflen)`.

Directly in our C Code! Like this: [test-nuttx.js](https://github.com/lupyuen/tcc-riscv32-wasm/blob/main/zig/test-nuttx.js#L55-L87)

```c
  int main(int argc, char *argv[])
  {
    // Make NuttX System Call to write(fd, buf, buflen)
    const unsigned int nbr = 61; // SYS_write
    const void *parm1 = 1;       // File Descriptor (stdout)
    const void *parm2 = "Hello, World!!\n"; // Buffer
    const void *parm3 = 15; // Buffer Length

    // Execute ECALL for System Call to NuttX Kernel
    register long r0 asm("a0") = (long)(nbr);
    register long r1 asm("a1") = (long)(parm1);
    register long r2 asm("a2") = (long)(parm2);
    register long r3 asm("a3") = (long)(parm3);
  
    asm volatile
    (
      // ECALL for System Call to NuttX Kernel
      "ecall \n"

      // NuttX needs NOP after ECALL
      ".word 0x0001 \n"

      // Input+Output Registers: None
      // Input-Only Registers: A0 to A3
      // Clobbers the Memory
      :
      : "r"(r0), "r"(r1), "r"(r2), "r"(r3)
      : "memory"
    );
  
    // Loop Forever
    for(;;) {}
    return 0;
  }
```

Why SysCall 61? Because that's the value of `SYS_write` System Call according to `nuttx.S` (the RISC-V Disassembly of NuttX Kernel).

In NuttX we enable System Call Logging: `make menuconfig` then select...

- Build Setup > Debug Options > SYSCALL  Debug Features > Enable "SYSCALL Error, Warnings and Info"

_Does it work?_

Nope we don't see SysCall 61, but we see a SysCall 15 (what?)...

```yaml
NuttShell (NSH) NuttX-12.4.0
nsh> a.out
...
riscv_swint: Entry: regs: 0x8020be10 cmd: 15
up_dump_register: EPC: 00000000c000006c
up_dump_register: A0: 000000000000000f A1: 00000000c0202010 A2: 0000000000000001 A3: 00000000c0202010
up_dump_register: A4: 00000000c0000000 A5: 0000000000000000 A6: 0000000000000000 A7: 0000000000000000
up_dump_register: T0: 0000000000000000 T1: 0000000000000000 T2: 0000000000000000 T3: 0000000000000000
up_dump_register: T4: 0000000000000000 T5: 0000000000000000 T6: 0000000000000000
up_dump_register: S0: 00000000c0202800 S1: 0000000000000000 S2: 0000000000000000 S3: 0000000000000000
up_dump_register: S4: 0000000000000000 S5: 0000000000000000 S6: 0000000000000000 S7: 0000000000000000
up_dump_register: S8: 0000000000000000 S9: 0000000000000000 S10: 0000000000000000 S11: 0000000000000000
up_dump_register: SP: 00000000c02027a0 FP: 00000000c0202800 TP: 0000000000000000 RA: 000000008000adee
riscv_swint: SWInt Return: 7
```

_But the registers A0, A1, A2 and A3 don't look right!_

Let's hardcode Registers A0, A1, A2 and A3 in Machine Code (because TCC won't assemble the `li` instruction): [test-nuttx.js](https://github.com/lupyuen/tcc-riscv32-wasm/blob/main/zig/test-nuttx.js#L55-L87)

```c
// Load 61 to Register A0 (SYS_write)
"addi a0, zero, 61 \n"

// Load 1 to Register A1 (File Descriptor)
"addi a1, zero, 1 \n"

// Load 0xc0101000 to Register A2 (Buffer)
"lui   a2, 0xc0 \n"
"addiw a2, a2, 257 \n"
"slli  a2, a2, 0xc \n"

// Load 15 to Register A3 (Buffer Length)
"addi a3, zero, 15 \n"

// ECALL for System Call to NuttX Kernel
"ecall \n"

// NuttX needs NOP after ECALL
".word 0x0001 \n"
```

(We used this [RISC-V Online Assembler](https://riscvasm.lucasteske.dev/#) to assemble the Machine Code)

When we run this, we see SysCall 61...

```yaml
NuttShell (NSH) NuttX-12.4.0
nsh> a.out
...
riscv_swint: Entry: regs: 0x8020be10 cmd: 61
up_dump_register: EPC: 00000000c0000084
up_dump_register: A0: 000000000000003d A1: 0000000000000001 A2: 00000000c0101000 A3: 000000000000000f
up_dump_register: A4: 00000000c0000000 A5: 0000000000000000 A6: 0000000000000000 A7: 0000000000000000
up_dump_register: T0: 0000000000000000 T1: 0000000000000000 T2: 0000000000000000 T3: 0000000000000000
up_dump_register: T4: 0000000000000000 T5: 0000000000000000 T6: 0000000000000000
up_dump_register: S0: 00000000c0202800 S1: 0000000000000000 S2: 0000000000000000 S3: 0000000000000000
up_dump_register: S4: 0000000000000000 S5: 0000000000000000 S6: 0000000000000000 S7: 0000000000000000
up_dump_register: S8: 0000000000000000 S9: 0000000000000000 S10: 0000000000000000 S11: 0000000000000000
up_dump_register: SP: 00000000c02027a0 FP: 00000000c0202800 TP: 0000000000000000 RA: 000000008000adee
riscv_swint: SWInt Return: 35
Hello, World!!
```

And "Hello, World!!" is printed yay!

_How did we figure out that the buffer is at 0xc0101000?_

We saw this in the NuttX Log...

```yaml
NuttShell (NSH) NuttX-12.4.0
nsh> a.out
...
elf_read: Read 576 bytes from offset 512
elf_loadfile: Loaded sections:
elf_read: Read 154 bytes from offset 64
elf_loadfile: 1. 00000000->c0000000
elf_read: Read 0 bytes from offset 224
elf_loadfile: 2. 00000000->c0101000
elf_read: Read 16 bytes from offset 224
elf_loadfile: 3. 00000000->c0101000
elf_loadfile: 4. 00000000->c0101010
```

Which says that the NuttX ELF Loader copied 16 bytes from our NuttX App Data Section `.data.ro` to 0xc0101000. That's all 15 bytes of "Hello, World!!\n", including the terminating null!

_Something odd about the TCC-generated RISC-V Machine Code?_

The registers seem to be mushed up in the generated RISC-V Machine Code. That's why it was passing value 15 in Register A0. (Supposed to be Register A3)

```text
// Watch how TCC compiles this C Program to RISC-V Assembly...
// register long a0 asm("a0") = 61; // SYS_write
// register long a1 asm("a1") = 1;  // File Descriptor (stdout)
// register long a2 asm("a2") = "Hello, World!!\\n"; // Buffer
// register long a3 asm("a3") = 15; // Buffer Length
// Execute ECALL for System Call to NuttX Kernel
// asm volatile (
// ECALL for System Call to NuttX Kernel
//   "ecall \\n"
//   ".word 0x0001 \\n"

main():
   0:   fc010113                add     sp,sp,-64
   4:   02113c23                sd      ra,56(sp)
   8:   02813823                sd      s0,48(sp)
   c:   04010413                add     s0,sp,64
  10:   00000013                nop
  14:   fea43423                sd      a0,-24(s0)
  18:   feb43023                sd      a1,-32(s0)

// Correct: Load Register A0 with 61 (SYS_write)
  1c:   03d0051b                addw    a0,zero,61
  20:   fca43c23                sd      a0,-40(s0)

// Nope: Load Register A0 with 1?
// Mixed up with Register A1! (Value 1)
  24:   0010051b                addw    a0,zero,1
  28:   fca43823                sd      a0,-48(s0)

// Nope: Load Register A0 with "Hello World"?
// Mixed up with Register A2!
  2c:   00000517                auipc   a0,0x0  2c: R_RISCV_PCREL_HI20  L.0
  30:   00050513                mv      a0,a0   30: R_RISCV_PCREL_LO12_I        .text
  34:   fca43423                sd      a0,-56(s0)

// Nope: Load Register A0 with 15?
// Mixed up with Register A3! (Value 15)
  38:   00f0051b                addw    a0,zero,15
  3c:   fca43023                sd      a0,-64(s0)

// Execute ECALL with Register A0 set to 15.
// Nope A0 should be 1!
  40:   00000073                ecall
  44:   0001                    nop

// Loop Forever
  46:   0000006f                j       46 <main+0x46>
  4a:   03813083                ld      ra,56(sp)
  4e:   03013403                ld      s0,48(sp)
  52:   04010113                add     sp,sp,64
  56:   00008067                ret
```

TODO: Is there a workaround? Do we paste the ECALL Machine Code ourselves?

TODO: Call the NuttX System Call `__exit` to terminate peacefully

![TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler](https://lupyuen.github.io/images/tcc-ecall.png)

# NuttX App runs in a Web Browser!

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

_OK so we can compile NuttX Apps in a Web Browser... But can we run them in a Web Browser?_

Yep! A NuttX App compiled in the Web Browser... Now runs OK with NuttX Emulator in Web Browser! 🎉

[(Watch the Demo on YouTube)](https://youtu.be/DJMDYq52Iv8)

1.  Browse to our latest NuttX Emulator in Web Browser...

    [NuttX Emulator for Ox64 (modified for TCC)](https://lupyuen.github.io/nuttx-tinyemu/tcc/)

    Enter `a.out` and we'll see...

    ```text
    NuttShell (NSH) NuttX-12.4.0-RC0
    nsh> a.out
    nsh: a.out: command not found
    ```

1.  Browse to our TCC Compiler in Web Browser...

    [TCC Compiler for WebAssembly](https://lupyuen.github.io/tcc-riscv32-wasm/)

    [Paste this code](https://gist.github.com/lupyuen/cc74229e39b3cea0d6974a85fb06f65a) into the Web Browser...

    ```c
    int main(int argc, char *argv[]) {

      // Make NuttX System Call to write(fd, buf, buflen)
      const unsigned int nbr = 61; // SYS_write
      const void *parm1 = 1;       // File Descriptor (stdout)
      const void *parm2 = "Hello, World!!\n"; // Buffer
      const void *parm3 = 15; // Buffer Length

      // Load the Parameters into Registers A0 to A3
      // TODO: This doesn't work, so we load again below
      register long r0 asm("a0") = (long)(nbr);
      register long r1 asm("a1") = (long)(parm1);
      register long r2 asm("a2") = (long)(parm2);
      register long r3 asm("a3") = (long)(parm3);

      // Execute ECALL for System Call to NuttX Kernel
      // Load the Parameters into Registers A0 to A3
      asm volatile (

        // Load 61 to Register A0 (SYS_write)
        "addi a0, zero, 61 \n"

        // Load 1 to Register A1 (File Descriptor)
        "addi a1, zero, 1 \n"

        // Load 0x80101000 to Register A2 (Buffer)
        "lui   a2, 0x80 \n"
        "addiw a2, a2, 257 \n"
        "slli  a2, a2, 0xc \n"

        // Load 15 to Register A3 (Buffer Length)
        "addi a3, zero, 15 \n"

        // ECALL for System Call to NuttX Kernel
        "ecall \n"

        // NuttX needs NOP after ECALL
        ".word 0x0001 \n"

        // Input+Output Registers: None
        // Input-Only Registers: A0 to A3
        // Clobbers the Memory
        :
        : "r"(r0), "r"(r1), "r"(r2), "r"(r3)
        : "memory"
      );

      // Loop Forever
      for(;;) {}
      return 0;
    }
    ```    

    Note that the Buffer Address (Register A2) is now 0x80101000 because we're running on Ox64 Emulator.
    
    (Instead of 0xC0101000 for QEMU Emulator)

1.  Click the "Compile" button.

1.  Head back to our latest NuttX Emulator in Web Browser...

    [NuttX Emulator for Ox64 (modified for TCC)](https://lupyuen.github.io/nuttx-tinyemu/tcc/)

    Enter `a.out` and we'll see...

    ```text
    NuttShell (NSH) NuttX-12.4.0-RC0
    nsh> a.out
    Hello, World!!
    ```

    A NuttX App compiled in the Web Browser... Now runs OK with NuttX Emulator in Web Browser! 🎉

1.  Try changing "Hello World" to "Hello aaaaa" (or any other message) as long as the Length stays the same.

    (Because we hardcoded the length in Register A3)

    Recompile, switch back to the Emulator, re-run `a.out`. It changes!

    [(Watch the Demo on YouTube)](https://youtu.be/DJMDYq52Iv8)

    [(Source Files for TCC WebAssembly)](https://github.com/lupyuen/tcc-riscv32-wasm/tree/main/docs)

    [(Source Files for NuttX Emulator integrated with TCC)](https://github.com/lupyuen/nuttx-tinyemu/tree/main/docs/tcc)

![Building and Testing NuttX Apps inside a Web Browser](https://lupyuen.github.io/images/tcc-nuttx.jpg)

_Wow how does it work?_

In Chrome Web Browser, click to `Menu > Developer Tools > Application Tab > Local Storage > lupyuen.github.io`

We'll see that the RISC-V ELF `a.out` is stored locally as `elf_data` in Local Storage.

That's why NuttX Emulator can pick up the `a.out` from our Web Browser!

TCC Compiler saves `a.out` to `elf_data` in Local Storage: [tcc.js](https://github.com/lupyuen/tcc-riscv32-wasm/blob/main/docs/tcc.js#L60-L90)

```javascript
  // Call TCC to compile a program
  const ptr = wasm.instance.exports
    .compile_program(options_ptr, code_ptr);
  console.log(`main: ptr=${ptr}`);
  ...
  // Encode the `a.out` data from the rest of the bytes returned
  const data = new Uint8Array(memory.buffer, ptr + 4, len);
  let encoded_data = "";
  for (const i in data) {
    const hex = Number(data[i]).toString(16).padStart(2, "0");
    encoded_data += `%${hex}`;
  }

  // Save the ELF Data to Local Storage for loading by NuttX Emulator
  localStorage.setItem("elf_data", encoded_data);
  console.log({ elf_data: localStorage.getItem("elf_data") });
```

_But NuttX Emulator boots from a fixed [NuttX Image](https://github.com/lupyuen/nuttx-tinyemu/blob/main/docs/tcc/Image), loaded from our Static Web Server. How did `a.out` appear inside the NuttX Image?_

We used a nifty illusion... `a.out` was in the NuttX Image all along!

```bash
## Create a Fake a.out that contains a Distinct Pattern:
##   22 05 69 00
##   22 05 69 01
## For 1024 times
rm -f /tmp/pattern.txt
start=$((0x22056900))
for i in {0..1023}
do
  printf 0x%x\\n $(($start + $i)) >> /tmp/pattern.txt
done

## Copy the Fake a.out to our NuttX Apps Folder
cat /tmp/pattern.txt \
  | xxd -revert -plain \
  >~/ox64/apps/bin/a.out
hexdump -C ~/ox64/apps/bin/a.out
```

During NuttX Build, the Fake `a.out` gets bundled into the [Initial RAM Disk (initrd)](https://github.com/lupyuen/nuttx-tinyemu/blob/main/docs/tcc/initrd).

[Which gets appended](https://lupyuen.github.io/articles/app#initial-ram-disk) to the [NuttX Image](https://github.com/lupyuen/nuttx-tinyemu/blob/main/docs/tcc/Image).

But because `a.out` doesn't contain a valid ELF File, NuttX says "command not found" because it couldn't load `a.out` as an ELF Executable.

(This won't work with QEMU, because NuttX QEMU doesn't append the Initial RAM Disk to NuttX Image. Instead [QEMU uses Semihosting](https://lupyuen.github.io/articles/semihost#nuttx-calls-semihosting) to access the NuttX Apps, which won't work in a Web Browsr)

_So we patched Fake `a.out` in the NuttX Image with the Real `a.out`?_

Exactly! In the NuttX Emulator JavaScript, we read `elf_data` from the Local Storage and pass it to TinyEMU WebAssembly: [jslinux.js](https://github.com/lupyuen/nuttx-tinyemu/blob/main/docs/tcc/jslinux.js#L504-L545)

```javascript
    function start()
    {
        //// Patch the ELF Data to a.out in Initial RAM Disk
        //// For Testing: localStorage.setItem("elf_data", "%7f%45%4c%46%02%01%01%00%00%00%00%00%00%00%00%00%01%00%f3%00%01%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%02%00%00%00%00%00%00%04%00%00%00%40%00%00%00%00%00%40%00%09%00%08%00%13%01%01%fa%23%3c%11%04%23%38%81%04%13%04%01%06%13%00%00%00%23%34%a4%fe%23%30%b4%fe%1b%05%d0%03%23%2e%a4%fc%1b%05%10%00%23%38%a4%fc%17%05%00%00%13%05%05%00%23%34%a4%fc%1b%05%f0%00%23%30%a4%fc%03%25%c4%fd%13%15%05%02%13%55%05%02%23%3c%a4%fa%03%35%04%fd%23%38%a4%fa%03%35%84%fc%23%34%a4%fa%03%35%04%fc%23%30%a4%fa%13%05%d0%03%93%05%10%00%37%06%08%00%1b%06%16%10%13%16%c6%00%93%06%f0%00%73%00%00%00%01%00%6f%00%00%00%83%30%81%05%03%34%01%05%13%01%01%06%67%80%00%00%00%00%00%00%00%00%48%65%6c%6c%6f%2c%20%57%6f%72%6c%64%21%21%0a%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%01%00%00%00%04%00%f1%ff%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%0e%00%00%00%01%00%03%00%00%00%00%00%00%00%00%00%10%00%00%00%00%00%00%00%00%00%00%00%00%00%01%00%2c%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%09%00%00%00%12%00%01%00%00%00%00%00%00%00%00%00%9a%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%68%65%6c%6c%6f%2e%63%00%6d%61%69%6e%00%4c%2e%30%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%2c%00%00%00%00%00%00%00%17%00%00%00%02%00%00%00%00%00%00%00%00%00%00%00%30%00%00%00%00%00%00%00%18%00%00%00%03%00%00%00%00%00%00%00%00%00%00%00%00%2e%74%65%78%74%00%2e%64%61%74%61%00%2e%64%61%74%61%2e%72%6f%00%2e%62%73%73%00%2e%73%79%6d%74%61%62%00%2e%73%74%72%74%61%62%00%2e%72%65%6c%61%2e%74%65%78%74%00%2e%73%68%73%74%72%74%61%62%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%01%00%00%00%01%00%00%00%06%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%40%00%00%00%00%00%00%00%9a%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%08%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%07%00%00%00%01%00%00%00%03%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%e0%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%08%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%0d%00%00%00%01%00%00%00%03%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%e0%00%00%00%00%00%00%00%10%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%08%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%16%00%00%00%08%00%00%00%03%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%f0%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%08%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%1b%00%00%00%02%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%f0%00%00%00%00%00%00%00%78%00%00%00%00%00%00%00%06%00%00%00%04%00%00%00%08%00%00%00%00%00%00%00%18%00%00%00%00%00%00%00%23%00%00%00%03%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%70%01%00%00%00%00%00%00%12%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%01%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%2b%00%00%00%04%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%90%01%00%00%00%00%00%00%30%00%00%00%00%00%00%00%05%00%00%00%01%00%00%00%08%00%00%00%00%00%00%00%18%00%00%00%00%00%00%00%36%00%00%00%03%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%c0%01%00%00%00%00%00%00%40%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%01%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00");
        let elf_len = 0;
        let elf_data = new Uint8Array([]);
        const elf_data_encoded = localStorage.getItem("elf_data");
        if (elf_data_encoded) {
            elf_data = new Uint8Array(
                elf_data_encoded
                    .split("%")
                    .slice(1)
                    .map(hex=>Number("0x" + hex))
            );
            elf_len = elf_data.length;
            console.log({elf_len, elf_data});    
        }
        ...
        // Pass elf_data and elf_len to TinyEMU
        Module.ccall(
            "vm_start",
            null,
            ["string", "number", "string", "string", "number", "number", "number", "string", "array", "number"],
            [url, mem_size, cmdline, pwd, width, height, (net_state != null) | 0, drive_url, elf_data, elf_len]
        );
```

Inside the TinyEMU WebAssembly: We receive the `elf_data` and copy it locally, because it will be clobbered (why?): [jsemu.c](https://github.com/lupyuen/ox64-tinyemu/blob/tcc/jsemu.c#L182-L211)

```c
void vm_start(const char *url, int ram_size, const char *cmdline,
              const char *pwd, int width, int height, BOOL has_network,
              const char *drive_url, uint8_t *elf_data0, int elf_len0)
{
    //// Patch the ELF Data to a.out in Initial RAM Disk
    extern uint8_t elf_data[];  // From riscv_machine.c
    extern int elf_len;
    elf_len = elf_len0;

    // Must copy ELF Data to Local Buffer because it will get overwritten
    printf("elf_len=%d\n", elf_len);
    if (elf_len > 4096) { puts("*** ERROR: elf_len exceeds 4096, increase elf_data and a.out size"); }
    memcpy(elf_data, elf_data0, elf_len);
```

Then we search for our Magic Pattern `22 05 69 00` in our Fake `a.out`: [riscv_machine.c](https://github.com/lupyuen/ox64-tinyemu/blob/tcc/riscv_machine.c#L1034-L1053)

```c
    // Patch the ELF Data to a.out in Initial RAM Disk
    uint64_t elf_addr = 0;
    printf("elf_len=%d\n", elf_len);
    if (elf_len > 0) {
        //// TODO: Fix the Image Size
        for (int i = 0; i < 0xD61680; i++) {
            const uint8_t pattern[] = { 0x22, 0x05, 0x69, 0x00 };
            if (memcmp(&kernel_ptr[i], pattern, sizeof(pattern)) == 0) {
                //// TODO: Catch overflow of a.out
                memcpy(&kernel_ptr[i], elf_data, elf_len);
                elf_addr = RAM_BASE_ADDR + i;
                printf("Patched ELF Data to a.out at %p\n", elf_addr);
                break;
            }
        }
        if (elf_addr == 0) { puts("*** ERROR: Pattern for ELF Data a.out is missing"); }
    }
```

And we overwrite the Fake `a.out` with the Real `a.out` from `elf_data`.

That's how we compile a NuttX App in the Web Browser, and run it with NuttX Emulator in the Web Browser! 🎉

![TCC RISC-V Compiler: Compiled to WebAssembly with Zig Compiler](https://lupyuen.github.io/images/tcc-emu2.png)

# ROM FS Filesystem for TCC WebAssembly

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

_TCC WebAssembly needs an Embedded Filesystem that will have C Header Files and C Library Files for building apps..._

_How will we implement this Embedded Filesystem in Zig?_

Let's embed the simple [__ROM FS Filesystem__](https://docs.kernel.org/filesystems/romfs.html) inside our Zig Wrapper...

1.  Our TCC JavaScript will fetch the Bundled ROM FS Filesystem over HTTP: [romfs.bin](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/docs/romfs/romfs.bin)

1.  Then copy the Bundled ROM FS into Zig Wrapper's WebAssembly Memory

1.  Our Zig Wrapper will mount the ROM FS in memory

1.  And expose POSIX Functions to TCC that will access the Emulated Filesystem

[(Works like the __Emscripten Filesystem__)](https://emscripten.org/docs/porting/files/file_systems_overview.html)

_How to bundle our C Header Files and C Library Files into the ROM FS Filesystem?_

Like this...

```bash
##  For Ubuntu: Install genromfs
sudo apt install genromfs

##  For macOS: Install genromfs
brew install genromfs

## Bundle the romfs folder into ROM FS Filesystem romfs.bin
## and label with this Volume Name
genromfs \
  -f zig/romfs.bin \
  -d zig/romfs \
  -V "ROMFS"
```

[(See the ROM FS Binary `zig/romfs.bin`)](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs.bin)

[(See the ROM FS Files `zig/romfs`)](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs)

_How to implement the ROM FS in our Zig Wrapper?_

We'll borrow the ROM FS Driver from Apache NuttX RTOS. And compile it from C to WebAssembly with Zig Compiler...

- [fs_romfs.c](https://github.com/apache/nuttx/blob/master/fs/romfs/fs_romfs.c)

- [fs_romfs.h](https://github.com/apache/nuttx/blob/master/fs/romfs/fs_romfs.h)

- [fs_romfsutil.c](https://github.com/apache/nuttx/blob/master/fs/romfs/fs_romfsutil.c)

- [inode.h](https://github.com/apache/nuttx/blob/master/fs/inode/inode.h)

- [fs.h](https://github.com/apache/nuttx/blob/master/include/nuttx/fs/fs.h)

[(See the __Modified Source Files__)](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig)

[(See the __Build Script__)](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/build.sh)

This compiles OK with Zig Compiler with a few tweaks, let's test it in Zig...

# Mount the ROM FS Filesystem in Zig

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

_We borrowed the ROM FS Driver from Apache NuttX RTOS. Zig Compiler compiles it to WebAssembly with a few tweaks..._

_How do we call the ROM FS Driver to Mount the ROM FS Filesystem?_

This is how we mount the ROM FS Filesystem in Zig: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L12-L34)

```zig
/// Import the ROM FS
const c = @cImport({
  @cInclude("zig_romfs.h");
});

/// Compile a C program to 64-bit RISC-V
pub export fn compile_program(...) [*]const u8 {

  // Create the Memory Allocator for malloc
  memory_allocator = std.heap.FixedBufferAllocator.init(&memory_buffer);

  // Mount the ROM FS Filesystem
  const ret = c.romfs_bind( // Bind the ROM FS Filesystem
    c.romfs_blkdriver, // blkdriver: ?*struct_inode_6
    null, // data: ?*const anyopaque
    &c.romfs_mountpt // handle: [*c]?*anyopaque
  );
  assert(ret >= 0);
```

Zig won't let us create objects for `romfs_blkdriver` and `romfs_mountpt`, so we create them in C: [fs_romfs.c](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/fs_romfs.c#L48-L50)

```c
struct inode romfs_blkdriver_inode;
struct inode *romfs_blkdriver = &romfs_blkdriver_inode;
void *romfs_mountpt = NULL;
```

This crashes inside [romfs_fsconfigure](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/fs_romfsutil.c#L738-L796)...

```bash
$ node zig/test.js
compile_program: start
Entry

wasm://wasm/0085e9b2:1
RuntimeError: unreachable
    at signature_mismatch:mtd_bread (wasm://wasm/0085e9b2:wasm-function[10]:0x842)
    at romfs_fsconfigure (wasm://wasm/0085e9b2:wasm-function[22]:0xab3)
    at romfs_bind (wasm://wasm/0085e9b2:wasm-function[20]:0x954)
    at compile_program (wasm://wasm/0085e9b2:wasm-function[251]:0x4e683)
    at /workspaces/bookworm/tcc-riscv32-wasm/zig/test.js:63:6
```

We need to return the XIP Address so that [romfs_fsconfigure](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/fs_romfsutil.c#L738-L796) will read the RAM directly. (Instead of reading from the device)

From [fs_romfsutil.c](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/fs_romfsutil.c#L704-L705):

```c
// Implement mid_ioctl() so that BIOC_XIPBASE
// sets the XIP Address in rm_xipbase
ret = MTD_IOCTL(inode->u.i_mtd, BIOC_XIPBASE,
  (unsigned long)&rm->rm_xipbase);
```

We implement `mid_ioctl` for `BIOC_XIPBASE`: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L819-L826)

```zig
export fn mtd_ioctl(_: *mtd_dev_s, cmd: c_int, rm_xipbase: ?*c_int) c_int {
  assert(rm_xipbase != null);
  if (cmd == c.BIOC_XIPBASE) {
    // Return the XIP Base Address
    rm_xipbase.?.* = @intCast(@intFromPtr(ROMFS_DATA));
  } else if (cmd == c.MTDIOC_GEOMETRY) {
    // Return the Storage Device Geometry
    const geo: *c.mtd_geometry_s = @ptrCast(rm_xipbase.?);
    geo.*.blocksize = 64;
    geo.*.erasesize = 64;
    geo.*.neraseblocks = 1024; // TODO: Is this needed?
    const name = "ZIG_ROMFS";
    @memcpy(geo.*.model[0..name.len], name);
    geo.*.model[name.len] = 0;
  } else {
    debug("mtd_ioctl: Unknown command {}", .{cmd});
  }
  return 0;
}

/// Embed the ROM FS Filesystem.
/// Later our JavaScript shall fetch this over HTTP.
const ROMFS_DATA = @embedFile("romfs.bin");
```

Also we embed the ROM FS Data inside our Zig Wrapper for now. Later our JavaScript shall fetch `romfs.bin` over HTTP.

And the mounting succeeds yay! 

```bash
$ node zig/test.js
compile_program: start
compile_program: Mounting ROM FS...
Entry
compile_program: ROM FS mounted OK!
```

The ROM FS Driver verifies the Magic Number when mounting. So we know it's correct: [fs_romfsutil.c](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/fs_romfsutil.c#L765-L770)

```c
int romfs_fsconfigure(FAR struct romfs_mountpt_s *rm) {
  ...
  /* Verify the magic number at that identifies this as a ROMFS filesystem */
  #define ROMFS_VHDR_MAGIC   "-rom1fs-"
  if (memcmp(rm->rm_buffer, ROMFS_VHDR_MAGIC, 8) != 0)
    { return -EINVAL; }
```

_We're sure it's correct?_

If we don't embed a proper ROM FS Filesystem, the Magic Number will fail...

```bash
## Let's embed some junk:
## const ROMFS_DATA = @embedFile("build.sh");

## The ROM FS Mounting fails...
$ node zig/test.js
compile_program: start
Entry
ERROR: romfs_fsconfigure failed: -22
```

So yeah we're correct.

Let's open a file from ROM FS...

# Open a ROM FS File in Zig

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

This is how we open a file from ROM FS in Zig: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L39-L46)

```c
// Create the Mount Inode
const mount_inode = c.create_mount_inode(c.romfs_mountpt);

// Create the File Struct
var filep = std.mem.zeroes(c.struct_file);
filep.f_inode = mount_inode;

// Open the file
const ret2 = c.romfs_open( // Open "hello" for Read-Only. `mode` is used only for creating files.
  &filep, // filep: [*c]struct_file
  "hello", // relpath: [*c]const u8
  c.O_RDONLY, // oflags: c_int
  0 // mode: mode_t
);
assert(ret2 >= 0);
```

Our file has been opened successfully yay!

```text
$ node zig/test-nuttx.js
compile_program: start
compile_program: Mounting ROM FS...
Entry
compile_program: ROM FS mounted OK!

compile_program: Opening ROM FS File `hello`...
Open 'hello'
compile_program: ROM FS File `hello` opened OK!
```

"/hello" works OK too...

```zig
// Open "/hello"
romfs_open(..., "/hello", ...);
```

_What if the file doesn't exist?_

ROM FS Driver says that the file doesn't exist...

```text
## Let's try a file that doesn't exist:
## romfs_open(..., "hello2", ...)

compile_program: Opening ROM FS File
Open 'hello2'
ERROR: Failed to find directory directory entry for '%s': %d
```

So yep our ROM FS Driver is reading the ROM FS Directory correctly!

_How did we figure out the Mount Inode?_

See the NuttX Code: [Create a Mount Inode](https://github.com/apache/nuttx/blob/master/fs/mount/fs_mount.c#L379-L409) with [inode_reserve](https://github.com/apache/nuttx/blob/master/fs/inode/fs_inodereserve.c#L146-L260)

Finally we read a ROM FS file...

# Read a ROM FS File in Zig

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

This is how we read a ROM FS File in Zig (and close it): [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L57-L73)

```zig
// Read the file
var buf = std.mem.zeroes([4]u8);
const ret3 = c.romfs_read( // Read the file
  &filep, // filep: [*c]struct_file
  &buf, // buffer: [*c]u8
  buf.len // buflen: usize
);
assert(ret3 >= 0);
hexdump.hexdump(@ptrCast(&buf), @intCast(ret3));

// Close the file
const ret4 = c.romfs_close(&filep);
assert(ret4 >= 0);
```

And it works yay!

```text
$ node zig/test.js
compile_program: start
compile_program: Mounting ROM FS...
Entry
compile_program: ROM FS mounted OK!

compile_program: Opening ROM FS File `hello`...
Open 'hello'
compile_program: ROM FS File `hello` opened OK!

compile_program: Reading ROM FS File `hello`...
Read %zu bytes from offset %jd
Read sector %jd
sector: %d cached: %d ncached: %d sectorsize: %d XIP base: %p buffer: %p
XIP buffer: %p
Return %d bytes from sector offset %d
compile_program: ROM FS File `hello` read OK!
  0000:  7F 45 4C 46                                       .ELF

compile_program: Closing ROM FS File `hello`...
Closing
compile_program: ROM FS File `hello` closed OK!
```

This works OK in the Web Browser too!

Let's integrate the ROM FS Driver with TCC...

# Integrate NuttX ROM FS Driver with TCC WebAssembly in Zig

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

_TCC WebAssembly needs a ROM FS Filesystem that will have C Header Files and C Library Files for building apps..._

_How will we integrate the NuttX ROM FS Driver in Zig?_

At Startup: We call the NuttX ROM FS Driver to mount the ROM FS Filesystem: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L24-L45)

```zig
/// Next File Descriptor Number.
/// First File Descriptor is reserved for C Program `hello.c`
var next_fd: c_int = FIRST_FD;
const FIRST_FD = 3;

/// Map a File Descriptor to the ROM FS File
/// Index of romfs_files = File Descriptor Number - FIRST_FD - 1
var romfs_files: std.ArrayList(*c.struct_file) = undefined;

/// Compile a C program to 64-bit RISC-V
pub export fn compile_program(...) [*]const u8 {

  // Create the Memory Allocator for malloc
  memory_allocator = std.heap.FixedBufferAllocator.init(&memory_buffer);

  // Map from File Descriptor to ROM FS File
  romfs_files = std.ArrayList(*c.struct_file).init(std.heap.page_allocator);
  defer romfs_files.deinit();

  // Mount the ROM FS Filesystem
  const ret = c.romfs_bind( // Bind the ROM FS Filesystem
    c.romfs_blkdriver, // blkdriver: ?*struct_inode_6
    null, // data: ?*const anyopaque
    &c.romfs_mountpt // handle: [*c]?*anyopaque
  );
  assert(ret >= 0);

  // Create the Mount Inode and test the ROM FS
  romfs_inode = c.create_mount_inode(c.romfs_mountpt);
  test_romfs();
```

NuttX ROM FS Driver will call `mtd_ioctl` to map the ROM FS Data in memory: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L974-L994)

```zig
/// Embed the ROM FS Filesystem.
/// Later our JavaScript shall fetch this over HTTP.
const ROMFS_DATA = @embedFile("romfs.bin");

export fn mtd_ioctl(_: *mtd_dev_s, cmd: c_int, rm_xipbase: ?*c_int) c_int {
  assert(rm_xipbase != null);
  if (cmd == c.BIOC_XIPBASE) {
    // Return the XIP Base Address
    rm_xipbase.?.* = @intCast(@intFromPtr(ROMFS_DATA));
  } else if (cmd == c.MTDIOC_GEOMETRY) {
    // Return the Storage Device Geometry
    const geo: *c.mtd_geometry_s = @ptrCast(rm_xipbase.?);
    geo.*.blocksize = 64;
    geo.*.erasesize = 64;
    geo.*.neraseblocks = 1024; // TODO: Is this needed?
    const name = "ZIG_ROMFS";
    @memcpy(geo.*.model[0..name.len], name);
    geo.*.model[name.len] = 0;
  } else {
    debug("mtd_ioctl: Unknown command {}", .{cmd});
  }
  return 0;
}
```

When TCC WebAssembly calls `open` to open an Include File, we call the NuttX ROM FS Driver to open the file in ROM FS: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L157-L207)

```zig
export fn open(path: [*:0]const u8, oflag: c_uint, ...) c_int {

  // If opening the C Program File `hello.c`
  // Or creating `hello.o`...
  // Just return the File Descriptor
  // TODO: This might create a hole in romfs_files if we open a file for reading after writing another file
  if (next_fd == FIRST_FD or oflag == 577) {
    const fd = next_fd;
    next_fd += 1;
    return fd;
  } else {
    // If opening an Include File or Library File...
    // Allocate the File Struct
    const files = std.heap.page_allocator.alloc(c.struct_file, 1) catch {
      debug("open: Failed to allocate file", .{});
      @panic("open: Failed to allocate file");
    };
    const file = &files[0];
    file.* = std.mem.zeroes(c.struct_file);
    file.*.f_inode = romfs_inode;

    // Strip the path from System Include
    const sys = "/usr/local/lib/tcc/include/";
    const strip_path = if (std.mem.startsWith(u8, std.mem.span(path), sys)) (path + sys.len) else path;

    // Open the ROM FS File
    const ret = c.romfs_open( // Open for Read-Only. `mode` is used only for creating files.
      file, // filep: [*c]struct_file
      strip_path, // relpath: [*c]const u8
      c.O_RDONLY, // oflags: c_int
      0 // mode: mode_t
    );
    if (ret < 0) { return ret; }

    // Remember the ROM FS File
    const fd = next_fd;
    next_fd += 1;
    const f = fd - FIRST_FD - 1;
    assert(romfs_files.items.len == f);
    romfs_files.append(file) catch {
      debug("Unable to allocate file", .{});
      @panic("Unable to allocate file");
    };
    return fd;
  }
}
```

When TCC WebAssembly calls `read` to read the Include File, we call ROM FS: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L214-L244)

```zig
export fn read(fd: c_int, buf: [*:0]u8, nbyte: size_t) isize {

  // If reading the C Program...
  if (fd == FIRST_FD) {
    // Copy from the Read Buffer
    const len = read_buf.len;
    assert(len < nbyte);
    @memcpy(buf[0..len], read_buf[0..len]);
    buf[len] = 0;
    read_buf.len = 0;
    return @intCast(len);
  } else {
    // Fetch the ROM FS File
    const f = fd - FIRST_FD - 1;
    const file = romfs_files.items[@intCast(f)];

    // Read from the ROM FS File
    const ret = c.romfs_read( // Read the file
      file, // filep: [*c]struct_file
      buf, // buffer: [*c]u8
      nbyte // buflen: usize
    );
    assert(ret >= 0);
    return @intCast(ret);
  }
}
```

And finally we call ROM FS Driver to close the Include File: [tcc-wasm.zig](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/tcc-wasm.zig#L266-L286)

```zig
export fn close(fd: c_int) c_int {

  // If closing an Include File or Library File...
  if (fd > FIRST_FD) {
    // Fetch the ROM FS File
    const f = fd - FIRST_FD - 1;
    if (f >= romfs_files.items.len) {
      // Skip the closing of `hello.o`
      return 0;
    }
    const file = romfs_files.items[@intCast(f)];

    // Close the ROM FS File. TODO: Deallocate the file
    const ret = c.romfs_close(file);
    assert(ret >= 0);
  }
  return 0;
}
```

We stage the Include Files `stdio.h` and `stdlib.h` here: [zig/romfs](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs)

```bash
$ ls -l zig/romfs
-rw-r--r-- 1 25 stdio.h
-rw-r--r-- 1 23 stdlib.h
```

And we bundle them into `romfs.bin`...

```bash
##  For Ubuntu: Install genromfs
sudo apt install genromfs

##  For macOS: Install genromfs
brew install genromfs

## Bundle the romfs folder into ROM FS Filesystem romfs.bin
## and label with this Volume Name
genromfs \
  -f zig/romfs.bin \
  -d zig/romfs \
  -V "ROMFS"
```

[(See the ROM FS Binary `zig/romfs.bin`)](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs.bin)

At last we have a proper POSIX (Read-Only) Filesystem for TCC WebAssembly yay!

```text
open: path=/usr/local/lib/tcc/include/stdio.h, oflag=0, return fd=4
Open 'stdio.h'
read: fd=4, nbyte=8192
XIP buffer: anyopaque@10b672
read: return buf=
  int puts(const char *s);

read: fd=4, nbyte=8192
read: return buf=
close: fd=4
Closing

open: path=/usr/local/lib/tcc/include/stdlib.h, oflag=0, return fd=5
Open 'stdlib.h'
read: fd=5, nbyte=8192
XIP buffer: anyopaque@10b6b2
read: return buf=
  void exit(int status);

read: fd=5, nbyte=8192
read: return buf=
close: fd=5
Closing
```

_What if we need a Temporary Writeable Filesystem?_

Try the NuttX Tmp FS Driver: [nuttx/fs/tmpfs](https://github.com/apache/nuttx/tree/master/fs/tmpfs)

Time to wrap up and run everything in a Web Browser...

# `puts` and `exit` work OK in TCC WebAssembly and NuttX Emulator yay!

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

[(Watch the __Demo on YouTube__)](https://youtu.be/sU69bUyrgN8)

Remember we're doing a Decent Demo of Building and Testing a #NuttX App in the Web Browser... `puts` and `exit` finally work OK yay! 🎉

1.  TCC Compiler in WebAssembly compiles `puts` and `exit` to proper NuttX System Calls

1.  By loading `<stdio.h>` and `<stdlib.h>` from the ROM FS Filesystem (thanks to the NuttX Driver)

1.  TCC Compiler generates the 64-bit RISC-V ELF `a.out`

1.  Which gets automagically copied to NuttX Emulator in WebAssembly

1.  And NuttX Emulator executes `puts` and `exit` correctly as NuttX System Calls!

Try the new ROM FS Demo here: https://lupyuen.github.io/tcc-riscv32-wasm/romfs/

```c
#include <stdio.h>
#include <stdlib.h>

void main(int argc, char *argv[]) {
  puts("Hello, World!!\n");
  exit(0);
}
```

Click "Compile". Then run the `a.out` here: https://lupyuen.github.io/nuttx-tinyemu/tcc/

```text
Loading...
TinyEMU Emulator for Ox64 BL808 RISC-V SBC
ABC
NuttShell (NSH) NuttX-12.4.0-RC0
nsh> a.out
Hello, World!!
 
nsh> a.out
Hello, World!!
 
nsh> a.out
Hello, World!!
 
nsh>
```

Try changing "Hello World" to something else. Recompile and Reload the [NuttX Emulator](https://lupyuen.github.io/nuttx-tinyemu/tcc/). It works!

Impressive, no? 3 things we fixed...

[(Watch the __Demo on YouTube__)](https://youtu.be/sU69bUyrgN8)

![TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)](https://lupyuen.github.io/images/romfs-title.png)

## ROM FS Filesystem for Include Files

_How did we get <stdio.h> and <stdlib.h> in TCC WebAssembly?_

We create a Staging Folder [zig/romfs](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs) that contains our C Header Files for TCC Compiler...

- [stdio.h](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs/stdio.h)

- [stdlib.h](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs/stdlib.h)

Then we bundle the Staging Folder into a ROM FS Filesystem...

```bash
##  For Ubuntu: Install genromfs
sudo apt install genromfs

##  For macOS: Install genromfs
brew install genromfs

## Bundle the romfs folder into ROM FS Filesystem romfs.bin
## and label with this Volume Name
genromfs \
  -f zig/romfs.bin \
  -d zig/romfs \
  -V "ROMFS"
```

Which becomes the ROM FS Data File [zig/romfs.bin](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs.bin)

Inside our TCC WebAssembly: We mounted the ROM FS Filesystem by calling the NuttX ROM FS Driver. (Which has been integrated into our Zig WebAssembly)

See the earlier sections to find out how we modded the POSIX Filesystem Calls (from TCC WebAssembly) to access the NuttX ROM FS Driver.

## Implement `puts` with NuttX System Call

In our Demo NuttX App, we implement `puts` by calling `write`: [stdio.h](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs/stdio.h#L18-L25)

```c
// Print the string to Standard Output
inline int puts(const char *s) {
  return
    write(1, s, strlen(s)) +
    write(1, "\n", 1);
}
```

Then we implement `write` the exact same way as NuttX, making a System Call: [stdio.h](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs/stdio.h#L25-L36)

```c
// Caution: This may change
#define SYS_write 61

// Write to the File Descriptor
// https://lupyuen.github.io/articles/app#nuttx-app-calls-nuttx-kernel
inline ssize_t write(int parm1, const void * parm2, size_t parm3) {
  return (ssize_t) sys_call3(
    (unsigned int) SYS_write,  // System Call Number
    (uintptr_t) parm1,         // File Descriptor (1 = Standard Output)
    (uintptr_t) parm2,         // Buffer to be written
    (uintptr_t) parm3          // Number of bytes to write
  );
}
```

`sys_call3` is our hacked implementation of NuttX System Call: [stdio.h](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs/stdio.h#L36-L84)

```c
// Make a System Call with 3 parameters
// https://github.com/apache/nuttx/blob/master/arch/risc-v/include/syscall.h#L240-L268
inline uintptr_t sys_call3(
  unsigned int nbr,  // System Call Number
  uintptr_t parm1,   // First Parameter
  uintptr_t parm2,   // Second Parameter
  uintptr_t parm3    // Third Parameter
) {
  // Pass the Function Number and Parameters in
  // Registers A0 to A3
  register long r3 asm("a0") = (long)(parm3);  // Will move to A3
  asm volatile ("slli a3, a0, 32");  // Shift 32 bits Left then Right
  asm volatile ("srli a3, a3, 32");  // To clear the top 32 bits

  register long r2 asm("a0") = (long)(parm2);  // Will move to A2
  asm volatile ("slli a2, a0, 32");  // Shift 32 bits Left then Right
  asm volatile ("srli a2, a2, 32");  // To clear the top 32 bits

  register long r1 asm("a0") = (long)(parm1);  // Will move to A1
  asm volatile ("slli a1, a0, 32");  // Shift 32 bits Left then Right
  asm volatile ("srli a1, a1, 32");  // To clear the top 32 bits

  register long r0 asm("a0") = (long)(nbr);  // Will stay in A0

  // `ecall` will jump from RISC-V User Mode
  // to RISC-V Supervisor Mode
  // to execute the System Call.
  // Input + Output Registers: A0 to A3
  // Clobbers the Memory
  asm volatile
  (
    // ECALL for System Call to NuttX Kernel
    "ecall \n"
    
    // NuttX needs NOP after ECALL
    ".word 0x0001 \n"

    // Input+Output Registers: None
    // Input-Only Registers: A0 to A3
    // Clobbers the Memory
    :
    : "r"(r0), "r"(r1), "r"(r2), "r"(r3)
    : "memory"
  );

  // Return the result from Register A0
  return r0;
} 
```

_Why so complicated?_

That's because TCC [won't load the RISC-V Registers correctly](https://lupyuen.github.io/articles/tcc#appendix-nuttx-system-call). Thus we load the registers ourselves.

_Why not simply copy A0 to A2?_

```c
register long r2 asm("a0") = (long)(parm2);  // Will move to A2
asm volatile ("addi a2, a0, 0");  // Copy A0 to A2
```

Because then Register A2 becomes negative...

```text
riscv_swint: Entry: regs: 0x8020be10
cmd: 61
EPC: 00000000c0000160
A0: 000000000000003d 
A1: 0000000000000001 
A2: ffffffffc0101000 
A3: 000000000000000f
[...Page Fault because A2 is Invalid Address...]
```

So we Shift away the Negative Sign...

```c
register long r2 asm("a0") = (long)(parm2);  // Will move to A2
asm volatile ("slli a2, a0, 32");  // Shift 32 bits Left then Right
asm volatile ("srli a2, a2, 32");  // To clear the top 32 bits
```

Then Register A2 becomes Positively OK...

```text
riscv_swint: Entry: regs: 0x8020be10
cmd: 61
EPC: 00000000c0000164
A0: 000000000000003d 
A1: 0000000000000001
A2: 00000000c0101000
A3: 000000000000000f
Hello, World!!
```

BTW `andi` doesn't work...

```c
register long r2 asm("a0") = (long)(parm2);  // Will move to A2
asm volatile ("andi a2, a0, 0xffffffff");
```

Because 0xffffffff gets assembled to -1. (Bug?)

## Implement `exit` with NuttX System Call

In our Demo NuttX App, we implement `exit` the same way as NuttX, by making a System Call: [stdlib.h](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs/stdlib.h#L1-L10)

```c
// Caution: This may change
#define SYS__exit 8

// Terminate the NuttX Process
// From nuttx/syscall/proxies/PROXY__exit.c
inline void exit(int parm1) {
  sys_call1((unsigned int)SYS__exit, (uintptr_t)parm1);
  while(1);
}
```

`sys_call1` makes a NuttX System Call, with our hand-crafted RISC-V Assembly (as a workaround): [stdlib.h](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs/stdlib.h#L10-L48)

```c
// Make a System Call with 1 parameters
// https://github.com/apache/nuttx/blob/master/arch/risc-v/include/syscall.h#L188-L213
inline uintptr_t sys_call1(
  unsigned int nbr,  // System Call Number
  uintptr_t parm1    // First Parameter
) {
  // Pass the Function Number and Parameters
  // Registers A0 to A1
  register long r1 asm("a0") = (long)(parm1);  // Will move to A1
  asm volatile ("slli a1, a0, 32");  // Shift 32 bits Left then Right
  asm volatile ("srli a1, a1, 32");  // To clear the top 32 bits

  register long r0 asm("a0") = (long)(nbr);  // Will stay in A0

  // `ecall` will jump from RISC-V User Mode
  // to RISC-V Supervisor Mode
  // to execute the System Call.
  // Input + Output Registers: A0 to A1
  // Clobbers the Memory
  asm volatile
  (
    // ECALL for System Call to NuttX Kernel
    "ecall \n"
    
    // NuttX needs NOP after ECALL
    ".word 0x0001 \n"

    // Input+Output Registers: None
    // Input-Only Registers: A0 to A1
    // Clobbers the Memory
    :
    : "r"(r0), "r"(r1)
    : "memory"
  );

  // Return the result from Register A0
  return r0;
} 
```

And everything works OK now!

_Wow this looks horribly painful... Are we doing any more of this?_

Nope we won't do any more of this! Hand-crafting the NuttX System Calls in RISC-V Assembly was extremely painful.

(Maybe we'll revisit this when the RISC-V Registers are working OK in TCC)

TODO: Define the printf formats %jd, %zu

TODO: Iteratively handle printf formats

# Inside a ROM FS Filesystem

Read the article...

- ["Zig runs ROM FS Filesystem in the Web Browser (thanks to Apache NuttX RTOS)"](https://lupyuen.github.io/articles/romfs)

Based on [__ROM FS Spec__](https://docs.kernel.org/filesystems/romfs.html)

And our [__ROM FS Filesystem `romfs.bin`__](https://github.com/lupyuen/tcc-riscv32-wasm/blob/romfs/zig/romfs.bin)...

```bash
hexdump -C tcc-riscv32-wasm/zig/romfs.bin 
```

We see the ROM FS Filesystem Header...

```text
      [ Magic Number        ]  [ FS Size ] [ Checksm ]
0000  2d 72 6f 6d 31 66 73 2d  00 00 0f 90 58 57 01 f8  |-rom1fs-....XW..|
      [ Volume Name: ROMFS                           ]
0010  52 4f 4d 46 53 00 00 00  00 00 00 00 00 00 00 00  |ROMFS...........|
```

Followed by File Header for `.`...

```text
----  File Header for `.`
      [ NextHdr ] [ Info    ]  [ Size    ] [ Checksm ]
0020  00 00 00 49 00 00 00 20  00 00 00 00 d1 ff ff 97  |...I... ........|
      [ File Name: `.`                               ]
0030  2e 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
      (NextHdr & 0xF = 9 means Executable Directory)
```

Followed by File Header for `..`...

```text
----  File Header for `..`
      [ NextHdr ] [ Info    ]  [ Size    ] [ Checksm ]
0040  00 00 00 60 00 00 00 20  00 00 00 00 d1 d1 ff 80  |...`... ........|
      [ File Name: `..`                              ]
0050  2e 2e 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
      (NextHdr & 0xF = 0 means Hard Link)
```

Followed by File Header and Data for `stdio.h`...

```text
----  File Header for `stdio.h`
      [ NextHdr ] [ Info    ]  [ Size    ] [ Checksm ]
0060  00 00 0a 42 00 00 00 00  00 00 09 b7 1d 5d 1f 9e  |...B.........]..|
      [ File Name: `stdio.h`                         ]
0070  73 74 64 69 6f 2e 68 00  00 00 00 00 00 00 00 00  |stdio.h.........|
      (NextHdr & 0xF = 2 means Regular File)

----  File Data for `stdio.h`
0080  2f 2f 20 43 61 75 74 69  6f 6e 3a 20 54 68 69 73  |// Caution: This|
....
0a20  74 65 72 20 41 30 0a 20  20 72 65 74 75 72 6e 20  |ter A0.  return |
0a30  72 30 3b 0a 7d 20 0a 00  00 00 00 00 00 00 00 00  |r0;.} ..........|
```

Followed by File Header and Data for `stdlib.h`...

```text
----  File Header for `stdlib.h`
      [ NextHdr ] [ Info    ]  [ Size    ] [ Checksm ]
0a40  00 00 00 02 00 00 00 00  00 00 05 2e 23 29 67 fc  |............#)g.|
      [ File Name: `stdlib.h`                        ]
0a50  73 74 64 6c 69 62 2e 68  00 00 00 00 00 00 00 00  |stdlib.h........|
      (NextHdr & 0xF = 2 means Regular File)

----  File Data for `stdio.h`
0a60  2f 2f 20 43 61 75 74 69  6f 6e 3a 20 54 68 69 73  |// Caution: This|
....
0f80  72 65 74 75 72 6e 20 72  30 3b 0a 7d 20 0a 00 00  |return r0;.} ...|
0f90  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
```

![Inside a ROM FS Filesystem](https://lupyuen.github.io/images/romfs-format.jpg)

# Analysis of Missing Functions

Read the article...

- ["TCC RISC-V Compiler runs in the Web Browser (thanks to Zig Compiler)"](https://lupyuen.github.io/articles/tcc)

TCC calls surprisingly few External Functions! We might get it running on WebAssembly. Here's our analysis of the Missing Functions: [zig/tcc-wasm.zig](zig/tcc-wasm.zig)

![Analysis of Missing Functions](https://lupyuen.github.io/images/tcc-posix.jpg)

## Semaphore Functions

Not sure why TCC uses Semaphores? Maybe we'll understand when we support `#include` files.

TODO: Borrow Semaphore Functions from where?

- sem_init, sem_post, sem_wait

## Standard Library

qsort isn't used right now. Maybe for the Linker later?

TODO: Borrow qsort from where?

- exit, qsort

## Time Functions

Not used right now.

TODO: Borrow Time Functions from where?

- time, gettimeofday, localtime

## Math Functions

Also not used right now.

TODO: Borrow Math Functions from where?

- ldexp

## Varargs Functions

Varargs will be tricky to implement in Zig. Probably we should implement in C. Maybe MUSL?

Right now we're doing simple Pattern Matching. But it won't work for Real Programs.

- printf, snprintf, sprintf, vsnprintf
- sscanf

## Filesystem Functions

Will mock up these functions for WebAssembly. Maybe an Emulated Filesystem, similar to [Emscripten File System](https://emscripten.org/docs/porting/files/file_systems_overview.html)?

- getcwd
- remove, unlink

## File I/O Functions

Will mock up these functions for WebAssembly. Right now we read only 1 simple C Source File, and produce only 1 Object File. No header files, no libraries. And it works!

But later we might need an Emulated Filesystem, similar to [Emscripten File System](https://emscripten.org/docs/porting/files/file_systems_overview.html). And our File I/O code will support Multiple Files with proper Buffer Overflow Checks.

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
