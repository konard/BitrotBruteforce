using System;
using System.Runtime.InteropServices;
using static Bruteforce.Utility;

namespace Bruteforce;

/// <summary>
/// Unified GPU bruteforce class that automatically selects between CUDA and ROCm
/// </summary>
public partial class BruteforceGpu
{
    private static readonly GpuType _gpuType = GpuDetection.DetectGpuType();
    private static bool _initialized = false;

    static BruteforceGpu()
    {
        if (_gpuType != GpuType.None)
        {
            Console.WriteLine($"GPU detected: {GpuDetection.GetGpuTypeDescription(_gpuType)}");
            _initialized = true;
        }
        else
        {
            Console.WriteLine("No compatible GPU found. GPU acceleration disabled.");
        }
    }

    public static bool IsGpuAvailable => _initialized && _gpuType != GpuType.None;

    public static int Bruteforce(byte[] data, byte[] hash)
    {
        if (!IsGpuAvailable)
        {
            return -1; // GPU not available
        }

        if (IsEqual(hash, GetHash(data)))
            return -2;

        var result = uint.MaxValue;

        try
        {
            if (_gpuType == GpuType.Nvidia)
            {
                // Use CUDA implementation
                if (data.Length % 64 == 0)
                    CudaBruteforceAligned.bruteforceBits(data, hash, data.Length, ref result);
                else
                    CudaBruteforceUnaligned.bruteforceBits(data, hash, data.Length, ref result);
            }
            else if (_gpuType == GpuType.AMD)
            {
                // Use ROCm implementation
                if (data.Length % 64 == 0)
                    RocmBruteforceAligned.bruteforceBits(data, hash, data.Length, ref result);
                else
                    RocmBruteforceUnaligned.bruteforceBits(data, hash, data.Length, ref result);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"GPU bruteforce failed: {ex.Message}");
            return -1;
        }

        if (result == uint.MaxValue)
            return -3;

        return (int)result;
    }
}

// CUDA implementations
internal class CudaBruteforceAligned
{
    [DllImport("libs/CudaAlignedBitrotFinder", CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}

internal class CudaBruteforceUnaligned
{
    [DllImport("libs/CudaUnalignedBitrotFinder", CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}

// ROCm implementations
internal class RocmBruteforceAligned
{
    private const string RocmAlignedLib = "libs/RocmAlignedBitrotFinder";

    [DllImport(RocmAlignedLib, CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}

internal class RocmBruteforceUnaligned
{
    private const string RocmUnalignedLib = "libs/RocmUnalignedBitrotFinder";

    [DllImport(RocmUnalignedLib, CallingConvention = CallingConvention.Cdecl)]
    public static extern void bruteforceBits(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result);
}