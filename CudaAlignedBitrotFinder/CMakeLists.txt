cmake_minimum_required(VERSION 3.18)
project(CudaAlignedBitrotFinder CUDA)

set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Find CUDA Toolkit
find_package(CUDAToolkit REQUIRED)

# Set CUDA architecture (compute capability 5.2 and higher)
# You can override this with -DCMAKE_CUDA_ARCHITECTURES=xx
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 52 60 70 75 80 86)
endif()

# Create shared library
add_library(CudaAlignedBitrotFinder SHARED
    kernel.cu
    sha1.cu
)

# Set library properties
set_target_properties(CudaAlignedBitrotFinder PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    POSITION_INDEPENDENT_CODE ON
    PREFIX "lib"
    OUTPUT_NAME "CudaAlignedBitrotFinder"
)

# Link CUDA runtime
target_link_libraries(CudaAlignedBitrotFinder
    CUDA::cudart_static
)

# Set optimization flags for Release build
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    target_compile_options(CudaAlignedBitrotFinder PRIVATE
        $<$<COMPILE_LANGUAGE:CUDA>:
            -O3
            --use_fast_math
            --ptxas-options=-v
        >
    )
endif()

# Set output directory
set_target_properties(CudaAlignedBitrotFinder PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)