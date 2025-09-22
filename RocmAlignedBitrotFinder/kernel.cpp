#include <hip/hip_runtime.h>
#include <hip/hip_runtime_api.h>

#include <stdio.h>
#include <string>
#include <string.h>
#include <stdexcept>
#include <iostream>
#include <fstream>

#include "sha1.hpp"

#ifdef _WIN32
#define DLL_EXPORT extern "C" __declspec(dllexport)
#else
#define DLL_EXPORT extern "C" __attribute__((visibility("default")))
#endif

DLL_EXPORT void bruteforceBits(unsigned char* pieceData, unsigned char* pieceHash, size_t pieceSize, unsigned int* result)
{
    unsigned char* dev_pieceData = 0;
    unsigned char* dev_pieceHash = 0;
    SHA1_CTX* dev_midstates = 0;
    unsigned int* dev_result = 0;
    hipError_t hipStatus;

    size_t midstatesLength = pieceSize / CHUNK_SIZE;
    SHA1_CTX* midstates = new SHA1_CTX[midstatesLength + 1];

    SHA1_CTX ctx;
    sha1_init(&ctx);

    midstates[0] = ctx;
    for (int i = 0; i < midstatesLength; i++) {
        sha1_update(&ctx, &pieceData[i * CHUNK_SIZE], CHUNK_SIZE);
        midstates[i + 1] = ctx;
    }

    hipStatus = hipSetDevice(0);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipSetDevice failed!");
        goto Error;
    }

    // alloc
    hipStatus = hipMalloc((void**)&dev_pieceData, pieceSize);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMalloc failed!");
        goto Error;
    }

    hipStatus = hipMalloc((void**)&dev_pieceHash, 20);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMalloc failed!");
        goto Error;
    }

    hipStatus = hipMalloc((void**)&dev_midstates, ((pieceSize / CHUNK_SIZE) + 1) * sizeof(SHA1_CTX));
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMalloc failed!");
        goto Error;
    }

    hipStatus = hipMalloc((void**)&dev_result, sizeof(unsigned int));
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMalloc failed!");
        goto Error;
    }

    // copy
    hipStatus = hipMemcpy(dev_pieceData, pieceData, pieceSize, hipMemcpyHostToDevice);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMemcpy failed!");
        goto Error;
    }

    hipStatus = hipMemcpy(dev_pieceHash, pieceHash, 20, hipMemcpyHostToDevice);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMemcpy failed!");
        goto Error;
    }

    hipStatus = hipMemcpy(dev_midstates, midstates, ((pieceSize / CHUNK_SIZE) + 1) * sizeof(SHA1_CTX), hipMemcpyHostToDevice);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMemcpy failed!");
        goto Error;
    }

    hipStatus = hipMemcpy(dev_result, result, sizeof(unsigned int), hipMemcpyHostToDevice);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMemcpy failed!");
        goto Error;
    }

    int threadsPerBlock = 1024;
    int blocksPerGrid = ((pieceSize / BATCH_SIZE) + threadsPerBlock - 1) / threadsPerBlock;
    hipLaunchKernelGGL(bitFlipKernel, dim3(blocksPerGrid), dim3(threadsPerBlock), 0, 0,
                       dev_pieceData, dev_pieceHash, dev_midstates, pieceSize, dev_result);

    hipStatus = hipGetLastError();
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "kernel launch failed: %s\n", hipGetErrorString(hipStatus));
        goto Error;
    }

    hipStatus = hipDeviceSynchronize();
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipDeviceSynchronize returned error code %d after launching kernel!\n", hipStatus);
        goto Error;
    }

    hipStatus = hipMemcpy(result, dev_result, sizeof(unsigned int), hipMemcpyDeviceToHost);
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipMemcpy failed!");
        goto Error;
    }

Error:
    hipFree(dev_pieceData);
    hipFree(dev_pieceHash);
    hipFree(dev_midstates);
    hipFree(dev_result);

    delete[] midstates;

    return;
}

unsigned char* hexStringToBytes(const char* hexStr, size_t& byteArrayLength) {
    size_t hexStrLength = std::strlen(hexStr);

    if (hexStrLength % 2 != 0) {
        return nullptr;
    }

    byteArrayLength = hexStrLength / 2;

    unsigned char* byteArray = new unsigned char[byteArrayLength];

    for (size_t i = 0; i < byteArrayLength; ++i) {
        char byteString[3] = { hexStr[2 * i], hexStr[2 * i + 1], '\0' };
        byteArray[i] = static_cast<unsigned char>(std::strtoul(byteString, nullptr, 16));
    }

    return byteArray;
}

int main(int argc, char** argv)
{
    if (argc != 3) {
        std::cerr << "Error: Not enough arguments supplied! Usage: " << argv[0] << " <piece path> " << "<expected hash>" << std::endl;
        return 1;
    }

    size_t byteArrayLength = 0;
    auto pieceHash = hexStringToBytes(argv[2], byteArrayLength);

    if (byteArrayLength != 20) {
        std::cerr << "Error: Incorrect expected hash length";
        return 1;
    }

    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <file_path>" << std::endl;
        return 1;
    }

    std::string piecePath = argv[1];

    std::ifstream file(piecePath, std::ios::binary | std::ios::ate);
    if (!file) {
        std::cerr << "Error: File '" << piecePath << "' does not exist or cannot be opened." << std::endl;
        return 1;
    }

    std::streamsize fileSize = file.tellg();
    file.seekg(0, std::ios::beg);

    unsigned char* fileData = new unsigned char[fileSize];

    if (!file.read(reinterpret_cast<char*>(fileData), fileSize)) {
        std::cerr << "Error: Failed to read the file." << std::endl;
        delete[] fileData;
        return 1;
    }

    file.close();

    std::cout << "File size: " << fileSize << " bytes" << std::endl;
    std::cout << "First few bytes: ";
    for (size_t i = 0; i < std::min(fileSize, static_cast<std::streamsize>(64)); ++i) {
        std::cout << std::hex << static_cast<int>(fileData[i]) << " ";
    }
    std::cout << std::dec << std::endl;

    unsigned int result = -1;
    bruteforceBits(fileData, pieceHash, fileSize, &result);

    std::cout << "Result: " << result << std::endl;

    hipError_t hipStatus = hipDeviceReset();
    if (hipStatus != hipSuccess) {
        fprintf(stderr, "hipDeviceReset failed!");
        return 1;
    }

    return 0;
}