# ROCm Support for BitrotBruteforce

This implementation adds AMD GPU support through ROCm™ technology, enabling hardware acceleration on AMD GPUs alongside the existing NVIDIA CUDA support.

## Features

- **Automatic GPU detection**: The application automatically detects whether an NVIDIA (CUDA) or AMD (ROCm) GPU is available
- **Cross-platform support**: Works on both Windows x64 and Linux x64
- **Aligned and unaligned blocks**: Supports both aligned (64-byte) and unaligned data blocks
- **Fallback to CPU**: Automatically falls back to CPU processing if no compatible GPU is detected

## Prerequisites

### For AMD GPUs (ROCm)
- **Linux**: ROCm 5.0+ installed ([Installation Guide](https://docs.amd.com/bundle/ROCm-Installation-Guide/page/Overview_of_ROCm_Installation_Methods.html))
- **Windows**: AMD HIP SDK ([Download](https://rocmdocs.amd.com/en/latest/Installation_Guide/HIP-Installation.html))

### For NVIDIA GPUs (CUDA)
- CUDA Toolkit 10.0 or later
- Compatible NVIDIA GPU

## Building

### Linux

```bash
# Build ROCm modules
./build-rocm.sh

# Build with cross-compilation for Windows
./build-rocm.sh --cross-compile
```

### Windows

```batch
# Build ROCm modules
build-rocm.bat
```

## Usage

The application automatically detects and uses the available GPU:

```bash
# GPU acceleration (auto-detects CUDA or ROCm)
./Bruteforce brute --gpu path/to/torrent path/to/data

# Force CPU-only processing
./Bruteforce brute path/to/torrent path/to/data
```

## Architecture

The implementation consists of:

1. **GPU Detection Module** (`GpuDetection.cs`): Detects available GPU type
2. **Unified GPU Interface** (`BruteforceGpu.cs`): Provides a single interface for both CUDA and ROCm
3. **ROCm Modules**: HIP-based implementations for aligned and unaligned data processing
   - `RocmAlignedBitrotFinder/`: Handles 64-byte aligned blocks
   - `RocmUnalignedBitrotFinder/`: Handles unaligned blocks

## Performance

ROCm performance is comparable to CUDA for similar GPU architectures. The actual performance depends on:
- GPU model and memory bandwidth
- Data block size and alignment
- System memory speed

## Troubleshooting

### GPU Not Detected

1. **Check ROCm installation**:
   ```bash
   rocm-smi
   hipcc --version
   ```

2. **Check library files**:
   - Linux: `libs/libRocmAlignedBitrotFinder.so` and `libs/libRocmUnalignedBitrotFinder.so`
   - Windows: `libs/RocmAlignedBitrotFinder.dll` and `libs/RocmUnalignedBitrotFinder.dll`

3. **Verify GPU support**:
   - AMD GPUs: GCN 3.0 or newer (Fiji, Polaris, Vega, RDNA series)
   - NVIDIA GPUs: Compute Capability 3.5 or newer

### Build Errors

- **Linux**: Ensure ROCm is properly installed and `hipcc` is in PATH
- **Windows**: Install AMD HIP SDK and ensure environment variables are set
- **Cross-compilation**: Install MinGW-w64 for Windows DLL generation on Linux

## Supported Platforms

- ✅ Windows x64 with AMD GPU (ROCm)
- ✅ Windows x64 with NVIDIA GPU (CUDA)
- ✅ Linux x64 with AMD GPU (ROCm)
- ✅ Linux x64 with NVIDIA GPU (CUDA)
- ✅ Automatic fallback to CPU on unsupported platforms

## License

Same as the main project license.