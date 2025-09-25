using System.Numerics;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

using static Bruteforce.Utility;

namespace Bruteforce;

public partial class BruteforceCuda
{
    public static int Bruteforce(byte[] data, byte[] hash)
    {
        if (IsEqual(hash, GetHash(data)))
            return -2;

        var result = uint.MaxValue;

        try
        {
            // Use native libraries (DLLs on Windows, .so on Linux)
            if(data.Length % 64 == 0)
                BruteforceAligned.bruteforceBits(data, hash, data.Length, ref result);
            else
                BruteforceUnaligned.bruteforceBits(data, hash, data.Length, ref result);
        }
        catch (DllNotFoundException ex)
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                throw new Exception($"CUDA libraries not found on Linux. Ensure .so files are available in libs/ folder. Error: {ex.Message}", ex);
            else
                throw new Exception($"CUDA libraries not found. Ensure CUDA is installed. Error: {ex.Message}", ex);
        }
        catch (Exception ex)
        {
            throw new Exception($"CUDA processing failed: {ex.Message}", ex);
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
        // Since class name is BruteforceAligned, we know exactly what library to load
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
        {
            // Try to load Linux .so file
            string soPath = "libs/CudaAlignedBitrotFinder.so";
            if (NativeLibrary.TryLoad(soPath, out IntPtr handle))
                return handle;
        }
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            // Try to load Windows DLL
            string dllPath = "libs/CudaAlignedBitrotFinder.dll";
            if (NativeLibrary.TryLoad(dllPath, out IntPtr handle))
                return handle;
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
        // Since class name is BruteforceUnaligned, we know exactly what library to load
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
        {
            // Try to load Linux .so file
            string soPath = "libs/CudaUnalignedBitrotFinder.so";
            if (NativeLibrary.TryLoad(soPath, out IntPtr handle))
                return handle;
        }
        else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            // Try to load Windows DLL
            string dllPath = "libs/CudaUnalignedBitrotFinder.dll";
            if (NativeLibrary.TryLoad(dllPath, out IntPtr handle))
                return handle;
        }
        // Fall back to default resolution
        return IntPtr.Zero;
    }

    [DllImport("CudaUnalignedBitrotFinder", CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}
