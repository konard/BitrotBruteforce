# CUDA Cross-Compilation: Windows to Linux

This document describes the cross-compilation setup for building Linux CUDA modules from Windows.

## Overview

The project now supports cross-compilation of CUDA modules for Linux directly from Windows. This allows developers to use the "Publish" button in Visual Studio or Rider to create Linux-compatible builds without needing WSL, Docker, or a Linux VM.

## Prerequisites

### Required Software
1. **CUDA Toolkit 12.0+** - Install from [NVIDIA Developer](https://developer.nvidia.com/cuda-downloads)
2. **.NET SDK 8.0+** - For building the C# application
3. **Visual Studio 2022** or **JetBrains Rider** - For IDE integration

### Optional (for enhanced cross-compilation)
- MinGW-w64 (for Linux-compatible GCC on Windows)
- MSYS2 (for additional Linux toolchain components)

## How It Works

The cross-compilation system uses a multi-strategy approach:

### Strategy 1: Direct NVCC Cross-Compilation
Attempts to use NVCC directly with Linux target flags to generate .so files:
```powershell
nvcc -m64 --shared -Xcompiler -fPIC --generate-code=arch=compute_52,code=sm_52 -o module.so
```

### Strategy 2: Relocatable Device Code
Generates relocatable device code (.rdc files) that can be linked on Linux:
```powershell
nvcc -rdc=true -m64 -c kernel.cu -o module.rdc
```

### Strategy 3: PTX Generation (Fallback)
Generates platform-independent PTX code for runtime compilation:
```powershell
nvcc -ptx -m64 kernel.cu -o module.ptx
```

## Usage

### From IDE (Visual Studio/Rider)

1. Right-click on the Bruteforce project
2. Select "Publish"
3. Choose target: `linux-x64`
4. Click "Publish"

The MSBuild integration will automatically:
- Detect Linux target
- Run cross-compilation PowerShell script
- Include generated .so/.ptx files in the output

### From Command Line

```powershell
# Build and publish for Linux
dotnet publish -c Release -r linux-x64 --self-contained

# Or run the cross-compilation script directly
.\CrossCompileLinuxCuda.ps1 -Configuration Release -RuntimeIdentifier linux-x64
```

### From GitHub Actions

The project includes a GitHub Actions workflow that:
1. Installs CUDA on Windows runner
2. Performs cross-compilation
3. Publishes Linux binaries as artifacts

## Architecture Support

The cross-compilation generates code for multiple GPU architectures:
- Compute 5.2 (Maxwell)
- Compute 6.1 (Pascal)
- Compute 7.0 (Volta)
- Compute 7.5 (Turing)
- Compute 8.0 (Ampere)
- Compute 8.6 (Ampere)
- Compute 8.9 (Ada Lovelace)

## Files Generated

After successful cross-compilation, you'll find:

```
CudaAlignedBitrotFinder/
  bin/
    linux-x64/
      CudaAlignedBitrotFinder.so     # Linux shared library (if successful)
      CudaAlignedBitrotFinder.ptx    # PTX code (fallback)
      CudaAlignedBitrotFinder.rdc    # Relocatable device code
      link_*.sh                       # Linux link scripts

CudaUnalignedBitrotFinder/
  bin/
    linux-x64/
      CudaUnalignedBitrotFinder.so   # Linux shared library (if successful)
      CudaUnalignedBitrotFinder.ptx  # PTX code (fallback)
      CudaUnalignedBitrotFinder.rdc  # Relocatable device code
      link_*.sh                      # Linux link scripts
```

## Troubleshooting

### CUDA Not Found
Ensure CUDA_PATH environment variable is set:
```powershell
echo $env:CUDA_PATH
# Should output: C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.x
```

### Cross-Compilation Fails
If direct cross-compilation fails, the system falls back to PTX generation. The PTX files can be compiled on the target Linux system.

### Missing Linux Toolchain
For best results, install MinGW-w64:
```powershell
choco install mingw
```

## Technical Limitations

True CUDA cross-compilation from Windows to Linux has inherent limitations:
- NVCC requires a host compiler compatible with the target platform
- Windows lacks native Linux ELF binary support
- Some features require runtime compilation on Linux

The solution uses multiple strategies to work around these limitations while maintaining a seamless developer experience.

## Contributing

To improve cross-compilation support:
1. Test with different CUDA versions
2. Add support for more GPU architectures
3. Enhance PTX runtime loader
4. Improve error handling and diagnostics