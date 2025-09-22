# Linux Build Requirements

This document describes the requirements and steps to build BitrotBruteforce on Linux x64.

## Prerequisites for Linux Build

### 1. CUDA Toolkit
Install CUDA Toolkit 12.6 or later. Follow the official NVIDIA instructions for your distribution:

#### Ubuntu/Debian:
```bash
# Add NVIDIA package repositories
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update

# Install CUDA Toolkit
sudo apt-get -y install cuda-toolkit-12-6

# Add CUDA to PATH (add to ~/.bashrc for permanent setup)
export PATH=/usr/local/cuda-12.6/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH
```

#### RHEL/CentOS/Fedora:
```bash
# Add NVIDIA package repositories
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
sudo dnf clean all

# Install CUDA Toolkit
sudo dnf -y install cuda-toolkit-12-6
```

Verify installation:
```bash
nvcc --version
```

### 2. .NET 8 SDK
Install .NET 8 SDK:

#### Ubuntu/Debian:
```bash
# Download and run the install script
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x ./dotnet-install.sh
./dotnet-install.sh --version latest --channel 8.0

# Add to PATH (add to ~/.bashrc for permanent setup)
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
```

#### Using Package Manager (Ubuntu 22.04+):
```bash
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0
```

Verify installation:
```bash
dotnet --version
```

### 3. Build Tools
Install essential build tools:

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake git
```

#### RHEL/CentOS/Fedora:
```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install cmake git
```

### 4. CMake
Ensure CMake 3.18 or later is installed:
```bash
cmake --version
```

If you need a newer version:
```bash
# Download and install latest CMake
wget https://github.com/Kitware/CMake/releases/download/v3.27.0/cmake-3.27.0-linux-x86_64.sh
chmod +x cmake-3.27.0-linux-x86_64.sh
sudo ./cmake-3.27.0-linux-x86_64.sh --prefix=/usr/local --skip-license
```

## Building the Project

### Quick Build
Use the provided build script:
```bash
# Make scripts executable
chmod +x build-cuda-linux.sh
chmod +x publish-linux.sh

# Build and publish for Linux
./publish-linux.sh
```

### Manual Build Steps

#### 1. Build CUDA Modules
```bash
# Build CudaAlignedBitrotFinder
cd CudaAlignedBitrotFinder
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j$(nproc)
cd ../..

# Build CudaUnalignedBitrotFinder
cd CudaUnalignedBitrotFinder
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j$(nproc)
cd ../..
```

#### 2. Build .NET Application
```bash
# Restore dependencies
dotnet restore

# Build the application
dotnet build -c Release

# Publish as self-contained application
dotnet publish Bruteforce/Bruteforce.csproj \
    -c Release \
    -r linux-x64 \
    --self-contained true \
    -o publish/linux-x64
```

## Running the Application

After building:
```bash
cd publish/linux-x64
./run.sh --help
```

Or directly:
```bash
export LD_LIBRARY_PATH=./libs:$LD_LIBRARY_PATH
./Bruteforce --help
```

## GPU Requirements

- NVIDIA GPU with Compute Capability 5.2 or higher
- NVIDIA drivers compatible with CUDA 12.6
- Check your GPU: `nvidia-smi`

## Troubleshooting

### CUDA Not Found
```bash
# Check if CUDA is installed
which nvcc

# Check CUDA version
nvcc --version

# Verify CUDA libraries
ls /usr/local/cuda/lib64/
```

### .NET SDK Issues
```bash
# List installed SDKs
dotnet --list-sdks

# Install specific version
./dotnet-install.sh --version 8.0.100
```

### Build Errors
```bash
# Clean build directories
rm -rf CudaAlignedBitrotFinder/build
rm -rf CudaUnalignedBitrotFinder/build
rm -rf Bruteforce/bin Bruteforce/obj

# Rebuild with verbose output
cmake -DCMAKE_VERBOSE_MAKEFILE=ON ..
dotnet build -v detailed
```

### Runtime Errors
```bash
# Check library dependencies
ldd ./Bruteforce
ldd ./libs/CudaAlignedBitrotFinder.dll

# Check CUDA runtime
nvidia-smi

# Enable debug output
export CUDA_LAUNCH_BLOCKING=1
```

## Docker Support (Optional)

Build using Docker with CUDA support:
```dockerfile
FROM nvidia/cuda:12.6.0-devel-ubuntu22.04

# Install .NET SDK and build tools
RUN apt-get update && apt-get install -y \
    wget \
    cmake \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 8
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --version latest --channel 8.0 --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet

# Build the project
WORKDIR /app
COPY . .
RUN chmod +x *.sh && ./publish-linux.sh
```

Build and run with Docker:
```bash
docker build -t bitrotbruteforce .
docker run --gpus all bitrotbruteforce ./publish/linux-x64/run.sh --help
```