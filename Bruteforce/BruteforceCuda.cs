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

        if(data.Length % 64 == 0)
            BruteforceAligned.bruteforceBits(data, hash, data.Length, ref result);
        else
            BruteforceUnaligned.bruteforceBits(data, hash, data.Length, ref result);

        if (result == uint.MaxValue)
            return -3;

        return (int)result;
    }
}


// CudaAlignedBitrotFinder.dll
// void __declspec(dllexport) bruteforceBits(unsigned char* pieceData, unsigned char* pieceHash, size_t pieceSize, unsigned int* result)
// В result попадает индекс бита, который нужно флипнуть, либо 4294967295 (-1 в unsigned) если хеш-сумма не найдена
public static class BruteforceAligned
{
    private const string WindowsLibrary = "libs/CudaAlignedBitrotFinder.dll";
    private const string LinuxLibrary = "libs/CudaAlignedBitrotFinder.so";

    static BruteforceAligned()
    {
        NativeLibrary.SetDllImportResolver(typeof(BruteforceAligned).Assembly, DllImportResolver);
    }

    private static IntPtr DllImportResolver(string libraryName, System.Reflection.Assembly assembly, DllImportSearchPath? searchPath)
    {
        if (libraryName == "CudaAlignedBitrotFinder")
        {
            string library = RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? WindowsLibrary : LinuxLibrary;
            return NativeLibrary.Load(library, assembly, searchPath);
        }
        return IntPtr.Zero;
    }

    [DllImport("CudaAlignedBitrotFinder", CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}

public static class BruteforceUnaligned
{
    private const string WindowsLibrary = "libs/CudaUnalignedBitrotFinder.dll";
    private const string LinuxLibrary = "libs/CudaUnalignedBitrotFinder.so";

    static BruteforceUnaligned()
    {
        NativeLibrary.SetDllImportResolver(typeof(BruteforceUnaligned).Assembly, DllImportResolver);
    }

    private static IntPtr DllImportResolver(string libraryName, System.Reflection.Assembly assembly, DllImportSearchPath? searchPath)
    {
        if (libraryName == "CudaUnalignedBitrotFinder")
        {
            string library = RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? WindowsLibrary : LinuxLibrary;
            return NativeLibrary.Load(library, assembly, searchPath);
        }
        return IntPtr.Zero;
    }

    [DllImport("CudaUnalignedBitrotFinder", CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}
