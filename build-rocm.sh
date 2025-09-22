#!/bin/bash

# Build script for ROCm modules
# Supports both native Linux builds and cross-compilation for Windows

set -e

echo "Building ROCm modules..."

# Function to check if hipcc is available
check_hipcc() {
    if ! command -v hipcc &> /dev/null; then
        echo "WARNING: hipcc not found. ROCm modules will not be built."
        echo "To install ROCm, visit: https://docs.amd.com/bundle/ROCm-Installation-Guide/page/Overview_of_ROCm_Installation_Methods.html"
        return 1
    fi
    return 0
}

# Build for Linux
build_linux() {
    echo "Building ROCm modules for Linux..."

    # Build aligned module
    echo "Building RocmAlignedBitrotFinder..."
    cd RocmAlignedBitrotFinder
    make clean 2>/dev/null || true
    make

    # Copy to libs directory
    mkdir -p ../Bruteforce/libs
    cp libRocmAlignedBitrotFinder.so ../Bruteforce/libs/ || true
    cd ..

    # Build unaligned module
    echo "Building RocmUnalignedBitrotFinder..."
    cd RocmUnalignedBitrotFinder
    make clean 2>/dev/null || true
    make

    # Copy to libs directory
    cp libRocmUnalignedBitrotFinder.so ../Bruteforce/libs/ || true
    cd ..

    echo "Linux ROCm modules built successfully!"
}

# Build for Windows (cross-compilation)
build_windows() {
    echo "Building ROCm modules for Windows (cross-compilation)..."

    # Check if MinGW is available
    if ! command -v x86_64-w64-mingw32-g++ &> /dev/null; then
        echo "WARNING: MinGW cross-compiler not found. Windows builds will be skipped."
        echo "To install: sudo apt-get install mingw-w64"
        return
    fi

    # Build aligned module
    echo "Building RocmAlignedBitrotFinder.dll..."
    cd RocmAlignedBitrotFinder
    make clean 2>/dev/null || true
    make windows

    # Copy to libs directory
    mkdir -p ../Bruteforce/libs
    cp RocmAlignedBitrotFinder.dll ../Bruteforce/libs/ || true
    cd ..

    # Build unaligned module
    echo "Building RocmUnalignedBitrotFinder.dll..."
    cd RocmUnalignedBitrotFinder
    make clean 2>/dev/null || true
    make windows

    # Copy to libs directory
    cp RocmUnalignedBitrotFinder.dll ../Bruteforce/libs/ || true
    cd ..

    echo "Windows ROCm modules built successfully!"
}

# Main build process
main() {
    # Detect OS
    OS_TYPE=$(uname -s)

    if [ "$OS_TYPE" == "Linux" ]; then
        echo "Detected Linux system"

        # Check if HIP/ROCm is available
        if check_hipcc; then
            build_linux
        else
            echo "Attempting CPU-only fallback build..."
            # You could add a CPU-only build option here if desired
        fi

        # Optionally build Windows version if cross-compilation is available
        if [ "$1" == "--cross-compile" ] || [ "$1" == "-x" ]; then
            build_windows
        fi

    elif [[ "$OS_TYPE" == *"MINGW"* ]] || [[ "$OS_TYPE" == *"MSYS"* ]]; then
        echo "Detected Windows system (MinGW/MSYS)"
        echo "Please use Visual Studio or the provided .vcxproj files for Windows builds"

    elif [ "$OS_TYPE" == "Darwin" ]; then
        echo "macOS is not yet supported for ROCm builds"
        exit 1

    else
        echo "Unsupported operating system: $OS_TYPE"
        exit 1
    fi
}

# Parse command line arguments
case "$1" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --cross-compile, -x    Also build Windows DLLs via cross-compilation"
        echo "  --help, -h            Show this help message"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac