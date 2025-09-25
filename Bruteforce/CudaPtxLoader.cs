using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace Bruteforce;

/// <summary>
/// Loads and executes PTX code at runtime for cross-platform CUDA support
/// </summary>
public static class CudaPtxLoader
{
    private static bool _initialized = false;
    private static IntPtr _context;
    private static IntPtr _moduleAligned;
    private static IntPtr _moduleUnaligned;
    private static IntPtr _funcAligned;
    private static IntPtr _funcUnaligned;

    // CUDA Driver API functions
    [DllImport("cuda", EntryPoint = "cuInit")]
    private static extern int CuInit(uint flags);

    [DllImport("cuda", EntryPoint = "cuDeviceGet")]
    private static extern int CuDeviceGet(out int device, int ordinal);

    [DllImport("cuda", EntryPoint = "cuCtxCreate")]
    private static extern int CuCtxCreate(out IntPtr pctx, uint flags, int dev);

    [DllImport("cuda", EntryPoint = "cuModuleLoadData")]
    private static extern int CuModuleLoadData(out IntPtr module, byte[] image);

    [DllImport("cuda", EntryPoint = "cuModuleGetFunction")]
    private static extern int CuModuleGetFunction(out IntPtr hfunc, IntPtr hmod, string name);

    [DllImport("cuda", EntryPoint = "cuMemAlloc")]
    private static extern int CuMemAlloc(out IntPtr dptr, IntPtr bytesize);

    [DllImport("cuda", EntryPoint = "cuMemcpyHtoD")]
    private static extern int CuMemcpyHtoD(IntPtr dstDevice, byte[] srcHost, IntPtr byteCount);

    [DllImport("cuda", EntryPoint = "cuMemcpyDtoH")]
    private static extern int CuMemcpyDtoH(byte[] dstHost, IntPtr srcDevice, IntPtr byteCount);

    [DllImport("cuda", EntryPoint = "cuLaunchKernel")]
    private static extern int CuLaunchKernel(
        IntPtr f,
        uint gridDimX, uint gridDimY, uint gridDimZ,
        uint blockDimX, uint blockDimY, uint blockDimZ,
        uint sharedMemBytes,
        IntPtr hStream,
        IntPtr kernelParams,
        IntPtr extra);

    [DllImport("cuda", EntryPoint = "cuMemFree")]
    private static extern int CuMemFree(IntPtr dptr);

    public static bool IsSupported()
    {
        try
        {
            // Try to initialize CUDA
            int initResult = CuInit(0);
            if (initResult != 0)
            {
                Console.WriteLine($"CUDA initialization failed with code: {initResult}");
                return false;
            }

            int device;
            int deviceResult = CuDeviceGet(out device, 0);
            if (deviceResult != 0)
            {
                Console.WriteLine($"CUDA device get failed with code: {deviceResult}");
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"CUDA check failed with exception: {ex.Message}");
            return false;
        }
    }

    public static void Initialize()
    {
        if (_initialized)
            return;

        // Initialize CUDA
        int result = CuInit(0);
        if (result != 0)
            throw new Exception($"Failed to initialize CUDA: {result}");

        // Get first CUDA device
        int device;
        result = CuDeviceGet(out device, 0);
        if (result != 0)
            throw new Exception($"Failed to get CUDA device: {result}");

        // Create context
        result = CuCtxCreate(out _context, 0, device);
        if (result != 0)
            throw new Exception($"Failed to create CUDA context: {result}");

        // Load PTX modules
        LoadPtxModules();

        _initialized = true;
    }

    private static void LoadPtxModules()
    {
        // Load aligned PTX
        string alignedPtxPath = Path.Combine("ptx", "kernel_aligned.ptx");
        Console.WriteLine($"Looking for aligned PTX at: {Path.GetFullPath(alignedPtxPath)}");
        if (File.Exists(alignedPtxPath))
        {
            Console.WriteLine($"Loading aligned PTX file (size: {new FileInfo(alignedPtxPath).Length} bytes)...");
            byte[] ptxData = File.ReadAllBytes(alignedPtxPath);
            int result = CuModuleLoadData(out _moduleAligned, ptxData);
            if (result != 0)
                throw new Exception($"Failed to load aligned PTX module: {result}");

            // Get function
            result = CuModuleGetFunction(out _funcAligned, _moduleAligned, "bruteforceBits");
            if (result != 0)
                throw new Exception($"Failed to get aligned function: {result}");
            Console.WriteLine("Aligned PTX module loaded successfully");
        }
        else
        {
            Console.WriteLine($"Warning: Aligned PTX file not found at {alignedPtxPath}");
        }

        // Load unaligned PTX
        string unalignedPtxPath = Path.Combine("ptx", "kernel_unaligned.ptx");
        Console.WriteLine($"Looking for unaligned PTX at: {Path.GetFullPath(unalignedPtxPath)}");
        if (File.Exists(unalignedPtxPath))
        {
            Console.WriteLine($"Loading unaligned PTX file (size: {new FileInfo(unalignedPtxPath).Length} bytes)...");
            byte[] ptxData = File.ReadAllBytes(unalignedPtxPath);
            int result = CuModuleLoadData(out _moduleUnaligned, ptxData);
            if (result != 0)
                throw new Exception($"Failed to load unaligned PTX module: {result}");

            // Get function
            result = CuModuleGetFunction(out _funcUnaligned, _moduleUnaligned, "bruteforceBits");
            if (result != 0)
                throw new Exception($"Failed to get unaligned function: {result}");
            Console.WriteLine("Unaligned PTX module loaded successfully");
        }
        else
        {
            Console.WriteLine($"Warning: Unaligned PTX file not found at {unalignedPtxPath}");
        }
    }

    public static void BruteforceBitsAligned(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result)
    {
        if (!_initialized)
            Initialize();

        ExecuteKernel(_funcAligned, pieceData, pieceHash, pieceSize, ref result);
    }

    public static void BruteforceBitsUnaligned(byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result)
    {
        if (!_initialized)
            Initialize();

        ExecuteKernel(_funcUnaligned, pieceData, pieceHash, pieceSize, ref result);
    }

    private static void ExecuteKernel(IntPtr func, byte[] pieceData, byte[] pieceHash, int pieceSize, ref uint result)
    {
        // Allocate device memory
        IntPtr d_data, d_hash, d_result;
        CuMemAlloc(out d_data, new IntPtr(pieceData.Length));
        CuMemAlloc(out d_hash, new IntPtr(pieceHash.Length));
        CuMemAlloc(out d_result, new IntPtr(sizeof(uint)));

        // Copy data to device
        CuMemcpyHtoD(d_data, pieceData, new IntPtr(pieceData.Length));
        CuMemcpyHtoD(d_hash, pieceHash, new IntPtr(pieceHash.Length));

        // Setup kernel parameters
        IntPtr[] parameters = new IntPtr[]
        {
            d_data,
            d_hash,
            new IntPtr(pieceSize),
            d_result
        };

        GCHandle handle = GCHandle.Alloc(parameters, GCHandleType.Pinned);
        IntPtr kernelParams = handle.AddrOfPinnedObject();

        // Launch kernel
        int gridSize = (pieceSize * 8 + 1023) / 1024;
        CuLaunchKernel(func,
            (uint)gridSize, 1, 1,  // Grid dimensions
            1024, 1, 1,             // Block dimensions
            0,                      // Shared memory
            IntPtr.Zero,            // Stream
            kernelParams,
            IntPtr.Zero);

        // Copy result back
        byte[] resultBytes = new byte[sizeof(uint)];
        CuMemcpyDtoH(resultBytes, d_result, new IntPtr(sizeof(uint)));
        result = BitConverter.ToUInt32(resultBytes, 0);

        handle.Free();

        // Free device memory
        CuMemFree(d_data);
        CuMemFree(d_hash);
        CuMemFree(d_result);
    }
}