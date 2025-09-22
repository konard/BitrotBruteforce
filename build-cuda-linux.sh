#!/bin/bash

# Build script for CUDA modules on Linux
# This script builds the CUDA modules for Linux x64

set -e

echo "Building CUDA modules for Linux..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if CUDA is installed
if ! command -v nvcc &> /dev/null; then
    echo -e "${RED}Error: CUDA toolkit is not installed or nvcc is not in PATH${NC}"
    echo "Please install CUDA toolkit from: https://developer.nvidia.com/cuda-downloads"
    exit 1
fi

# Check if cmake is installed
if ! command -v cmake &> /dev/null; then
    echo -e "${RED}Error: CMake is not installed${NC}"
    echo "Please install CMake: sudo apt-get install cmake (Ubuntu/Debian) or equivalent for your distro"
    exit 1
fi

# Print CUDA version
echo -e "${GREEN}Found CUDA version:${NC}"
nvcc --version | grep "release"

# Set build type (default to Release)
BUILD_TYPE=${1:-Release}
echo -e "${GREEN}Building in $BUILD_TYPE mode${NC}"

# Function to build a CUDA module
build_cuda_module() {
    local module_name=$1
    local module_dir=$2

    echo -e "${YELLOW}Building $module_name...${NC}"

    # Create build directory
    mkdir -p "$module_dir/build"
    cd "$module_dir/build"

    # Configure with CMake
    cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE ..

    # Build
    cmake --build . --config $BUILD_TYPE -j$(nproc)

    # Copy the built library to the expected location
    mkdir -p "../bin/x64/$BUILD_TYPE"
    if [ -f "bin/libCuda${module_name#Cuda}.so" ]; then
        cp "bin/libCuda${module_name#Cuda}.so" "../bin/x64/$BUILD_TYPE/Cuda${module_name#Cuda}.dll"
        echo -e "${GREEN}Successfully built $module_name${NC}"
    else
        echo -e "${RED}Failed to build $module_name${NC}"
        exit 1
    fi

    cd ../..
}

# Build CudaAlignedBitrotFinder
build_cuda_module "CudaAlignedBitrotFinder" "CudaAlignedBitrotFinder"

# Build CudaUnalignedBitrotFinder
build_cuda_module "CudaUnalignedBitrotFinder" "CudaUnalignedBitrotFinder"

echo -e "${GREEN}All CUDA modules built successfully!${NC}"
echo -e "${GREEN}Libraries are located in:${NC}"
echo "  - CudaAlignedBitrotFinder/bin/x64/$BUILD_TYPE/"
echo "  - CudaUnalignedBitrotFinder/bin/x64/$BUILD_TYPE/"