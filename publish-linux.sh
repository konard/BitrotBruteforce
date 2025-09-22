#!/bin/bash

# Publish script for Linux x64
# This script builds the CUDA modules and publishes the .NET application for Linux

set -e

echo "Publishing BitrotBruteforce for Linux x64..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build configuration
BUILD_CONFIG=${1:-Release}
RUNTIME="linux-x64"
OUTPUT_DIR="publish/$RUNTIME"

echo -e "${GREEN}Build configuration: $BUILD_CONFIG${NC}"
echo -e "${GREEN}Target runtime: $RUNTIME${NC}"

# Step 1: Build CUDA modules
echo -e "${YELLOW}Step 1: Building CUDA modules...${NC}"
if [ -f "build-cuda-linux.sh" ]; then
    bash build-cuda-linux.sh $BUILD_CONFIG
else
    echo -e "${RED}Error: build-cuda-linux.sh not found${NC}"
    exit 1
fi

# Step 2: Build and publish .NET application
echo -e "${YELLOW}Step 2: Publishing .NET application...${NC}"

# Check if dotnet is installed
if ! command -v dotnet &> /dev/null; then
    echo -e "${RED}Error: .NET SDK is not installed${NC}"
    echo "Please install .NET 8 SDK from: https://dotnet.microsoft.com/download"
    exit 1
fi

# Clean previous build
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Publish the application
dotnet publish Bruteforce/Bruteforce.csproj \
    -c $BUILD_CONFIG \
    -r $RUNTIME \
    --self-contained true \
    -o $OUTPUT_DIR \
    /p:PublishSingleFile=false \
    /p:PublishTrimmed=false

# Step 3: Copy CUDA libraries to output directory
echo -e "${YELLOW}Step 3: Copying CUDA libraries...${NC}"

# Create libs directory in output
mkdir -p $OUTPUT_DIR/libs

# Copy CUDA libraries (renaming .dll extension to maintain compatibility)
if [ -f "CudaAlignedBitrotFinder/bin/x64/$BUILD_CONFIG/CudaAlignedBitrotFinder.dll" ]; then
    cp "CudaAlignedBitrotFinder/bin/x64/$BUILD_CONFIG/CudaAlignedBitrotFinder.dll" "$OUTPUT_DIR/libs/"
    echo -e "${GREEN}Copied CudaAlignedBitrotFinder.dll${NC}"
fi

if [ -f "CudaUnalignedBitrotFinder/bin/x64/$BUILD_CONFIG/CudaUnalignedBitrotFinder.dll" ]; then
    cp "CudaUnalignedBitrotFinder/bin/x64/$BUILD_CONFIG/CudaUnalignedBitrotFinder.dll" "$OUTPUT_DIR/libs/"
    echo -e "${GREEN}Copied CudaUnalignedBitrotFinder.dll${NC}"
fi

# Step 4: Create run script
echo -e "${YELLOW}Step 4: Creating run script...${NC}"
cat > $OUTPUT_DIR/run.sh << 'EOF'
#!/bin/bash
# Run script for BitrotBruteforce
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="$SCRIPT_DIR/libs:$LD_LIBRARY_PATH"
"$SCRIPT_DIR/Bruteforce" "$@"
EOF

chmod +x $OUTPUT_DIR/run.sh

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}Output directory: $OUTPUT_DIR${NC}"
echo -e "${GREEN}To run the application:${NC}"
echo -e "  cd $OUTPUT_DIR"
echo -e "  ./run.sh --help"
echo ""
echo -e "${YELLOW}Note: Make sure you have CUDA runtime installed on the target system${NC}"