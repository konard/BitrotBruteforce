using System;
using System.Runtime.InteropServices;
using System.IO;

namespace Bruteforce;

public enum GpuType
{
    None,
    Nvidia,
    AMD
}

public static class GpuDetection
{
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr LoadLibrary(string lpFileName);

    [DllImport("kernel32.dll")]
    private static extern bool FreeLibrary(IntPtr hModule);

    [DllImport("libc.so.6", EntryPoint = "dlopen")]
    private static extern IntPtr DlOpen(string filename, int flags);

    [DllImport("libc.so.6", EntryPoint = "dlclose")]
    private static extern int DlClose(IntPtr handle);

    private const int RTLD_LAZY = 1;

    /// <summary>
    /// Detects the type of GPU available on the system
    /// </summary>
    public static GpuType DetectGpuType()
    {
        // First try to detect NVIDIA GPU (CUDA)
        if (CanLoadCudaLibrary())
        {
            return GpuType.Nvidia;
        }

        // Then try to detect AMD GPU (ROCm)
        if (CanLoadRocmLibrary())
        {
            return GpuType.AMD;
        }

        return GpuType.None;
    }

    private static bool CanLoadCudaLibrary()
    {
        try
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                // Try to load CUDA runtime library on Windows
                IntPtr handle = LoadLibrary("cudart64_12.dll");
                if (handle == IntPtr.Zero)
                {
                    // Try older versions
                    handle = LoadLibrary("cudart64_11.dll");
                    if (handle == IntPtr.Zero)
                    {
                        handle = LoadLibrary("cudart64_10.dll");
                    }
                }

                if (handle != IntPtr.Zero)
                {
                    FreeLibrary(handle);
                    return true;
                }
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                // Try to load CUDA runtime library on Linux
                IntPtr handle = DlOpen("libcudart.so", RTLD_LAZY);
                if (handle != IntPtr.Zero)
                {
                    DlClose(handle);
                    return true;
                }
            }
        }
        catch
        {
            // Ignore errors - library not found
        }

        // Also check if our CUDA libraries exist
        string cudaAlignedLib = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
            ? "libs/CudaAlignedBitrotFinder.dll"
            : "libs/CudaAlignedBitrotFinder.so";

        return File.Exists(cudaAlignedLib);
    }

    private static bool CanLoadRocmLibrary()
    {
        try
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                // Try to load ROCm/HIP runtime library on Windows
                IntPtr handle = LoadLibrary("amdhip64.dll");
                if (handle != IntPtr.Zero)
                {
                    FreeLibrary(handle);
                    return true;
                }
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                // Try to load HIP runtime library on Linux
                IntPtr handle = DlOpen("libamdhip64.so", RTLD_LAZY);
                if (handle != IntPtr.Zero)
                {
                    DlClose(handle);
                    return true;
                }
            }
        }
        catch
        {
            // Ignore errors - library not found
        }

        // Also check if our ROCm libraries exist
        string rocmAlignedLib = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
            ? "libs/RocmAlignedBitrotFinder.dll"
            : "libs/libRocmAlignedBitrotFinder.so";

        return File.Exists(rocmAlignedLib);
    }

    /// <summary>
    /// Gets a descriptive string for the GPU type
    /// </summary>
    public static string GetGpuTypeDescription(GpuType gpuType)
    {
        return gpuType switch
        {
            GpuType.Nvidia => "NVIDIA (CUDA)",
            GpuType.AMD => "AMD (ROCm)",
            GpuType.None => "No compatible GPU",
            _ => "Unknown"
        };
    }
}