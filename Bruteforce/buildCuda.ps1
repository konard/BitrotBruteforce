
Write-Output $PWD;

docker run --rm -v $PWD/../:/app nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04 bash -c "echo `$(pwd) &&
    ls /app/ &&
    apt-get update  &&
    apt-get install -y cmake build-essential  &&
    cd /app/CudaAlignedBitrotFinder/  &&
    rm -r build || true &&
    mkdir build  &&
    cd build  &&
    cmake ..  &&
    cmake --build .  &&
    mv /app/CudaAlignedBitrotFinder/build/libCudaAlignedBitrotFinder.so /app/Bruteforce/libs/CudaAlignedBitrotFinder.so  &&
    cd /app/CudaAlignedBitrotFinder/  &&
    rm -r build &&
    cd /app/CudaUnalignedBitrotFinder/  &&
    rm -r build || true &&
    mkdir build  &&
    cd build  &&
    cmake ..  &&
    cmake --build .  &&
    mv /app/CudaUnalignedBitrotFinder/build/libCudaUnalignedBitrotFinder.so /app/Bruteforce/libs/CudaUnalignedBitrotFinder.so  &&
    cd /app/CudaUnalignedBitrotFinder/  &&
    rm -r build"

