# PowerShell script to compile CUDA code to PTX for cross-platform deployment
# This enables Windows developers to create Linux-compatible CUDA modules

param(
    [Parameter(Mandatory=$false)]
    [string]$Configuration = "Release",

    [Parameter(Mandatory=$false)]
    [string]$CudaPath = $env:CUDA_PATH
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CUDA to PTX Cross-Platform Compiler" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Note: CI environment will now have real CUDA toolkit installed

# Check if CUDA is installed
if (-not $CudaPath) {
    $CudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.0"
    if (-not (Test-Path $CudaPath)) {
        $CudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
    }
}

if (-not (Test-Path $CudaPath)) {
    Write-Warning "CUDA Toolkit not found. PTX files will not be generated."
    Write-Host "To enable CUDA cross-compilation, install CUDA Toolkit from https://developer.nvidia.com/cuda-downloads" -ForegroundColor Yellow
    exit 0
}

$nvcc = Join-Path $CudaPath "bin\nvcc.exe"
if (-not (Test-Path $nvcc)) {
    Write-Error "nvcc.exe not found at $nvcc"
    exit 1
}

Write-Host "Using CUDA Toolkit at: $CudaPath" -ForegroundColor Green

# Create output directories
$outputDir = "ptx"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Compile options for PTX generation
# -ptx: Generate PTX instead of cubin
# -arch: Target compute capability (using sm_50 for broad compatibility)
# -O3: Optimization level for release builds
$compileArgs = @(
    "-ptx",
    "-arch=sm_50",  # Broad compatibility - supports Maxwell and newer
    "-use_fast_math"
)

if ($Configuration -eq "Release") {
    $compileArgs += "-O3"
} else {
    $compileArgs += "-G", "-g"  # Debug symbols
}

# Compile CudaAlignedBitrotFinder
Write-Host "`nCompiling CudaAlignedBitrotFinder..." -ForegroundColor Cyan
$alignedSources = @(
    "CudaAlignedBitrotFinder\kernel.cu",
    "CudaAlignedBitrotFinder\sha1.cu"
)

$alignedSuccess = $true
foreach ($source in $alignedSources) {
    $outputFile = Join-Path $outputDir ([System.IO.Path]::GetFileNameWithoutExtension($source) + "_aligned.ptx")

    $args = $compileArgs + @(
        "-o", $outputFile,
        $source
    )

    Write-Host "Compiling $source to PTX..." -ForegroundColor Yellow
    $process = Start-Process -FilePath $nvcc -ArgumentList $args -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "[SUCCESS] Successfully compiled to $outputFile" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] Failed to compile $source" -ForegroundColor Red
        $alignedSuccess = $false
    }
}

# Compile CudaUnalignedBitrotFinder
Write-Host "`nCompiling CudaUnalignedBitrotFinder..." -ForegroundColor Cyan
$unalignedSources = @(
    "CudaUnalignedBitrotFinder\kernel.cu",
    "CudaUnalignedBitrotFinder\sha1.cu"
)

$unalignedSuccess = $true
foreach ($source in $unalignedSources) {
    $outputFile = Join-Path $outputDir ([System.IO.Path]::GetFileNameWithoutExtension($source) + "_unaligned.ptx")

    $args = $compileArgs + @(
        "-o", $outputFile,
        $source
    )

    Write-Host "Compiling $source to PTX..." -ForegroundColor Yellow
    $process = Start-Process -FilePath $nvcc -ArgumentList $args -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "[SUCCESS] Successfully compiled to $outputFile" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] Failed to compile $source" -ForegroundColor Red
        $unalignedSuccess = $false
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($alignedSuccess -and $unalignedSuccess) {
    Write-Host "[SUCCESS] All PTX files generated successfully!" -ForegroundColor Green
    Write-Host "PTX files are located in: .\$outputDir\" -ForegroundColor Green
    Write-Host "These PTX files can be used on any platform with CUDA support." -ForegroundColor Green
    exit 0
} else {
    Write-Host "[FAILED] Some compilations failed. Check the errors above." -ForegroundColor Red
    exit 1
}