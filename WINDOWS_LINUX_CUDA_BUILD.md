# Windows to Linux CUDA Cross-Platform Support

This guide explains how to support both Windows and Linux CUDA deployments.

## Overview

The solution uses native CUDA libraries (.dll for Windows, .so for Linux) with automatic cross-platform loading.

## Requirements

### On Windows Development Machine

1. **.NET 8.0 SDK**
   - Download from: https://dotnet.microsoft.com/download

2. **Visual Studio 2022**
   - With CUDA development tools installed
   - Required for building Windows CUDA modules

3. **CUDA Toolkit**
   - Download from: https://developer.nvidia.com/cuda-downloads
   - Required for compiling CUDA modules

### On Linux Target Machine

1. **NVIDIA GPU Driver** (version 450.0 or later)
2. **CUDA Runtime Libraries**
3. **.NET 8.0 Runtime**

## Building CUDA Libraries

### Windows Libraries (.dll)

Windows CUDA libraries are built automatically with the solution:
- `CudaAlignedBitrotFinder.dll`
- `CudaUnalignedBitrotFinder.dll`

These are placed in `libs/` folder during build.

### Linux Libraries (.so)

Linux libraries must be built on a Linux machine or via GitHub Actions.

#### Option 1: Download from GitHub Actions

1. Go to the [Actions tab](../../actions) in the repository
2. Find the latest successful workflow with Linux builds
3. Download the artifact containing:
   - `CudaAlignedBitrotFinder.so`
   - `CudaUnalignedBitrotFinder.so`
4. Place these files in `Bruteforce/libs/`

#### Option 2: Build on Linux Machine

On a Linux machine with CUDA Toolkit installed:

```bash
# Install CUDA Toolkit if not already installed
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-0

# Build the CUDA modules
cd CudaAlignedBitrotFinder
nvcc -shared -fPIC -o CudaAlignedBitrotFinder.so kernel.cu -O3

cd ../CudaUnalignedBitrotFinder
nvcc -shared -fPIC -o CudaUnalignedBitrotFinder.so kernel.cu -O3

# Copy to libs folder
cp CudaAlignedBitrotFinder.so ../Bruteforce/libs/
cp CudaUnalignedBitrotFinder.so ../Bruteforce/libs/
```

## Publishing for Linux from Windows

### From Visual Studio/Rider

1. Right-click on the Bruteforce project
2. Select **Publish** → **linux-x64**
3. Ensure the Linux .so files are in `Bruteforce/libs/`
4. Deploy the published folder to Linux

### From Command Line

```powershell
# From the solution root directory
dotnet publish Bruteforce -r linux-x64 -c Release --self-contained
```

## How It Works

The solution uses .NET's `NativeLibrary.SetDllImportResolver` to automatically load the correct library based on the platform:

- **Windows**: Loads `.dll` files from `libs/` folder
- **Linux**: Loads `.so` files from `libs/` folder

The library loading is handled transparently in `BruteforceCuda.cs`:

```csharp
// Automatically selects correct library based on OS
if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
    // Load .so file
else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
    // Load .dll file
```

## Troubleshooting

### "CUDA libraries not found on Linux"

Ensure that:
1. The .so files are present in the `libs/` folder
2. CUDA runtime is installed on the Linux machine
3. The .so files have execute permissions: `chmod +x *.so`

### "CUDA libraries not found" on Windows

Ensure that:
1. CUDA Toolkit is installed
2. Visual Studio has been configured for CUDA development
3. The Windows CUDA projects have been built successfully

## Testing

To test the cross-platform support:

1. Build on Windows: `dotnet build -c Release`
2. Publish for Linux: `dotnet publish -r linux-x64 -c Release`
3. Copy published folder to Linux machine
4. Run on Linux: `./Bruteforce [torrent-file]`