using System;
using Benchmarks.Framework;
using Sizzle.Core;
using System.Collections;

namespace Benchmarks.Benchmarks;

static class BitBenchmarks
{
    private static BitfieldArray mBitfield;
    private static bool[] mBoolArray;

    private static BitfieldArray mBitfieldPopulated;
    private static bool[] mBoolArrayPopulated;

    private static BitfieldArray mBitfieldLhs;
    private static BitfieldArray mBitfieldRhs;
    private static bool[] mBoolArrayLhs;
    private static bool[] mBoolArrayRhs;

    private static BitfieldArray mBitfieldAssignLhs;
    private static BitfieldArray mBitfieldAssignRhs;
    private static bool[] mBoolArrayAssignLhs;
    private static bool[] mBoolArrayAssignRhs;

    private static BitfieldArray mBitfieldSparse;
    private static bool[] mBoolArraySparse;

    private static BitfieldArray mBitfieldSOO;
    private static bool[] mBoolArraySOO;
    private static BitfieldArray mBitfieldSOO_Populated;
    private static bool[] mBoolArraySOO_Populated;

    public static int64 sAccumulator = 0;

    public static void Setup()
    {
        mBitfield = .();
        mBitfield.Reserve(10000);

        mBoolArray = new bool[10000];

        mBitfieldPopulated = .();
        mBitfieldPopulated.Reserve(10000);
        mBoolArrayPopulated = new bool[10000];

        mBitfieldLhs = .(); mBitfieldLhs.Reserve(10000);
        mBitfieldRhs = .(); mBitfieldRhs.Reserve(10000);
        mBoolArrayLhs = new bool[10000];
        mBoolArrayRhs = new bool[10000];

        mBitfieldAssignLhs = .(); mBitfieldAssignLhs.Reserve(10000);
        mBitfieldAssignRhs = .(); mBitfieldAssignRhs.Reserve(10000);
        mBoolArrayAssignLhs = new bool[10000];
        mBoolArrayAssignRhs = new bool[10000];

        mBitfieldSparse = .();
        mBitfieldSparse.Reserve(100000);
        mBoolArraySparse = new bool[100000];

        // SOO Setup (256 bits = 1 block)
        mBitfieldSOO = .();
        mBitfieldSOO.Reserve(256);
        mBoolArraySOO = new bool[256];

        mBitfieldSOO_Populated = .();
        mBitfieldSOO_Populated.Reserve(256);
        mBoolArraySOO_Populated = new bool[256];

        for (int i = 0; i < 256; i += 2)
        {
            mBitfieldSOO_Populated.SetBit(i);
            mBoolArraySOO_Populated[i] = true;
        }

        for (int i = 0; i < 100000; i += 1000)
        {
            mBitfieldSparse.SetBit(i);
            mBoolArraySparse[i] = true;
        }

        for (int i = 0; i < 10000; i += 2)
        {
            mBitfieldPopulated.SetBit(i);
            mBoolArrayPopulated[i] = true;

            mBitfieldLhs.SetBit(i);
            mBoolArrayLhs[i] = true;

            mBitfieldAssignLhs.SetBit(i);
            mBoolArrayAssignLhs[i] = true;
        }

        for (int i = 0; i < 10000; i += 3)
        {
            mBitfieldRhs.SetBit(i);
            mBoolArrayRhs[i] = true;

            mBitfieldAssignRhs.SetBit(i);
            mBoolArrayAssignRhs[i] = true;
        }
        
        BenchmarkRegistry.Register("Bitfield_SetBit", new => Bitfield_SetBit, 100000, 5, 15, "SetBit");
        BenchmarkRegistry.Register("BoolArray_SetBit", new => BoolArray_SetBit, 100000, 5, 15, "SetBit", true);

        BenchmarkRegistry.Register("Bitfield_GetBit", new => Bitfield_GetBit, 100000, 5, 15, "GetBit");
        BenchmarkRegistry.Register("BoolArray_GetBit", new => BoolArray_GetBit, 100000, 5, 15, "GetBit", true);

        BenchmarkRegistry.Register("Bitfield_FindFirstSet", new => Bitfield_FindFirstSet, 10000, 5, 15, "FindFirstSet");
        BenchmarkRegistry.Register("BoolArray_FindFirstSet", new => BoolArray_FindFirstSet, 10000, 5, 15, "FindFirstSet", true);

        BenchmarkRegistry.Register("Bitfield_PopCount", new => Bitfield_PopCount, 10000, 5, 15, "PopCount");
        BenchmarkRegistry.Register("BoolArray_PopCount", new => BoolArray_PopCount, 10000, 5, 15, "PopCount", true);

        BenchmarkRegistry.Register("Bitfield_Iterate", new => Bitfield_Iterate, 10000, 5, 15, "Iterate");
        BenchmarkRegistry.Register("BoolArray_Iterate", new => BoolArray_Iterate, 10000, 5, 15, "Iterate", true);

        BenchmarkRegistry.Register("Bitfield_ClearAll", new => Bitfield_ClearAll, 10000, 5, 15, "ClearAll");
        BenchmarkRegistry.Register("BoolArray_ClearAll", new => BoolArray_ClearAll, 10000, 5, 15, "ClearAll", true);

        BenchmarkRegistry.Register("Bitfield_And", new => Bitfield_And, 10000, 5, 15, "And");
        BenchmarkRegistry.Register("BoolArray_And", new => BoolArray_And, 10000, 5, 15, "And", true);

        BenchmarkRegistry.Register("Bitfield_Or", new => Bitfield_Or, 10000, 5, 15, "Or");
        BenchmarkRegistry.Register("BoolArray_Or", new => BoolArray_Or, 10000, 5, 15, "Or", true);

        BenchmarkRegistry.Register("Bitfield_Xor", new => Bitfield_Xor, 10000, 5, 15, "Xor");
        BenchmarkRegistry.Register("BoolArray_Xor", new => BoolArray_Xor, 10000, 5, 15, "Xor", true);

        BenchmarkRegistry.Register("Bitfield_Not", new => Bitfield_Not, 10000, 5, 15, "Not");
        BenchmarkRegistry.Register("BoolArray_Not", new => BoolArray_Not, 10000, 5, 15, "Not", true);

        BenchmarkRegistry.Register("Bitfield_IterateSparse", new => Bitfield_IterateSparse, 10000, 5, 15, "IterateSparse");
        BenchmarkRegistry.Register("BoolArray_IterateSparse", new => BoolArray_IterateSparse, 10000, 5, 15, "IterateSparse", true);

        BenchmarkRegistry.Register("Bitfield_SOO_SetBit", new => Bitfield_SOO_SetBit, 1000000, 5, 15, "SOO_SetBit");
        BenchmarkRegistry.Register("BoolArray_SOO_SetBit", new => BoolArray_SOO_SetBit, 1000000, 5, 15, "SOO_SetBit", true);

        BenchmarkRegistry.Register("Bitfield_SOO_GetBit", new => Bitfield_SOO_GetBit, 1000000, 5, 15, "SOO_GetBit");
        BenchmarkRegistry.Register("BoolArray_SOO_GetBit", new => BoolArray_SOO_GetBit, 1000000, 5, 15, "SOO_GetBit", true);

        BenchmarkRegistry.Register("Bitfield_SOO_PopCount", new => Bitfield_SOO_PopCount, 100000, 5, 15, "SOO_PopCount");
        BenchmarkRegistry.Register("BoolArray_SOO_PopCount", new => BoolArray_SOO_PopCount, 100000, 5, 15, "SOO_PopCount", true);

        BenchmarkRegistry.Register("Bitfield_SOO_Iterate", new => Bitfield_SOO_Iterate, 100000, 5, 15, "SOO_Iterate");
        BenchmarkRegistry.Register("BoolArray_SOO_Iterate", new => BoolArray_SOO_Iterate, 100000, 5, 15, "SOO_Iterate", true);

        BenchmarkRegistry.Register("Bitfield_AndAssign", new => Bitfield_AndAssign, 10000, 5, 15, "AndAssign");
        BenchmarkRegistry.Register("BoolArray_AndAssign", new => BoolArray_AndAssign, 10000, 5, 15, "AndAssign", true);

        BenchmarkRegistry.Register("Bitfield_OrAssign", new => Bitfield_OrAssign, 10000, 5, 15, "OrAssign");
        BenchmarkRegistry.Register("BoolArray_OrAssign", new => BoolArray_OrAssign, 10000, 5, 15, "OrAssign", true);

        BenchmarkRegistry.Register("Bitfield_XorAssign", new => Bitfield_XorAssign, 10000, 5, 15, "XorAssign");
        BenchmarkRegistry.Register("BoolArray_XorAssign", new => BoolArray_XorAssign, 10000, 5, 15, "XorAssign", true);
    }

    public static void Teardown()
    {
        mBitfield.Dispose();
        delete mBoolArray;
        mBitfieldPopulated.Dispose();
        delete mBoolArrayPopulated;
        mBitfieldLhs.Dispose();
        mBitfieldRhs.Dispose();
        delete mBoolArrayLhs;
        delete mBoolArrayRhs;
        mBitfieldSparse.Dispose();
        delete mBoolArraySparse;

        mBitfieldSOO.Dispose();
        delete mBoolArraySOO;
        mBitfieldSOO_Populated.Dispose();
        delete mBoolArraySOO_Populated;

        mBitfieldAssignLhs.Dispose();
        mBitfieldAssignRhs.Dispose();
        delete mBoolArrayAssignLhs;
        delete mBoolArrayAssignRhs;
    }

    public static void Bitfield_SetBit()
    {
        mBitfield.SetBit(5000);
    }

    public static void BoolArray_SetBit()
    {
        mBoolArray[5000] = true;
    }

    public static void Bitfield_GetBit()
    {
        mBitfield.GetBit(5000);
    }

    public static void BoolArray_GetBit()
    {
        let val = mBoolArray[5000];
        if (val) { sAccumulator++; }
    }
    
    public static void Bitfield_FindFirstSet()
    {
        mBitfield.SetBit(9999);
        sAccumulator += mBitfield.FindFirstSet();
        mBitfield.ClearBit(9999);
    }

    public static void BoolArray_FindFirstSet()
    {
        mBoolArray[9999] = true;
        // Simulate finding the first set bit by iterating
        for (int i = 0; i < mBoolArray.Count; i++)
        {
            if (mBoolArray[i])
            {
                sAccumulator += i;
                break;
            }
        }
        mBoolArray[9999] = false;
    }

    public static void Bitfield_PopCount()
    {
        sAccumulator += mBitfieldPopulated.PopCount();
    }

    public static void BoolArray_PopCount()
    {
        int count = 0;
        for (let b in mBoolArrayPopulated)
        {
            if (b) count++;
        }
        sAccumulator += count;
    }

    public static void Bitfield_Iterate()
    {
        for (let i in mBitfieldPopulated)
        {
            sAccumulator += i;
        }
    }

    public static void BoolArray_Iterate()
    {
        for (int i = 0; i < mBoolArrayPopulated.Count; i++)
        {
            if (mBoolArrayPopulated[i])
            {
                sAccumulator += i;
            }
        }
    }

    public static void Bitfield_ClearAll()
    {
        mBitfield.ClearAll();
    }

    public static void BoolArray_ClearAll()
    {
        Array.Clear(mBoolArray, 0, mBoolArray.Count);
    }

    public static void Bitfield_And()
    {
        var result = mBitfieldLhs & mBitfieldRhs;
        result.Dispose();
    }

    public static void BoolArray_And()
    {
        bool[] result = new bool[mBoolArrayLhs.Count];
        for (int i = 0; i < mBoolArrayLhs.Count; i++)
        {
            result[i] = mBoolArrayLhs[i] & mBoolArrayRhs[i];
        }
        delete result;
    }

    public static void Bitfield_Or()
    {
        var result = mBitfieldLhs | mBitfieldRhs;
        result.Dispose();
    }

    public static void BoolArray_Or()
    {
        bool[] result = new bool[mBoolArrayLhs.Count];
        for (int i = 0; i < mBoolArrayLhs.Count; i++)
        {
            result[i] = mBoolArrayLhs[i] | mBoolArrayRhs[i];
        }
        delete result;
    }

    public static void Bitfield_Xor()
    {
        var result = mBitfieldLhs ^ mBitfieldRhs;
        result.Dispose();
    }

    public static void BoolArray_Xor()
    {
        bool[] result = new bool[mBoolArrayLhs.Count];
        for (int i = 0; i < mBoolArrayLhs.Count; i++)
        {
            result[i] = mBoolArrayLhs[i] ^ mBoolArrayRhs[i];
        }
        delete result;
    }

    public static void Bitfield_Not()
    {
        var result = ~mBitfieldLhs;
        result.Dispose();
    }

    public static void BoolArray_Not()
    {
        bool[] result = new bool[mBoolArrayLhs.Count];
        for (int i = 0; i < mBoolArrayLhs.Count; i++)
        {
            result[i] = !mBoolArrayLhs[i];
        }
        delete result;
    }

    public static void Bitfield_IterateSparse()
    {
        for (let i in mBitfieldSparse)
        {
            sAccumulator += i;
        }
    }

    public static void BoolArray_IterateSparse()
    {
        for (int i = 0; i < mBoolArraySparse.Count; i++)
        {
            if (mBoolArraySparse[i])
            {
                sAccumulator += i;
            }
        }
    }

    public static void Bitfield_SOO_SetBit()
    {
        mBitfieldSOO.SetBit(128);
    }

    public static void BoolArray_SOO_SetBit()
    {
        mBoolArraySOO[128] = true;
    }

    public static void Bitfield_SOO_GetBit()
    {
        mBitfieldSOO.GetBit(128);
    }

    public static void BoolArray_SOO_GetBit()
    {
        let val = mBoolArraySOO[128];
        if (val) { sAccumulator++; }
    }

    public static void Bitfield_SOO_PopCount()
    {
        sAccumulator += mBitfieldSOO_Populated.PopCount();
    }

    public static void BoolArray_SOO_PopCount()
    {
        int count = 0;
        for (let b in mBoolArraySOO_Populated)
        {
            if (b) count++;
        }
        sAccumulator += count;
    }

    public static void Bitfield_SOO_Iterate()
    {
        for (let i in mBitfieldSOO_Populated)
        {
            sAccumulator += i;
        }
    }

    public static void BoolArray_SOO_Iterate()
    {
        for (int i = 0; i < mBoolArraySOO_Populated.Count; i++)
        {
            if (mBoolArraySOO_Populated[i])
            {
                sAccumulator += i;
            }
        }
    }

    public static void Bitfield_AndAssign()
    {
        mBitfieldAssignLhs &= mBitfieldAssignRhs;
    }

    public static void BoolArray_AndAssign()
    {
        for (int i = 0; i < mBoolArrayAssignLhs.Count; i++)
        {
            mBoolArrayAssignLhs[i] &= mBoolArrayAssignRhs[i];
        }
    }

    public static void Bitfield_OrAssign()
    {
        mBitfieldAssignLhs |= mBitfieldAssignRhs;
    }

    public static void BoolArray_OrAssign()
    {
        for (int i = 0; i < mBoolArrayAssignLhs.Count; i++)
        {
            mBoolArrayAssignLhs[i] |= mBoolArrayAssignRhs[i];
        }
    }

    public static void Bitfield_XorAssign()
    {
        mBitfieldAssignLhs ^= mBitfieldAssignRhs;
    }

    public static void BoolArray_XorAssign()
    {
        for (int i = 0; i < mBoolArrayAssignLhs.Count; i++)
        {
            mBoolArrayAssignLhs[i] ^= mBoolArrayAssignRhs[i];
        }
    }
}
