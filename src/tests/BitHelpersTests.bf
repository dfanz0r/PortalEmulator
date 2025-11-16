using System;
using PortalEmulator.Sizzle.Core;

namespace Sizzle.Tests;

static class BitHelpersTests
{
    private const float FloatEpsilon = 1e-4f;
    private const double DoubleEpsilon = 1e-8;

    [Test]
    public static void GetHighestBit_ReturnsMostSignificantSetBit()
    {
        int64 value = 0xB4L; // 1011 0100
        int64 highest = BitHelpers.GetHighestBit(value);
        Test.Assert(highest == 0x80L);
    }

    [Test]
    public static void GetHighestBit_HandlesTopBit()
    {
        uint32 value = 1U << 31;
        uint32 highest = BitHelpers.GetHighestBit(value);
        Test.Assert(highest == value);
    }

    [Test]
    public static void GetLowestBit_ReturnsLeastSignificantSetBit()
    {
        int64 value = 0xD8L; // 1101 1000
        int64 lowest = BitHelpers.GetLowestBit(value);
        Test.Assert(lowest == 0x8L);
    }

    [Test]
    public static void GetLowestBit_ReturnsHighBitWhenOnlyOneSet()
    {
        int64 value = int64.MinValue;
        int64 lowest = BitHelpers.GetLowestBit(value);
        Test.Assert(lowest == value);
    }

    [Test]
    public static void GetFlagAtPos_ReturnsExpectedNthSetBit()
    {
        int64 bits = (1L << 2) | (1L << 7) | (1L << 11);
        Test.Assert(BitHelpers.GetFlagAtPos(bits, 0) == (1L << 2));
        Test.Assert(BitHelpers.GetFlagAtPos(bits, 1) == (1L << 7));
        Test.Assert(BitHelpers.GetFlagAtPos(bits, 2) == (1L << 11));
        Test.Assert(BitHelpers.GetFlagAtPos(bits, 3) == 0); // Out of range
    }

    [Test]
    public static void GetFlagAtPos_ReturnsHighOrderBit()
    {
        int64 bits = (1L << 0) | int64.MinValue;
        Test.Assert(BitHelpers.GetFlagAtPos(bits, 1) == int64.MinValue);
    }

    [Test]
    public static void GetBitCount_ReturnsCorrectNumberOfBits()
    {
        int64 bits = (1L << 0) | (1L << 1) | (1L << 5) | (1L << 8) | (1L << 16);
        int count = BitHelpers.GetBitCount(bits);
        Test.Assert(count == 5);
    }

    [Test]
    public static void GetBitCount_AllBitsSetReturnsWordSize()
    {
        int64 bits = -1;
        int count = BitHelpers.GetBitCount(bits);
        Test.Assert(count == 64);
    }

    [Test]
    public static void GetLSBitPosition_ReturnsZeroBasedIndex()
    {
        uint32 bits = (uint32)((1U << 3) | (1U << 9));
        Test.Assert(BitHelpers.GetLSBitPosition(bits) == 3);
        Test.Assert(BitHelpers.GetLSBitPosition(0) == -1);
    }

    [Test]
    public static void GetLSBitPosition_HandlesHighestBit()
    {
        uint32 bits = 1U << 31;
        Test.Assert(BitHelpers.GetLSBitPosition(bits) == 31);
    }

    [Test]
    public static void TruncateFloat_RemovesExcessDigits()
    {
        float value = 3.14159f;
        float truncated = BitHelpers.Truncate(value, 2);
        Test.Assert(Math.Abs(truncated - 3.14f) <= FloatEpsilon);
    }

    [Test]
    public static void TruncateDouble_RemovesExcessDigits()
    {
        double value = 2.718281828;
        double truncated = BitHelpers.Truncate(value, 4);
        Test.Assert(Math.Abs(truncated - 2.7182) <= DoubleEpsilon);
    }

    [Test]
    public static void EnumerateBitFlags_YieldsEachSetBitOnce()
    {
        int64 bits = (1L << 1) | (1L << 3) | (1L << 7) | (1L << 12);
        uint[4] expected = .((uint)(1U << 1), (uint)(1U << 3), (uint)(1U << 7), (uint)(1U << 12));

        int idx = 0;
        var enumerator = BitHelpers.EnumerateBitFlags(bits).GetEnumerator();
        while (true)
        {
            switch (enumerator.GetNext())
            {
            case .Ok(let current):
                Test.Assert(idx < expected.Count);
                Test.Assert((uint)current == expected[idx]);
                idx++;
                continue;
            case .Err:
                break;
            }
            break;
        }

        Test.Assert(idx == expected.Count);
    }

    [Test]
    public static void EnumerateBitFlags_ForLoopWorks()
    {
        int64 bits = (1L << 2) | (1L << 5) | (1L << 31);
        uint[3] expected = .((uint)(1U << 2), (uint)(1U << 5), (uint)(1U << 31));

        int idx = 0;
        for (var flag in BitHelpers.EnumerateBitFlags(bits))
        {
            Test.Assert(idx < expected.Count);
            Test.Assert((uint)flag == expected[idx]);
            idx++;
        }

        Test.Assert(idx == expected.Count);
    }

    [Test]
    public static void EnumerateBitFlags_HandlesMostSignificantBit()
    {
        int64 bits = int64.MinValue;
        var enumerator = BitHelpers.EnumerateBitFlags(bits).GetEnumerator();
        Test.Assert(enumerator.GetNext() case .Ok(let current) && current == bits);
        Test.Assert(enumerator.GetNext() case .Err);
    }

    [Test]
    public static void GetNextBitPos_EnumeratesIndicesInAscendingOrder()
    {
        uint32 bits = (uint32)((1U << 0) | (1U << 4) | (1U << 6) | (1U << 15));
        int32[4] expected = .(0, 4, 6, 15);

        var enumerator = BitHelpers.GetNextBitPos(bits).GetEnumerator();
        int idx = 0;
        while (true)
        {
            switch (enumerator.GetNext())
            {
            case .Ok(let current):
                Test.Assert(idx < expected.Count);
                Test.Assert(current == expected[idx]);
                idx++;
                continue;
            case .Err:
                break;
            }
            break;
        }

        Test.Assert(idx == expected.Count);
    }

    [Test]
    public static void GetNextBitPos_ReturnsHighestIndex()
    {
        uint32 bits = 1U << 31;
        var enumerator = BitHelpers.GetNextBitPos(bits).GetEnumerator();
        Test.Assert(enumerator.GetNext() case .Ok(let current) && current == 31);
        Test.Assert(enumerator.GetNext() case .Err);
    }

}
