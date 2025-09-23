# Testing Linux Support from Windows

## Testing Approach

Since we're using pre-built Linux binaries approach, the testing consists of two phases:

### Phase 1: Building Linux .so files (on Linux)

1. **On a Linux machine with CUDA SDK installed:**
```bash
# Clone the repository
git clone https://github.com/1dNDN/BitrotBruteforce.git
cd BitrotBruteforce

# Run the build script
./build-linux-on-linux.sh

# Verify .so files are created
ls -la CudaAlignedBitrotFinder/bin/linux-x64/
ls -la CudaUnalignedBitrotFinder/bin/linux-x64/
```

Expected output:
- `CudaAlignedBitrotFinder.so`
- `CudaUnalignedBitrotFinder.so`

### Phase 2: Publishing from Windows (on Windows)

1. **Prerequisites on Windows:**
   - Visual Studio 2022 or Rider
   - .NET 8.0 SDK
   - CUDA Toolkit (for building Windows version)

2. **Building and Publishing:**

```powershell
# Clone repository with Linux .so files included
git clone https://github.com/1dNDN/BitrotBruteforce.git
cd BitrotBruteforce

# Build Windows version first (to ensure everything compiles)
dotnet build -c Release

# Publish for Linux
dotnet publish -r linux-x64 --self-contained -c Release

# Check output directory
dir .\Bruteforce\bin\Release\net8.0\linux-x64\publish\libs\
```

Expected files in `libs/`:
- `CudaAlignedBitrotFinder.so`
- `CudaUnalignedBitrotFinder.so`
- `libcrypto-3-x64_cl.so`

### Phase 3: Testing on Linux

1. **Copy published files to Linux machine:**
```bash
# On Linux machine
scp -r user@windows:/path/to/publish/* /opt/bruteforce/
cd /opt/bruteforce

# Run the application
./Bruteforce --help

# Test with sample data
./Bruteforce check ./BitrotTestSet/
```

## Testing in VM (Optional)

If you want to test in a VM environment:

### Windows in QEMU:
```bash
# Install QEMU on Linux
sudo apt-get install qemu-kvm qemu-utils

# Create Windows VM (requires Windows ISO)
qemu-img create -f qcow2 windows.qcow2 50G
qemu-system-x86_64 -enable-kvm -m 8G -hda windows.qcow2 -cdrom windows.iso

# Inside Windows VM:
# 1. Install Visual Studio 2022
# 2. Install .NET 8.0 SDK
# 3. Install CUDA Toolkit
# 4. Clone repository and test publishing
```

### Linux testing:
```bash
# Test on native Linux or in container
docker run --gpus all -it nvidia/cuda:12.0-devel-ubuntu22.04

# Inside container
apt-get update && apt-get install -y dotnet-sdk-8.0
# Copy published files and test
```

## Verification Checklist

- [ ] Windows build completes successfully
- [ ] Linux publish includes .so files in libs/ directory
- [ ] Published application runs on Linux
- [ ] CUDA detection works on Linux with GPU
- [ ] Hash bruteforce functionality works correctly

## Known Limitations

1. **Cross-compilation limitation:** True cross-compilation of CUDA from Windows to Linux is not technically possible without Linux toolchain
2. **Pre-built binaries:** Solution uses pre-built .so files that must be compiled on Linux machine
3. **CUDA dependency:** Target Linux machine must have CUDA runtime installed

## CI/CD Alternative

For automated building of Linux binaries, consider GitHub Actions:

```yaml
name: Build Linux CUDA Modules
on:
  push:
    paths:
      - 'CudaAlignedBitrotFinder/**'
      - 'CudaUnalignedBitrotFinder/**'

jobs:
  build-linux:
    runs-on: ubuntu-latest
    container: nvidia/cuda:12.0-devel-ubuntu22.04
    steps:
      - uses: actions/checkout@v3
      - run: ./build-linux-on-linux.sh
      - uses: actions/upload-artifact@v3
        with:
          name: linux-cuda-modules
          path: |
            CudaAlignedBitrotFinder/bin/linux-x64/*.so
            CudaUnalignedBitrotFinder/bin/linux-x64/*.so
```