# Windows to Linux CUDA Cross-Compilation Guide

This guide explains how to build Linux CUDA modules from a Windows development environment.

## Overview

This solution provides two approaches for cross-platform CUDA deployment:

1. **Primary**: Pre-compiled Linux .so files (built via GitHub Actions or Linux machine)
2. **Fallback**: PTX (Parallel Thread Execution) intermediate code for JIT compilation

## Solution Architecture

### Approach 1: Pre-compiled Linux Binaries (Recommended)

Linux .so files are built on a Linux environment (GitHub Actions or local Linux machine) and included in the Windows build process.

**Advantages:**
- Native performance on Linux
- No JIT compilation overhead
- Guaranteed compatibility

**Process:**
1. GitHub Actions workflow builds .so files on Ubuntu with CUDA Toolkit
2. .so files are downloaded and placed in `Bruteforce/libs/`
3. Windows developers include these when publishing for Linux

### Approach 2: PTX Intermediate Code (Fallback)

When .so files are not available, PTX code can be generated on Windows and JIT-compiled on Linux.

**Advantages:**
- Can be generated on Windows without Linux toolchain
- Platform-independent format
- Automatic optimization for target GPU

**Limitations:**
- Requires JIT compilation on first run
- Slightly slower initial startup

## Requirements

### On Windows Development Machine

1. **.NET 8.0 SDK**
   - Download from: https://dotnet.microsoft.com/download

2. **Visual Studio 2022** or **JetBrains Rider**
   - For IDE integration with the Publish button

3. **CUDA Toolkit** (Optional - only for PTX fallback)
   - Download from: https://developer.nvidia.com/cuda-downloads
   - Default installation path: `C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.0`

### On Linux Target Machine

1. **NVIDIA GPU Driver** (version 450.0 or later)
2. **CUDA Runtime**
3. **.NET 8.0 Runtime**

## Usage

### From IDE (Recommended)

1. Right-click on the Bruteforce project
2. Select **Publish** → **linux-x64**
3. The build system automatically:
   - Uses pre-built .so files if available in `Bruteforce/libs/`
   - Falls back to PTX compilation if needed
4. Deploy the published folder to Linux

### From Command Line

```powershell
# From the solution root directory
dotnet publish Bruteforce -r linux-x64 -c Release --self-contained
```

## Getting Linux .so Files

### Option 1: Download from GitHub Actions (Easiest)

1. Go to the [Actions tab](../../actions) in the repository
2. Find the latest successful "CUDA Cross-Compilation" workflow
3. Download the `linux-cuda-libs` artifact
4. Extract the .so files to `Bruteforce/libs/`

### Option 2: Build on Linux Machine

On a Linux machine with CUDA Toolkit installed:

```bash
# Install CUDA Toolkit if not already installed
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-0

# Create output directory
mkdir -p linux-libs

# Compile CudaAlignedBitrotFinder
nvcc -shared -Xcompiler -fPIC \
  -o linux-libs/CudaAlignedBitrotFinder.so \
  CudaAlignedBitrotFinder/kernel.cu CudaAlignedBitrotFinder/sha1.cu \
  -arch=sm_50 -O3

# Compile CudaUnalignedBitrotFinder
nvcc -shared -Xcompiler -fPIC \
  -o linux-libs/CudaUnalignedBitrotFinder.so \
  CudaUnalignedBitrotFinder/kernel.cu CudaUnalignedBitrotFinder/sha1.cu \
  -arch=sm_50 -O3
```

Copy the generated .so files to `Bruteforce/libs/` in your Windows development environment.

## Project Structure

```
BitrotBruteforce/
├── CompileCudaToPtx.ps1          # PTX compilation script (fallback)
├── CudaAlignedBitrotFinder/      # CUDA source for aligned data
├── CudaUnalignedBitrotFinder/    # CUDA source for unaligned data
├── Bruteforce/
│   ├── BruteforceCuda.cs         # Cross-platform CUDA interface
│   ├── CudaPtxLoader.cs          # Runtime PTX loader (fallback)
│   └── libs/                     # Native libraries location
│       ├── *.dll                 # Windows CUDA libraries
│       └── *.so                  # Linux CUDA libraries (place here)
└── .github/workflows/
    └── cuda-cross-compile.yml    # Automated Linux .so building
```

## How It Works

### Runtime Library Selection

The `BruteforceCuda.cs` class automatically selects the appropriate library:

1. **On Windows**: Loads .dll files from `libs/`
2. **On Linux**:
   - First tries to load .so files from `libs/`
   - Falls back to PTX JIT compilation if .so files not found
   - Uses CUDA Driver API for PTX loading

### Cross-Platform Library Loading

The solution uses `NativeLibrary.SetDllImportResolver` to dynamically resolve library paths based on the operating system, ensuring seamless operation on both Windows and Linux.

## Published Package Structure

After publishing for Linux, the output contains:

```
linux-x64/publish/
├── Bruteforce                    # Main executable
├── libs/
│   ├── libcrypto-3-x64_cl.so   # OpenSSL library
│   ├── CudaAlignedBitrotFinder.so    # CUDA aligned module
│   └── CudaUnalignedBitrotFinder.so  # CUDA unaligned module
├── ptx/                          # PTX files (fallback)
│   └── *.ptx
└── [other .NET runtime files]
```

## Troubleshooting

### Linux .so Files Not Found
- Check GitHub Actions artifacts for pre-built files
- Build manually on a Linux machine with CUDA Toolkit
- System will automatically fall back to PTX if available

### CUDA Toolkit Not Found (Windows, PTX compilation)
- Only needed if not using pre-built .so files
- Verify installation: `C:\Program Files\NVIDIA GPU Computing Toolkit\`
- Set `CUDA_PATH` environment variable if using non-standard location

### Linux Runtime Issues
```bash
# Verify CUDA driver
nvidia-smi

# Check for CUDA libraries
ldconfig -p | grep cuda

# List available .so files
ls -la libs/*.so

# Check executable permissions
chmod +x Bruteforce
```

### Library Loading Errors
- Ensure .so files have correct permissions: `chmod 755 libs/*.so`
- Check library dependencies: `ldd libs/CudaAlignedBitrotFinder.so`
- Review application logs for detailed error messages

## CI/CD Integration

The solution includes comprehensive GitHub Actions workflows:

1. **build-linux-cuda**: Automatically builds .so files on Ubuntu with CUDA
2. **cross-compile-cuda**: Tests the complete Windows to Linux publishing pipeline
3. **test-windows-linux-publish**: Validates published artifacts

### Using CI/CD Artifacts

The GitHub Actions workflow automatically:
1. Builds Linux .so files on each push
2. Stores them as downloadable artifacts
3. Uses them in Windows publishing tests

## Technical Details

### Compilation Parameters
- `-arch=sm_50`: Targets Maxwell GPUs and newer for broad compatibility
- `-O3`: Maximum optimization for release builds
- `-Xcompiler -fPIC`: Position-independent code required for .so files
- `-shared`: Creates shared library

### Supported GPU Architectures
- sm_50: Maxwell (GTX 750, GTX 900 series)
- sm_60: Pascal (GTX 1000 series)
- sm_70: Volta (V100)
- sm_75: Turing (RTX 2000 series, GTX 1600 series)
- sm_80: Ampere (RTX 3000 series)
- sm_90: Hopper (H100)

Binaries compiled for sm_50 are forward-compatible with all newer architectures.

### Performance Considerations

**Using .so files:**
- Native performance
- No startup delay
- Optimal for production

**Using PTX fallback:**
- ~100-500ms JIT compilation on first run
- Compiled kernels cached by CUDA driver
- Runtime performance identical to native after JIT

## References

- [NVIDIA CUDA Toolkit Documentation](https://docs.nvidia.com/cuda/)
- [CUDA Driver API](https://docs.nvidia.com/cuda/cuda-driver-api/)
- [PTX ISA Documentation](https://docs.nvidia.com/cuda/parallel-thread-execution/)
- [Building Cross-Platform CUDA Applications](https://developer.nvidia.com/blog/building-cuda-applications-cmake/)