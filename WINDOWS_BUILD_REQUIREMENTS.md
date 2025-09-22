# Windows Build Requirements

This document describes the requirements and steps to build BitrotBruteforce on Windows x64, including cross-compilation for Linux x64.

## Prerequisites for Windows Build

### 1. Visual Studio 2022
- Download and install [Visual Studio 2022](https://visualstudio.microsoft.com/downloads/)
- Required workloads:
  - **.NET desktop development**
  - **Desktop development with C++**
  - **Linux development with C++** (for cross-compilation)

### 2. CUDA Toolkit
- Download and install [CUDA Toolkit 12.6](https://developer.nvidia.com/cuda-12-6-0-download-archive) or later
- Ensure that the CUDA Toolkit is added to your PATH
- Verify installation: `nvcc --version`

### 3. .NET 8 SDK
- Download and install [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- Verify installation: `dotnet --version`

### 4. CMake (for Linux cross-compilation)
- Download and install [CMake](https://cmake.org/download/) version 3.18 or later
- Add CMake to your PATH
- Verify installation: `cmake --version`

### 5. Windows Subsystem for Linux (WSL2) - Optional but Recommended
For testing Linux builds on Windows:
- Enable WSL2: `wsl --install`
- Install Ubuntu or your preferred Linux distribution
- Inside WSL2, install build tools:
  ```bash
  sudo apt update
  sudo apt install -y build-essential cmake
  ```

## Building for Windows x64

1. Open the solution in Visual Studio 2022:
   ```
   Bruteforce.sln
   ```

2. Select configuration:
   - Configuration: `Release`
   - Platform: `x64`

3. Build the solution:
   - Build → Build Solution (or press F7)

4. The output will be in:
   - `Bruteforce/bin/x64/Release/`
   - CUDA modules: `Cuda*BitrotFinder/bin/x64/Release/`

## Cross-Compiling for Linux x64 on Windows

### Option 1: Using WSL2 (Recommended)

1. Open WSL2 terminal
2. Navigate to the project directory
3. Install CUDA Toolkit in WSL2:
   ```bash
   # Follow NVIDIA's instructions for your distribution
   # Example for Ubuntu:
   wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
   sudo dpkg -i cuda-keyring_1.1-1_all.deb
   sudo apt-get update
   sudo apt-get -y install cuda-toolkit-12-6
   ```

4. Install .NET SDK in WSL2:
   ```bash
   # Follow Microsoft's instructions for your distribution
   wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
   chmod +x ./dotnet-install.sh
   ./dotnet-install.sh --version latest
   ```

5. Run the Linux build script:
   ```bash
   chmod +x publish-linux.sh
   ./publish-linux.sh
   ```

### Option 2: Using Visual Studio Cross-Platform Tools

1. In Visual Studio, install the **Linux development with C++** workload

2. Configure a Linux connection:
   - Tools → Options → Cross Platform → Connection Manager
   - Add your Linux machine or WSL2 connection

3. Create a CMake project configuration:
   - Right-click on CMakeLists.txt → Configure
   - Select Linux-Release configuration

4. Build CUDA modules for Linux:
   - Build → Build All

5. Use dotnet CLI to publish for Linux:
   ```powershell
   dotnet publish Bruteforce/Bruteforce.csproj -c Release -r linux-x64 --self-contained
   ```

## Troubleshooting

### CUDA Not Found
- Ensure CUDA Toolkit is installed and `nvcc` is in PATH
- Check CUDA_PATH environment variable is set
- Restart Visual Studio after CUDA installation

### Build Errors with CUDA
- Verify Visual Studio has the latest updates
- Check that the CUDA extension for Visual Studio is installed
- Ensure compute capability matches your GPU (default is sm_52 and higher)

### Linux Build Issues on Windows
- Use WSL2 for best compatibility
- Ensure file permissions are preserved when copying to Linux
- Check that line endings are LF, not CRLF

## Additional Tools (Optional)

- **Git Bash**: For running shell scripts on Windows
- **Docker Desktop**: For containerized Linux builds
- **NVIDIA Nsight**: For CUDA debugging and profiling