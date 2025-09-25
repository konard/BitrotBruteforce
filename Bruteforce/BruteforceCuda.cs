using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

using static Bruteforce.Utility;

namespace Bruteforce;

public partial class BruteforceCuda
{
    private static readonly bool _usePtx;
    private static readonly bool _isLinux;

    static BruteforceCuda()
    {
        _isLinux = RuntimeInformation.IsOSPlatform(OSPlatform.Linux);

        // On Linux, check if we need to use PTX (only if .so files don't exist)
        if (_isLinux)
        {
            // First check if native .so files exist
            bool hasSoFiles = System.IO.File.Exists("libs/CudaAlignedBitrotFinder.so") ||
                              System.IO.File.Exists("libs/CudaUnalignedBitrotFinder.so");

            // Use PTX only if .so files don't exist and PTX files are available
            _usePtx = !hasSoFiles &&
                      System.IO.File.Exists("ptx/kernel_aligned.ptx") &&
                      CudaPtxLoader.IsSupported();
        }
    }

    public static int Bruteforce(byte[] data, byte[] hash)
    {
        if (IsEqual(hash, GetHash(data)))
            return -2;

        var result = uint.MaxValue;

        if (_usePtx)
        {
            // Use PTX loader on Linux (fallback when no .so files)
            if(data.Length % 64 == 0)
                CudaPtxLoader.BruteforceBitsAligned(data, hash, data.Length, ref result);
            else
                CudaPtxLoader.BruteforceBitsUnaligned(data, hash, data.Length, ref result);
        }
        else
        {
            // Use native libraries (DLLs on Windows, .so on Linux)
            if(data.Length % 64 == 0)
                BruteforceAligned.bruteforceBits(data, hash, data.Length, ref result);
            else
                BruteforceUnaligned.bruteforceBits(data, hash, data.Length, ref result);
        }

        if (result == uint.MaxValue)
            return -3;

        return (int)result;
    }
}


// CudaAlignedBitrotFinder.dll/.so
// void __declspec(dllexport) bruteforceBits(unsigned char* pieceData, unsigned char* pieceHash, size_t pieceSize, unsigned int* result)
// В result попадает индекс бита, который нужно флипнуть, либо 4294967295 (-1 в unsigned) если хеш-сумма не найдена
public class BruteforceAligned
{
    static BruteforceAligned()
    {
        // Set up DLL import resolver for cross-platform support
        NativeLibrary.SetDllImportResolver(typeof(BruteforceAligned).Assembly, ImportResolver);
    }

    private static IntPtr ImportResolver(string libraryName, System.Reflection.Assembly assembly, DllImportSearchPath? searchPath)
    {
        if (libraryName == "libs/CudaAlignedBitrotFinder" || libraryName == "CudaAlignedBitrotFinder")
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                // Try to load Linux .so file
                string[] paths = { "libs/CudaAlignedBitrotFinder.so", "./libs/CudaAlignedBitrotFinder.so", "CudaAlignedBitrotFinder.so" };
                foreach (var path in paths)
                {
                    if (NativeLibrary.TryLoad(path, out IntPtr handle))
                        return handle;
                }
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                // Try to load Windows DLL
                string[] paths = { "libs/CudaAlignedBitrotFinder.dll", "./libs/CudaAlignedBitrotFinder.dll", "CudaAlignedBitrotFinder.dll" };
                foreach (var path in paths)
                {
                    if (NativeLibrary.TryLoad(path, out IntPtr handle))
                        return handle;
                }
            }
        }
        // Fall back to default resolution
        return IntPtr.Zero;
    }

    [DllImport("CudaAlignedBitrotFinder", CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}

public class BruteforceUnaligned
{
    static BruteforceUnaligned()
    {
        // Set up DLL import resolver for cross-platform support
        NativeLibrary.SetDllImportResolver(typeof(BruteforceUnaligned).Assembly, ImportResolver);
    }

    private static IntPtr ImportResolver(string libraryName, System.Reflection.Assembly assembly, DllImportSearchPath? searchPath)
    {
        if (libraryName == "libs/CudaUnalignedBitrotFinder" || libraryName == "CudaUnalignedBitrotFinder")
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                // Try to load Linux .so file
                string[] paths = { "libs/CudaUnalignedBitrotFinder.so", "./libs/CudaUnalignedBitrotFinder.so", "CudaUnalignedBitrotFinder.so" };
                foreach (var path in paths)
                {
                    if (NativeLibrary.TryLoad(path, out IntPtr handle))
                        return handle;
                }
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                // Try to load Windows DLL
                string[] paths = { "libs/CudaUnalignedBitrotFinder.dll", "./libs/CudaUnalignedBitrotFinder.dll", "CudaUnalignedBitrotFinder.dll" };
                foreach (var path in paths)
                {
                    if (NativeLibrary.TryLoad(path, out IntPtr handle))
                        return handle;
                }
            }
        }
        // Fall back to default resolution
        return IntPtr.Zero;
    }

    [DllImport("CudaUnalignedBitrotFinder", CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}
