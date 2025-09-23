# Publishing for Linux from Windows

## Quick Start

To publish the project for Linux x64 from Windows:

### Using Visual Studio 2022 or JetBrains Rider
1. Open the solution
2. Right-click on Bruteforce project → Publish
3. Select Target Runtime: linux-x64
4. Click Publish

### Using Command Line
```powershell
dotnet publish Bruteforce/Bruteforce.csproj -c Release -r linux-x64 --self-contained
```

## How It Works

The project includes pre-built CUDA modules for Linux in the repository. When you publish for Linux from Windows, these pre-built .so files are automatically included in the output.

## Updating Linux CUDA Modules

If you need to update the CUDA modules for Linux:

1. On a Linux machine with CUDA Toolkit, run:
   ```bash
   ./build-linux-on-linux.sh
   ```

2. Commit the updated .so files to the repository

3. Windows users can then publish for Linux without rebuilding

## Requirements

### On Windows (for publishing)
- Visual Studio 2022 or JetBrains Rider
- .NET 8 SDK
- CUDA Toolkit 12.6+ (for Windows builds only)

### On Linux (for CUDA module updates)
- CUDA Toolkit 12.6+
- gcc/g++
- Compatible NVIDIA GPU drivers