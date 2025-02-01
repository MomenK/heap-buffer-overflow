# Define the C++ compiler command with debug symbols (-g) and AddressSanitizer enabled.
CXX := g++ -g -fsanitize=address -Wall

################################################################################
# Targets to compile the library source file (lib.c)
################################################################################

# Build lib.o with the preprocessor flag -DCOND defined.
# This might change the behavior or structure definitions in lib.c.
lib_cond:
	$(CXX) -c lib.c -o lib.o -DCOND

# Build lib.o without any preprocessor flag.
# The code in lib.c is compiled without the conditional definitions.
lib_uncond:
	$(CXX) -c lib.c -o lib.o

################################################################################
# Targets to build the main executable (main) linking with lib.o
################################################################################

# Build main executable with -DCOND defined.
# Both main.c and lib.o expect the conditionally compiled behavior.
main_cond:
	$(CXX) main.c lib.o -o main -DCOND

# Build main executable without -DCOND defined.
# main.c is compiled without the conditional flag, which might be inconsistent
# with lib.o if lib.o was built with -DCOND.
main_uncond:
	$(CXX) main.c lib.o -o main

################################################################################
# Combined target to simulate a segmentation fault scenario
#
# "main_segfault" builds the library with -DCOND (lib_cond) but then builds main
# without -DCOND (main_uncond). This inconsistency can cause a segmentation fault.
################################################################################

main_segfault: lib_cond main_uncond

################################################################################
# Clean up target
################################################################################

# .PHONY indicates that 'clean' is not a file name but a command.
.PHONY: clean
clean:
	rm -f lib.o main

################################################################################
# Run targets to execute the built executable
################################################################################

# 'run' target cleans the build, compiles the library with -DCOND and main without -DCOND,
# then runs the resulting executable. This configuration is intended to cause a segfault.
.PHONY: run
run: clean main_segfault
	./main

# 'run_fine' target cleans the build, compiles both the library and main with -DCOND,
# then runs the executable. This configuration should run correctly without a segfault.
.PHONY: run_fine
run_fine: clean lib_cond main_cond
	./main
