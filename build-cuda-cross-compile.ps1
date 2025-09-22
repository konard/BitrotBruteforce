param(
    [Parameter(Mandatory=$true)]
    [string]$Module,

    [Parameter(Mandatory=$false)]
    [string]$Configuration = "Release"
)

# Check for CUDA installation
$cudaPath = $env:CUDA_PATH
if (-not $cudaPath) {
    Write-Error "CUDA_PATH environment variable not set. Please install CUDA Toolkit."
    exit 1
}

$nvccPath = Join-Path $cudaPath "bin\nvcc.exe"
if (-not (Test-Path $nvccPath)) {
    Write-Error "NVCC compiler not found at $nvccPath"
    exit 1
}

# Check for Linux cross-compilation toolchain
$gccPath = ""
$possibleGccPaths = @(
    "C:\MinGW\bin\x86_64-pc-linux-gnu-gcc.exe",
    "C:\cygwin64\bin\x86_64-pc-linux-gnu-gcc.exe",
    "C:\msys64\mingw64\bin\x86_64-pc-linux-gnu-gcc.exe",
    "${env:ProgramFiles}\mingw-w64\x86_64-8.1.0-posix-seh-rt_v6-rev0\mingw64\bin\x86_64-w64-mingw32-gcc.exe"
)

foreach ($path in $possibleGccPaths) {
    if (Test-Path $path) {
        $gccPath = $path
        break
    }
}

# If no cross-compiler found, try to use WSL as fallback
$useWSL = $false
if (-not $gccPath) {
    $wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslAvailable) {
        Write-Warning "No native cross-compiler found. Attempting to use WSL for cross-compilation..."
        $useWSL = $true
    } else {
        Write-Error "No Linux cross-compilation toolchain found. Please install MinGW-w64 with Linux target or WSL."
        Write-Host "You can install the required toolchain using one of these methods:"
        Write-Host "1. Install MinGW-w64 with Linux target support"
        Write-Host "2. Install WSL2 with gcc and CUDA toolkit"
        exit 1
    }
}

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleDir = Join-Path $projectDir $Module
$outputDir = Join-Path $moduleDir "bin\linux-x64"
$objDir = Join-Path $outputDir "obj"

# Create output directories
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $objDir | Out-Null

# Source files
$sourceFiles = @(
    (Join-Path $moduleDir "kernel.cu"),
    (Join-Path $moduleDir "sha1.cu")
)

$outputFile = Join-Path $outputDir "lib$Module.so"

if ($useWSL) {
    # Using WSL for cross-compilation
    Write-Host "Cross-compiling $Module for Linux using WSL..."

    # Convert Windows paths to WSL paths
    $wslModuleDir = wsl wslpath -u "$moduleDir".Replace('\', '/')
    $wslOutputDir = wsl wslpath -u "$outputDir".Replace('\', '/')
    $wslObjDir = wsl wslpath -u "$objDir".Replace('\', '/')

    # Create build script for WSL
    $wslBuildScript = @"
#!/bin/bash
set -e

# Check if CUDA is installed in WSL
if [ ! -d /usr/local/cuda ]; then
    echo "CUDA not found in WSL. Please install CUDA toolkit in WSL."
    exit 1
fi

export PATH=/usr/local/cuda/bin:`$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:`$LD_LIBRARY_PATH

cd "$wslModuleDir"

# Compile CUDA files
nvcc -Xcompiler -fPIC -shared \
    -gencode arch=compute_52,code=sm_52 \
    -gencode arch=compute_60,code=sm_60 \
    -gencode arch=compute_70,code=sm_70 \
    -gencode arch=compute_75,code=sm_75 \
    -gencode arch=compute_80,code=sm_80 \
    -gencode arch=compute_86,code=sm_86 \
    -O3 --use_fast_math \
    kernel.cu sha1.cu \
    -o "$wslOutputDir/lib$Module.so"

echo "Successfully built lib$Module.so for Linux"
"@

    $wslScriptPath = Join-Path $objDir "build_wsl.sh"
    $wslBuildScript | Out-File -FilePath $wslScriptPath -Encoding UTF8 -NoNewline

    # Execute build in WSL
    wsl bash "$($wslScriptPath.Replace('\', '/'))"

} else {
    # Native cross-compilation
    Write-Host "Cross-compiling $Module for Linux x64..."

    $nvccArgs = @(
        "-ccbin", "`"$gccPath`"",
        "-Xcompiler", "-fPIC",
        "-shared",
        "-gencode", "arch=compute_52,code=sm_52",
        "-gencode", "arch=compute_60,code=sm_60",
        "-gencode", "arch=compute_70,code=sm_70",
        "-gencode", "arch=compute_75,code=sm_75",
        "-gencode", "arch=compute_80,code=sm_80",
        "-gencode", "arch=compute_86,code=sm_86",
        "-O3",
        "--use_fast_math",
        "-target-os", "linux",
        "-target-cpu-arch", "x86_64"
    )

    foreach ($source in $sourceFiles) {
        $nvccArgs += $source
    }

    $nvccArgs += @("-o", $outputFile)

    Write-Host "Running: nvcc $($nvccArgs -join ' ')"

    $process = Start-Process -FilePath $nvccPath -ArgumentList $nvccArgs -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        Write-Error "NVCC compilation failed with exit code $($process.ExitCode)"
        exit $process.ExitCode
    }
}

if (Test-Path $outputFile) {
    Write-Host "Successfully built $outputFile"

    # Also create a copy without the 'lib' prefix for compatibility
    $altOutputFile = Join-Path $outputDir "$Module.so"
    Copy-Item -Path $outputFile -Destination $altOutputFile -Force
    Write-Host "Created compatibility copy at $altOutputFile"
} else {
    Write-Error "Build failed - output file not created"
    exit 1
}