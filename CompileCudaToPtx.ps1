param (
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = "Release"
)

Write-Host "Starting CUDA to PTX compilation for $Configuration configuration..." -ForegroundColor Cyan

# Check if CUDA is installed
$cudaPath = $env:CUDA_PATH
if (-not $cudaPath) {
    Write-Host "CUDA_PATH environment variable not set. Checking default locations..." -ForegroundColor Yellow

    # Try common CUDA installation paths
    $possiblePaths = @(
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.3",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.2",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.0",
        "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.8"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $cudaPath = $path
            Write-Host "Found CUDA at: $cudaPath" -ForegroundColor Green
            break
        }
    }

    if (-not $cudaPath) {
        Write-Host "Warning: CUDA Toolkit not found. Skipping PTX compilation." -ForegroundColor Yellow
        Write-Host "PTX compilation is optional - the build will use pre-built libraries if available." -ForegroundColor Yellow
        exit 0
    }
}

$nvcc = Join-Path $cudaPath "bin\nvcc.exe"
if (-not (Test-Path $nvcc)) {
    Write-Host "Warning: nvcc.exe not found at $nvcc. Skipping PTX compilation." -ForegroundColor Yellow
    exit 0
}

# Create PTX output directory
$ptxDir = Join-Path $PSScriptRoot "ptx"
if (-not (Test-Path $ptxDir)) {
    New-Item -ItemType Directory -Path $ptxDir | Out-Null
    Write-Host "Created PTX output directory: $ptxDir" -ForegroundColor Green
}

# Compile CUDA files to PTX
$cudaProjects = @(
    @{
        Name = "CudaAlignedBitrotFinder"
        Source = "CudaAlignedBitrotFinder\kernel.cu"
        Output = "ptx\CudaAlignedBitrotFinder.ptx"
    },
    @{
        Name = "CudaUnalignedBitrotFinder"
        Source = "CudaUnalignedBitrotFinder\kernel.cu"
        Output = "ptx\CudaUnalignedBitrotFinder.ptx"
    }
)

$success = $true
foreach ($project in $cudaProjects) {
    $sourcePath = Join-Path $PSScriptRoot $project.Source
    $outputPath = Join-Path $PSScriptRoot $project.Output

    if (-not (Test-Path $sourcePath)) {
        Write-Host "Warning: Source file not found: $sourcePath" -ForegroundColor Yellow
        continue
    }

    Write-Host "Compiling $($project.Name)..." -ForegroundColor Cyan

    # Compile to PTX with compute capability 5.0 as minimum (covers most modern GPUs)
    $args = @(
        "-ptx",
        "-arch=sm_50",
        "-O3",
        "-o", $outputPath,
        $sourcePath
    )

    # Add Visual Studio compatibility flag for newer versions
    if ($env:GITHUB_ACTIONS -ne "true") {
        $args += "-allow-unsupported-compiler"
    }

    Write-Host "Running: nvcc $($args -join ' ')" -ForegroundColor Gray

    $process = Start-Process -FilePath $nvcc -ArgumentList $args -NoNewWindow -PassThru -Wait

    if ($process.ExitCode -eq 0) {
        Write-Host "Successfully compiled $($project.Name) to PTX" -ForegroundColor Green
    } else {
        Write-Host "Warning: Failed to compile $($project.Name) (exit code: $($process.ExitCode))" -ForegroundColor Yellow
        $success = $false
    }
}

if ($success) {
    Write-Host "PTX compilation completed successfully!" -ForegroundColor Green
} else {
    Write-Host "PTX compilation completed with warnings. The build will fall back to pre-built libraries." -ForegroundColor Yellow
}

# List generated PTX files
if (Test-Path $ptxDir) {
    $ptxFiles = Get-ChildItem -Path $ptxDir -Filter "*.ptx"
    if ($ptxFiles) {
        Write-Host "`nGenerated PTX files:" -ForegroundColor Cyan
        $ptxFiles | ForEach-Object {
            Write-Host "  - $($_.Name) ($('{0:N0}' -f $_.Length) bytes)" -ForegroundColor Gray
        }
    }
}

exit 0