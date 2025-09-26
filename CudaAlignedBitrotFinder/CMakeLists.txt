cmake_minimum_required(VERSION 3.24)
project(CudaAlignedBitrotFinder LANGUAGES CUDA)

add_library(CudaAlignedBitrotFinder SHARED
    kernel.cu
    sha1.cu
)

target_compile_features(CudaAlignedBitrotFinder
    INTERFACE
        cxx_std_14
)

# Platform-specific configurations
if(WIN32)
    target_compile_definitions(CudaAlignedBitrotFinder
        INTERFACE
            WIN32
            WIN64
            _CONSOLE
            _MBCS
            $<$<CONFIG:Debug>:_DEBUG>
            $<$<CONFIG:Release>:NDEBUG>
    )

    target_link_libraries(CudaAlignedBitrotFinder
        INTERFACE
            cudart_static.lib
            kernel32.lib
            user32.lib
            gdi32.lib
            winspool.lib
            comdlg32.lib
            advapi32.lib
            shell32.lib
            ole32.lib
            oleaut32.lib
            uuid.lib
            odbc32.lib
            odbccp32.lib
    )

    target_compile_options(CudaAlignedBitrotFinder
        INTERFACE
            /W3
    )
else()
    # Linux/Unix configurations
    target_compile_definitions(CudaAlignedBitrotFinder
        PRIVATE
            LINUX
    )

    find_package(CUDAToolkit REQUIRED)
    target_link_libraries(CudaAlignedBitrotFinder
        PUBLIC
            CUDA::cudart_static
    )

    target_compile_options(CudaAlignedBitrotFinder
        PRIVATE
            -fPIC
    )
endif()

set(CMAKE_CUDA_ARCHITECTURES "52")
