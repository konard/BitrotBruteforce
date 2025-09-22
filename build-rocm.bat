@echo off
REM Build script for ROCm modules on Windows
REM Requires AMD HIP SDK to be installed

echo Building ROCm modules for Windows...

REM Check if HIP SDK is installed
where hipcc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: hipcc not found. Please install AMD HIP SDK.
    echo Download from: https://rocmdocs.amd.com/en/latest/Installation_Guide/HIP-Installation.html
    exit /b 1
)

REM Set build directory
set BUILD_DIR=%~dp0

REM Build RocmAlignedBitrotFinder
echo Building RocmAlignedBitrotFinder.dll...
cd /d "%BUILD_DIR%RocmAlignedBitrotFinder"

REM Compile with HIP
hipcc -O3 -std=c++14 -shared -fPIC -o RocmAlignedBitrotFinder.dll kernel.cpp sha1.cpp

if %ERRORLEVEL% NEQ 0 (
    echo Failed to build RocmAlignedBitrotFinder.dll
    exit /b 1
)

REM Copy to libs directory
if not exist "%BUILD_DIR%Bruteforce\libs" mkdir "%BUILD_DIR%Bruteforce\libs"
copy /Y RocmAlignedBitrotFinder.dll "%BUILD_DIR%Bruteforce\libs\"

REM Build RocmUnalignedBitrotFinder
echo Building RocmUnalignedBitrotFinder.dll...
cd /d "%BUILD_DIR%RocmUnalignedBitrotFinder"

REM Compile with HIP
hipcc -O3 -std=c++14 -shared -fPIC -o RocmUnalignedBitrotFinder.dll kernel.cpp sha1.cpp

if %ERRORLEVEL% NEQ 0 (
    echo Failed to build RocmUnalignedBitrotFinder.dll
    exit /b 1
)

REM Copy to libs directory
copy /Y RocmUnalignedBitrotFinder.dll "%BUILD_DIR%Bruteforce\libs\"

echo.
echo ROCm modules built successfully!
echo Libraries copied to: %BUILD_DIR%Bruteforce\libs
echo.

cd /d "%BUILD_DIR%"