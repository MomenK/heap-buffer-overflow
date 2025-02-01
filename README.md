# heap-buffer-overflow

This repository demonstrates how mixing different compiler flags during a build can lead to a heap-buffer-overflow. It contains a simple C/C++ project with conditional compilation that intentionally creates an inconsistency between the allocation size of an object and the code that accesses it.

## Overview

The project consists of the following files:

- **Makefile**  
  Contains build targets that compile the library (`lib.c`) and the main application (`main.c`) with different preprocessor flags. This illustrates how using different flags (i.e., with and without `-DCOND`) can cause a mismatch in object layout and result in a runtime heap-buffer-overflow error.

- **lib.c & lib.h**  
  Define the `lib` class. When compiled with the `-DCOND` flag, the class includes an additional member (`int y`) in addition to an integer member (`int x`). This changes the expected allocation size of the object.

- **main.c & main.h**  
  Contain the `main()` function which creates an instance of `lib` and calls its member function `display()`. The code in `main.c` is intentionally compiled without `-DCOND` (in one of the build targets) so that the allocated memory for the `lib` object is smaller than what the constructor in `lib.c` expects.

- **build.log**  
  Contains the output of a build and run session, including the detailed error report from AddressSanitizer, which shows the heap-buffer-overflow error.

## How It Works

The project is designed to illustrate the dangers of inconsistent build configurations:

1. **Conditional Compilation:**  
   The `lib` class in `lib.h` uses the preprocessor directive `#ifdef COND` to conditionally compile an extra member (`int y`). When `-DCOND` is defined, the object is expected to be larger.

2. **Inconsistent Build Flags:**  
   - The **library object file (`lib.o`)** is compiled with the `-DCOND` flag, so the constructor of `lib` assumes the object includes both `x` and `y`.
   - The **main application (`main.c`)** is compiled without the `-DCOND` flag, causing the allocation of a smaller object (only sufficient for `x`).

3. **Heap-Buffer-Overflow:**  
   The inconsistency leads the constructor to write data for `y` into memory that was not allocated. AddressSanitizer catches this error at runtime and reports a heap-buffer-overflow, as seen in the `build.log`.

## Build Targets

The Makefile includes several targets:

- **`lib_cond`**  
  Compiles `lib.c` with the `-DCOND` flag.

- **`lib_uncond`**  
  Compiles `lib.c` without the `-DCOND` flag.

- **`main_cond`**  
  Compiles and links `main.c` with `-DCOND`.

- **`main_uncond`**  
  Compiles and links `main.c` without `-DCOND`.

- **`main_segfault`**  
  Combines `lib_cond` (library with `-DCOND`) and `main_uncond` (main without `-DCOND`) to produce an executable that is expected to crash with a heap-buffer-overflow.

- **`run`**  
  Cleans previous builds, builds the segfault scenario, and runs the executable.

- **`run_fine`**  
  Builds both library and main with consistent flags (`-DCOND`), which should run without errors.

## Reproducing the Error

To reproduce the heap-buffer-overflow error using AddressSanitizer:


1. **Clean and Build the Faulty Configuration:**

   ```bash
   make run
This target cleans the build, compiles `lib.c` with `-DCOND`, compiles `main.c` without it, links them, and then runs the resulting executable. You should see an AddressSanitizer error report in the output.

2. **View the Build Log**

The file `build.log` contains the output from a complete build and run session, including a detailed error report and a shadow memory dump. [See explanation details](explanation.md)

## Explanation
When running the executable, AddressSanitizer detects a heap-buffer-overflow error:

```vbnet
==26560==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x602000000014 at pc 0x5557b4a58512 bp 0x7ffd11ae44f0 sp 0x7ffd11ae44e0
WRITE of size 4 at 0x602000000014 thread T0
    #0 0x5557b4a58511 in lib::lib() /home/user_name/C/heap-buffer-overflow/lib.c:8
    #1 0x5557b4a5836c in main /home/user_name/C/heap-buffer-overflow/main.c:7
    #2 0x7f698fc0e082 in __libc_start_main ../csu/libc-start.c:308
    #3 0x5557b4a5828d in _start (/home/user_name/C/heap-buffer-overflow/main+0x128d)
```

**Memory layout:**

```vbnet
Expected Memory Layout (if compiled with -DCOND):

   0x602000000010  +-----------------------+  
                   |        int x          | 4 bytes
   0x602000000014  +-----------------------+
                   |        int y          | 4 bytes
   0x602000000018  +-----------------------+

---------------------------------------------------------------

Actual Allocation (when compiled without -DCOND):

   0x602000000010  +-----------------------+  
                   |        int x          | 4 bytes
   0x602000000014  +-----------------------+

---------------------------------------------------------------
```

### Key Points


**Heap-Buffer-Overflow:**  
The error indicates that a write of 4 bytes (the size of a int on your system) is attempted at address 0x602000000020.

**Allocation Mismatch:**  
The allocated memory is only 4 bytes (sufficient for int x), as main.c was compiled without -DCOND. However, lib.c (compiled with -DCOND) expects an object that includes both x and y.

**Stack Trace:**  
The overflow occurs in the constructor `lib::lib()` (line 8 of lib.c), which is called from main (line 7 of main.c).

**Shadow Memory Dump Analysis:**  

The log includes a shadow memory dump, which might look similar to this:

```yaml
Shadow bytes around the buggy address:
  0x0c047fff7fb0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7fc0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7fd0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7fe0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  0x0c047fff7ff0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
=>0x0c047fff8000: fa fa[04]fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8010: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8020: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8030: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8040: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
  0x0c047fff8050: fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa fa
```

**Redzone Markers (fa):**  
The value `fa` marks redzones, which are guard areas around allocated memory. Accessing these areas indicates an out-of-bounds access.

**Highlighted Byte [04]:**  
The square brackets indicate the specific shadow byte corresponding to the memory address where the error occurred. Here, the `04` shows that the write landed in a redzone.


## Fixing the Issue

To fix the issue, ensure that all source files are compiled with consistent preprocessor flags. For example, compiling both `lib.c` and `main.c` with `-DCOND` (using the `run_fine` target) ensures that the object size is consistent throughout the project.

## Conclusion

This repository is intended as a teaching tool to demonstrate:

- The importance of consistent build configurations.
- How conditional compilation can affect object layout.
- How tools like AddressSanitizer help detect memory errors such as heap-buffer-overflows.

Feel free to explore and modify the project to see how changes in build flags affect program behavior.

Happy coding!