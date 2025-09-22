# Cross-Compilation Setup for Linux x64 from Windows

This document describes how to set up cross-compilation for Linux x64 CUDA modules from Windows.

## Prerequisites

### Required Software on Windows

1. **Visual Studio 2022** with:
   - Desktop development with C++
   - .NET desktop development

2. **CUDA Toolkit 12.6 or later**
   - Download from: https://developer.nvidia.com/cuda-downloads
   - Ensure CUDA_PATH environment variable is set

3. **.NET 8 SDK**
   - Download from: https://dotnet.microsoft.com/download

4. **Cross-compilation toolchain** (choose one):

   **Option A: MinGW-w64 with Linux target**
   ```powershell
   # Install via Chocolatey
   choco install mingw
   ```

   **Option B: WSL2 (Windows Subsystem for Linux)**
   - Enable WSL2 in Windows Features
   - Install Ubuntu from Microsoft Store
   - Inside WSL2, install:
     ```bash
     sudo apt update
     sudo apt install gcc g++ make cmake
     # Install CUDA Toolkit for Linux in WSL2
     wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
     sudo dpkg -i cuda-keyring_1.1-1_all.deb
     sudo apt update
     sudo apt install cuda-toolkit-12-6
     ```

## Building for Linux x64

### Using Visual Studio 2022 or Rider

1. Open the solution in Visual Studio 2022 or JetBrains Rider

2. To publish for Linux x64:
   - In Visual Studio: Right-click on Bruteforce project → Publish → Select "linux-x64" profile
   - In Rider: Right-click on Bruteforce project → Publish → Runtime: linux-x64

3. The build process will automatically:
   - Detect if you're cross-compiling (Windows → Linux)
   - Build CUDA modules using the cross-compilation toolchain
   - Package everything for Linux deployment

### Using Command Line

```powershell
# From the solution root directory
dotnet publish Bruteforce/Bruteforce.csproj -c Release -r linux-x64 --self-contained
```

## Verification

After successful build, you should have:
- `bin/Release/net8.0/linux-x64/publish/` - Main application for Linux
- `libs/CudaAlignedBitrotFinder.so` - CUDA module for aligned search
- `libs/CudaUnalignedBitrotFinder.so` - CUDA module for unaligned search

## Troubleshooting

### CUDA_PATH not found
Ensure CUDA Toolkit is installed and the CUDA_PATH environment variable is set:
```powershell
echo $env:CUDA_PATH
```

### Cross-compiler not found
If you don't have a Linux cross-compiler, the build will attempt to use WSL2. Ensure WSL2 is installed with CUDA support.

### Build fails with "nvcc not found"
Verify CUDA installation:
```powershell
nvcc --version
```

## Deployment to Linux

Transfer the published files to your Linux machine:
```bash
# On Linux machine
chmod +x Bruteforce
./Bruteforce --help
```

Ensure the target Linux machine has:
- CUDA drivers installed
- Compatible NVIDIA GPU
- glibc 2.27 or later