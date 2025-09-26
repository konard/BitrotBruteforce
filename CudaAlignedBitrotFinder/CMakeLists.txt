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

target_compile_definitions(CudaAlignedBitrotFinder
    PRIVATE
        $<$<CONFIG:Debug>:_DEBUG>
        $<$<CONFIG:Release>:NDEBUG>
        $<$<PLATFORM_ID:Windows>:WIN32;WIN64;_CONSOLE;_MBCS>
        $<$<PLATFORM_ID:Linux>:LINUX>
)

# Platform-specific link libraries
if(WIN32)
    target_link_libraries(CudaAlignedBitrotFinder
        PRIVATE
            cudart_static
            kernel32
            user32
            gdi32
            winspool
            comdlg32
            advapi32
            shell32
            ole32
            oleaut32
            uuid
            odbc32
            odbccp32
    )
else()
    target_link_libraries(CudaAlignedBitrotFinder
        PRIVATE
            cudart_static
    )
endif()

# Platform-specific compile options
if(WIN32)
    target_compile_options(CudaAlignedBitrotFinder
        PRIVATE
            /W3
    )
else()
    target_compile_options(CudaAlignedBitrotFinder
        PRIVATE
            -Wall
    )
endif()

set(CMAKE_CUDA_ARCHITECTURES "52")
