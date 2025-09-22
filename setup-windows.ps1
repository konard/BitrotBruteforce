# Setup script for Windows development environment
# This script checks and helps set up the required dependencies

Write-Host "BitrotBruteforce - Windows Setup Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$errors = @()
$warnings = @()

# Check Visual Studio
Write-Host "`nChecking Visual Studio..." -ForegroundColor Yellow
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -property installationPath
    if ($vsPath) {
        Write-Host "✓ Visual Studio found at: $vsPath" -ForegroundColor Green
    } else {
        $errors += "Visual Studio 2022 not found. Please install from: https://visualstudio.microsoft.com/"
    }
} else {
    $errors += "Visual Studio 2022 not found. Please install from: https://visualstudio.microsoft.com/"
}

# Check CUDA
Write-Host "`nChecking CUDA Toolkit..." -ForegroundColor Yellow
$cudaPath = $env:CUDA_PATH
if ($cudaPath -and (Test-Path "$cudaPath\bin\nvcc.exe")) {
    $nvccVersion = & "$cudaPath\bin\nvcc.exe" --version 2>&1 | Select-String "release" | Out-String
    Write-Host "✓ CUDA found at: $cudaPath" -ForegroundColor Green
    Write-Host "  Version: $($nvccVersion.Trim())" -ForegroundColor Gray
} else {
    $errors += "CUDA Toolkit not found. Please install from: https://developer.nvidia.com/cuda-downloads"
}

# Check .NET SDK
Write-Host "`nChecking .NET SDK..." -ForegroundColor Yellow
$dotnetVersion = dotnet --list-sdks 2>&1 | Select-String "8\." | Select-Object -First 1
if ($dotnetVersion) {
    Write-Host "✓ .NET 8 SDK found: $dotnetVersion" -ForegroundColor Green
} else {
    $errors += ".NET 8 SDK not found. Please install from: https://dotnet.microsoft.com/download"
}

# Check for cross-compilation tools
Write-Host "`nChecking cross-compilation tools..." -ForegroundColor Yellow
$hasWSL = Get-Command wsl -ErrorAction SilentlyContinue
$hasMinGW = $false

$mingwPaths = @(
    "C:\MinGW\bin",
    "C:\msys64\mingw64\bin",
    "C:\tools\mingw64\bin"
)

foreach ($path in $mingwPaths) {
    if (Test-Path $path) {
        $hasMinGW = $true
        Write-Host "✓ MinGW found at: $path" -ForegroundColor Green
        break
    }
}

if ($hasWSL) {
    Write-Host "✓ WSL detected - can be used for cross-compilation" -ForegroundColor Green

    # Check WSL CUDA
    $wslCuda = wsl bash -c "if [ -d /usr/local/cuda ]; then echo 'installed'; fi" 2>$null
    if ($wslCuda -eq "installed") {
        Write-Host "  ✓ CUDA detected in WSL" -ForegroundColor Green
    } else {
        $warnings += "CUDA not found in WSL. For cross-compilation, install CUDA in WSL."
    }
} elseif (-not $hasMinGW) {
    $warnings += "No cross-compilation tools found. Install WSL2 or MinGW-w64 for Linux cross-compilation."
}

# Display results
Write-Host "`n========================================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "✓ All required dependencies are installed!" -ForegroundColor Green
} else {
    Write-Host "✗ Missing required dependencies:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`nWarnings:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  ⚠ $warning" -ForegroundColor Yellow
    }
}

# Offer to install WSL if not present
if (-not $hasWSL -and -not $hasMinGW) {
    Write-Host "`nWould you like to enable WSL2 for cross-compilation? (Y/N)" -ForegroundColor Cyan
    $response = Read-Host
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Enabling WSL2..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        Write-Host "WSL2 enabled. Please restart your computer and install Ubuntu from Microsoft Store." -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup check complete!" -ForegroundColor Cyan