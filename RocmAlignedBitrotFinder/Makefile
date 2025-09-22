# Makefile for ROCm Aligned Bitrot Finder
# Supports both Windows (cross-compile via MinGW) and Linux

# Detect OS
UNAME_S := $(shell uname -s)

# HIP compiler
HIPCC ?= hipcc

# Common flags
HIPFLAGS = -O3 -std=c++14
LDFLAGS =

# Source files
SOURCES = kernel.cpp sha1.cpp
OBJECTS = $(SOURCES:.cpp=.o)

# Library name
ifeq ($(OS),Windows_NT)
    TARGET = RocmAlignedBitrotFinder.dll
    HIPFLAGS += -shared -fPIC
    LDFLAGS += -shared
else ifeq ($(UNAME_S),Linux)
    TARGET = libRocmAlignedBitrotFinder.so
    HIPFLAGS += -shared -fPIC
    LDFLAGS += -shared
endif

# Executable for testing
TEST_TARGET = test_rocm_aligned

# Default target
all: $(TARGET)

# Build shared library
$(TARGET): $(OBJECTS)
	$(HIPCC) $(LDFLAGS) -o $@ $^
	@echo "Built $(TARGET) successfully"

# Build test executable
test: $(SOURCES)
	$(HIPCC) $(HIPFLAGS) -o $(TEST_TARGET) $(SOURCES)
	@echo "Built test executable $(TEST_TARGET)"

# Pattern rule for object files
%.o: %.cpp
	$(HIPCC) $(HIPFLAGS) -c $< -o $@

# Cross-compilation for Windows (requires MinGW and Wine for testing)
windows: HIPCC = x86_64-w64-mingw32-g++
windows: HIPFLAGS = -O3 -std=c++14 -shared -D__HIP_PLATFORM_CPU__
windows: TARGET = RocmAlignedBitrotFinder.dll
windows: $(TARGET)

# Clean
clean:
	rm -f $(OBJECTS) $(TARGET) $(TEST_TARGET)

# Install (Linux only)
install: $(TARGET)
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		mkdir -p /usr/local/lib; \
		cp $(TARGET) /usr/local/lib/; \
		ldconfig; \
		echo "Installed $(TARGET) to /usr/local/lib"; \
	else \
		echo "Install target only supported on Linux"; \
	fi

.PHONY: all clean test windows install