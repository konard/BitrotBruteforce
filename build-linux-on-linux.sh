#!/bin/bash
# This script must be run on a Linux machine with CUDA Toolkit installed

set -e

echo "Building CUDA modules for Linux..."

# Check CUDA installation
if [ ! -d /usr/local/cuda ]; then
    echo "Error: CUDA Toolkit not found at /usr/local/cuda"
    exit 1
fi

export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Build CudaAlignedBitrotFinder
echo "Building CudaAlignedBitrotFinder..."
cd CudaAlignedBitrotFinder
mkdir -p bin/linux-x64
nvcc -shared -Xcompiler -fPIC \
    -gencode arch=compute_52,code=sm_52 \
    -gencode arch=compute_60,code=sm_60 \
    -gencode arch=compute_70,code=sm_70 \
    -gencode arch=compute_75,code=sm_75 \
    -gencode arch=compute_80,code=sm_80 \
    -gencode arch=compute_86,code=sm_86 \
    -O3 --use_fast_math \
    kernel.cu sha1.cu \
    -o bin/linux-x64/CudaAlignedBitrotFinder.so

# Build CudaUnalignedBitrotFinder
echo "Building CudaUnalignedBitrotFinder..."
cd ../CudaUnalignedBitrotFinder
mkdir -p bin/linux-x64
nvcc -shared -Xcompiler -fPIC \
    -gencode arch=compute_52,code=sm_52 \
    -gencode arch=compute_60,code=sm_60 \
    -gencode arch=compute_70,code=sm_70 \
    -gencode arch=compute_75,code=sm_75 \
    -gencode arch=compute_80,code=sm_80 \
    -gencode arch=compute_86,code=sm_86 \
    -O3 --use_fast_math \
    kernel.cu sha1.cu \
    -o bin/linux-x64/CudaUnalignedBitrotFinder.so

cd ..
echo "Build completed successfully!"
echo "The .so files are ready in:"
echo "  - CudaAlignedBitrotFinder/bin/linux-x64/CudaAlignedBitrotFinder.so"
echo "  - CudaUnalignedBitrotFinder/bin/linux-x64/CudaUnalignedBitrotFinder.so"