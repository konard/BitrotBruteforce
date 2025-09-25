# Windows to Linux CUDA Cross-Compilation

This document describes how to build Linux-compatible CUDA modules from Windows using PTX (Parallel Thread Execution) intermediate code.

## Overview

Since direct cross-compilation of CUDA from Windows to Linux is not supported by NVIDIA's toolchain, we use PTX as an intermediate format. PTX is a platform-independent representation that can be JIT-compiled on the target platform.

## Prerequisites

### Windows Development Machine
1. **Visual Studio 2022** with C++ development tools
2. **NVIDIA CUDA Toolkit 11.8+** - [Download](https://developer.nvidia.com/cuda-downloads)
3. **.NET SDK 8.0** - [Download](https://dotnet.microsoft.com/download/dotnet/8.0)
4. **PowerShell 5.0+** (included in Windows)

### Target Linux Machine
- NVIDIA GPU driver installed
- CUDA runtime libraries (cuda-runtime package)
- .NET 8.0 runtime

## Build Process

### 1. One-Click Build from IDE

#### Visual Studio 2022
1. Right-click on the Bruteforce project
2. Select **Publish**
3. Choose **linux-x64** as the target runtime
4. Click **Publish**

#### JetBrains Rider
1. Right-click on the Bruteforce project
2. Select **Publish**
3. Choose **linux-x64** profile
4. Click **Run**

The build process automatically:
- Compiles CUDA code to PTX format
- Packages PTX files with the application
- Creates a Linux-compatible executable

### 2. Command Line Build

```powershell
# From the solution root directory
dotnet publish Bruteforce -r linux-x64 -c Release --self-contained
```

### 3. Manual PTX Compilation (Optional)

If you need to compile PTX files manually:

```powershell
# From the solution root directory
.\CompileCudaToPtx.ps1
```

This creates PTX files in the `ptx/` directory.

## How It Works

1. **Compilation to PTX**: The PowerShell script uses NVCC to compile CUDA code to PTX format instead of binary cubin files.

2. **PTX Packaging**: PTX files are included in the published application as content files.

3. **Runtime JIT Compilation**: On Linux, the application uses CUDA Driver API to:
   - Load PTX files at runtime
   - JIT compile them for the specific GPU
   - Execute the compiled kernels

4. **Fallback Support**: On Windows, the application uses native DLLs. On Linux without PTX files, it falls back to CPU computation.

## Architecture Support

The PTX files are compiled with `sm_50` architecture for broad compatibility:
- Maxwell (GTX 900 series)
- Pascal (GTX 1000 series)
- Volta (Tesla V100)
- Turing (RTX 2000 series)
- Ampere (RTX 3000 series)
- Ada Lovelace (RTX 4000 series)

## Deployment

The published Linux package includes:
```
Bruteforce                  # Main executable
libs/
  ├── libcrypto-*.so        # Crypto libraries
ptx/
  ├── kernel_aligned.ptx    # Aligned kernel PTX
  ├── kernel_unaligned.ptx  # Unaligned kernel PTX
  ├── sha1_aligned.ptx      # SHA1 aligned PTX
  └── sha1_unaligned.ptx    # SHA1 unaligned PTX
```

## Troubleshooting

### CUDA Toolkit Not Found
Ensure CUDA Toolkit is installed and the `CUDA_PATH` environment variable is set:
```powershell
echo $env:CUDA_PATH
```

### PTX Files Not Generated
Run the PowerShell script manually and check for errors:
```powershell
.\CompileCudaToPtx.ps1 -Verbose
```

### Linux Runtime Errors
Verify CUDA is properly installed on the Linux machine:
```bash
nvidia-smi
ldconfig -p | grep cuda
```

## Technical Details

### PTX vs Binary Compilation
- **PTX**: Platform-independent, JIT-compiled, forward-compatible
- **Cubin**: Platform-specific, pre-compiled, requires exact architecture match

### Performance Considerations
- Initial JIT compilation adds ~100-500ms startup time
- Compiled kernels are cached by the CUDA driver
- Runtime performance is identical to pre-compiled binaries

## References
- [NVIDIA PTX ISA Documentation](https://docs.nvidia.com/cuda/parallel-thread-execution/)
- [CUDA Driver API](https://docs.nvidia.com/cuda/cuda-driver-api/)
- [Building Cross-Platform CUDA Applications](https://developer.nvidia.com/blog/building-cuda-applications-cmake/)