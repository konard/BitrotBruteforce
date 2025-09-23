# Linux CUDA Module

This directory should contain `CudaAlignedBitrotFinder.so` built on a Linux machine.

## Building

On a Linux machine with CUDA Toolkit:

```bash
cd ../../  # Go to CudaAlignedBitrotFinder directory
nvcc -shared -Xcompiler -fPIC kernel.cu sha1.cu -o bin/linux-x64/CudaAlignedBitrotFinder.so
```

Or use the build script from project root:
```bash
./build-linux-on-linux.sh
```

The built .so file should be committed to the repository so Windows users can publish for Linux.