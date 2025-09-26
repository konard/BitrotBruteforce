cmake_minimum_required(VERSION 3.24)
project(CudaUnalignedBitrotFinder LANGUAGES CUDA)


add_library(CudaUnalignedBitrotFinder SHARED
    kernel.cu
    sha1.cu
)

target_compile_features(CudaUnalignedBitrotFinder
    INTERFACE
        cxx_std_14
)

target_compile_definitions(CudaUnalignedBitrotFinder
    PRIVATE
        $<$<CONFIG:Debug>:_DEBUG>
        $<$<CONFIG:Release>:NDEBUG>
        $<$<PLATFORM_ID:Windows>:WIN32;WIN64;_CONSOLE;_MBCS>
        $<$<PLATFORM_ID:Linux>:LINUX>
)

# Platform-specific link libraries
if(WIN32)
    target_link_libraries(CudaUnalignedBitrotFinder
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
    target_link_libraries(CudaUnalignedBitrotFinder
        PRIVATE
            cudart_static
    )
endif()

# Platform-specific compile options
if(WIN32)
    target_compile_options(CudaUnalignedBitrotFinder
        PRIVATE
            /W3
    )
else()
    target_compile_options(CudaUnalignedBitrotFinder
        PRIVATE
            -Wall
    )
endif()

set(CMAKE_CUDA_ARCHITECTURES "52")


