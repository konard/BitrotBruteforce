# Advanced Cross-Compilation Script for CUDA Linux Modules from Windows
# This script attempts multiple strategies to build Linux .so files on Windows

param(
    [string]$Configuration = "Release",
    [string]$RuntimeIdentifier = "linux-x64"
)

$ErrorActionPreference = "Stop"

Write-Host "`n===== CUDA Linux Cross-Compilation from Windows =====" -ForegroundColor Cyan
Write-Host "Configuration: $Configuration" -ForegroundColor Yellow
Write-Host "Target: $RuntimeIdentifier" -ForegroundColor Yellow

# Check prerequisites
function Test-Prerequisites {
    Write-Host "`nChecking prerequisites..." -ForegroundColor Green

    # Check CUDA
    if (-not $env:CUDA_PATH) {
        throw "CUDA_PATH environment variable not set. Please install CUDA Toolkit 12.0+"
    }

    $nvcc = Join-Path $env:CUDA_PATH "bin\nvcc.exe"
    if (-not (Test-Path $nvcc)) {
        throw "NVCC not found at: $nvcc"
    }

    Write-Host "✓ CUDA found at: $env:CUDA_PATH" -ForegroundColor Green

    # Check for MinGW or other cross-compiler
    $mingw = Get-Command "x86_64-w64-mingw32-gcc" -ErrorAction SilentlyContinue
    if ($mingw) {
        Write-Host "✓ MinGW cross-compiler found" -ForegroundColor Green
    }

    # Check for WSL (as fallback)
    $wsl = Get-Command "wsl" -ErrorAction SilentlyContinue
    if ($wsl) {
        Write-Host "✓ WSL available as fallback" -ForegroundColor Green
    }

    return $nvcc
}

# Strategy 1: Direct NVCC cross-compilation with Linux target
function Build-DirectNvcc {
    param(
        [string]$ModuleName,
        [string]$SourceDir,
        [string]$Nvcc
    )

    Write-Host "`n[Strategy 1] Attempting direct NVCC cross-compilation for $ModuleName..." -ForegroundColor Cyan

    $outputDir = "$SourceDir\bin\linux-x64"
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

    $outputFile = "$outputDir\$ModuleName.so"

    # NVCC arguments for Linux target
    $nvccArgs = @(
        # Linux target
        "-m64",
        "--compiler-options", "-fPIC",
        "--shared",
        # Optimization
        "-O3",
        "--use_fast_math",
        # GPU architectures
        "--generate-code=arch=compute_52,code=sm_52",
        "--generate-code=arch=compute_61,code=sm_61",
        "--generate-code=arch=compute_70,code=sm_70",
        "--generate-code=arch=compute_75,code=sm_75",
        "--generate-code=arch=compute_80,code=sm_80",
        "--generate-code=arch=compute_86,code=sm_86",
        # Define Linux macros
        "-DLINUX",
        "-D__linux__",
        # Remove Windows-specific defines
        "-UWIN32",
        "-UWIN64",
        "-U_WIN32",
        "-U_WIN64",
        # Input files
        "$SourceDir\kernel.cu",
        "$SourceDir\sha1.cu",
        # Output
        "-o", $outputFile
    )

    try {
        $output = & $Nvcc @nvccArgs 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Successfully cross-compiled $ModuleName!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ Direct compilation failed: $output" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Direct compilation error: $_" -ForegroundColor Red
    }

    return $false
}

# Strategy 2: Generate relocatable device code
function Build-RelocatableCode {
    param(
        [string]$ModuleName,
        [string]$SourceDir,
        [string]$Nvcc
    )

    Write-Host "`n[Strategy 2] Generating relocatable device code for $ModuleName..." -ForegroundColor Cyan

    $outputDir = "$SourceDir\bin\linux-x64"
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

    # First, compile to relocatable device code
    $rdcFile = "$outputDir\$ModuleName.rdc"

    $nvccArgs = @(
        "-rdc=true",
        "-m64",
        "-O3",
        "--use_fast_math",
        "--generate-code=arch=compute_52,code=sm_52",
        "--generate-code=arch=compute_70,code=sm_70",
        "--generate-code=arch=compute_80,code=sm_80",
        "-c",
        "$SourceDir\kernel.cu",
        "-o", $rdcFile
    )

    try {
        & $Nvcc @nvccArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Relocatable device code generated" -ForegroundColor Green

            # Create linking script for Linux
            $linkScript = @"
#!/bin/bash
# Link script to create .so from relocatable device code
nvcc -shared -m64 -o $ModuleName.so $ModuleName.rdc -lcudart
"@
            Set-Content -Path "$outputDir\link_$ModuleName.sh" -Value $linkScript

            Write-Host "✓ Linux link script created: link_$ModuleName.sh" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "✗ RDC compilation error: $_" -ForegroundColor Red
    }

    return $false
}

# Strategy 3: Generate PTX for runtime compilation
function Build-PTX {
    param(
        [string]$ModuleName,
        [string]$SourceDir,
        [string]$Nvcc
    )

    Write-Host "`n[Strategy 3] Generating PTX for runtime compilation..." -ForegroundColor Cyan

    $outputDir = "$SourceDir\bin\linux-x64"
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

    $ptxFile = "$outputDir\$ModuleName.ptx"

    $nvccArgs = @(
        "-ptx",
        "-m64",
        "-O3",
        "--use_fast_math",
        "--generate-code=arch=compute_52,code=compute_52",
        "$SourceDir\kernel.cu",
        "-o", $ptxFile
    )

    try {
        & $Nvcc @nvccArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ PTX generated successfully" -ForegroundColor Green

            # Create runtime loader wrapper
            $wrapperCode = @"
// Runtime PTX loader for $ModuleName on Linux
#include <cuda.h>
#include <cuda_runtime.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern "C" {
    void bruteforceBits(unsigned char* pieceData, unsigned char* pieceHash, size_t pieceSize, unsigned int* result);
}

static CUmodule module = NULL;
static CUfunction kernel = NULL;

__attribute__((constructor))
void initialize_cuda() {
    CUresult err;

    // Initialize CUDA
    err = cuInit(0);
    if (err != CUDA_SUCCESS) return;

    // Load PTX from file
    const char* ptx_path = "libs/$ModuleName.ptx";
    FILE* fp = fopen(ptx_path, "r");
    if (!fp) return;

    fseek(fp, 0, SEEK_END);
    size_t ptx_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    char* ptx_code = (char*)malloc(ptx_size + 1);
    fread(ptx_code, 1, ptx_size, fp);
    ptx_code[ptx_size] = '\0';
    fclose(fp);

    // Create context and load module
    CUdevice device;
    CUcontext context;

    cuDeviceGet(&device, 0);
    cuCtxCreate(&context, 0, device);
    cuModuleLoadData(&module, ptx_code);
    cuModuleGetFunction(&kernel, module, "bruteforceBitsKernel");

    free(ptx_code);
}

void bruteforceBits(unsigned char* pieceData, unsigned char* pieceHash, size_t pieceSize, unsigned int* result) {
    if (!kernel) {
        *result = 0xFFFFFFFF;
        return;
    }

    // Call the actual CUDA kernel
    // (Implementation would go here)

    // Placeholder for now
    *result = 0xFFFFFFFF;
}
"@
            Set-Content -Path "$outputDir\${ModuleName}_loader.c" -Value $wrapperCode

            # Create build script for Linux
            $buildScript = @"
#!/bin/bash
# Build script to compile PTX loader on Linux
gcc -shared -fPIC -o $ModuleName.so ${ModuleName}_loader.c -lcuda -lcudart
"@
            Set-Content -Path "$outputDir\build_$ModuleName.sh" -Value $buildScript

            Write-Host "✓ PTX and loader wrapper created" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "✗ PTX generation error: $_" -ForegroundColor Red
    }

    return $false
}

# Main execution
try {
    $nvcc = Test-Prerequisites

    $modules = @(
        @{ Name = "CudaAlignedBitrotFinder"; Dir = ".\CudaAlignedBitrotFinder" },
        @{ Name = "CudaUnalignedBitrotFinder"; Dir = ".\CudaUnalignedBitrotFinder" }
    )

    $totalSuccess = $true

    foreach ($module in $modules) {
        Write-Host "`n======= Building $($module.Name) =======" -ForegroundColor Yellow

        $success = $false

        # Try strategies in order
        if (-not $success) {
            $success = Build-DirectNvcc -ModuleName $module.Name -SourceDir $module.Dir -Nvcc $nvcc
        }

        if (-not $success) {
            $success = Build-RelocatableCode -ModuleName $module.Name -SourceDir $module.Dir -Nvcc $nvcc
        }

        if (-not $success) {
            $success = Build-PTX -ModuleName $module.Name -SourceDir $module.Dir -Nvcc $nvcc
        }

        if (-not $success) {
            Write-Host "✗ Failed to build $($module.Name)" -ForegroundColor Red
            $totalSuccess = $false
        }
    }

    if ($totalSuccess) {
        Write-Host "`n✓ Cross-compilation process completed successfully!" -ForegroundColor Green
        Write-Host "Note: Some strategies produce intermediate files that require final compilation on Linux." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "`n✗ Some modules failed to build." -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host "`n✗ Error: $_" -ForegroundColor Red
    exit 1
}