using System;
using Sizzle.Core;

namespace Sizzle.Tests;

static class BitfieldArrayTests
{
	private const int BitsPerBlock = 256;

	[Test]
	public static void SetBit_GrowsCapacityAndReadsBack()
	{
		BitfieldArray bitfield = .();
		defer bitfield.Dispose();

		bitfield.SetBit(0);
		bitfield.SetBit(63);
		bitfield.SetBit(BitsPerBlock);
		bitfield.SetBit(BitsPerBlock * 2);

		Test.Assert(bitfield.Capacity >= BitsPerBlock * 3);
		Test.Assert(bitfield.GetBit(0));
		Test.Assert(bitfield.GetBit(63));
		Test.Assert(bitfield.GetBit(BitsPerBlock));
		Test.Assert(bitfield.GetBit(BitsPerBlock * 2));
		Test.Assert(!bitfield.GetBit(BitsPerBlock * 2 + 1));
	}

	[Test]
	public static void ClearBit_RemovesBitWhenSet()
	{
		BitfieldArray bitfield = .();
		defer bitfield.Dispose();

		bitfield.SetBit(42);
		Test.Assert(bitfield.GetBit(42));

		bitfield.ClearBit(42);
		Test.Assert(!bitfield.GetBit(42));
	}

	[Test]
	public static void PopCount_SumsAcrossBlocks()
	{
		BitfieldArray bitfield = .();
		defer bitfield.Dispose();

		bitfield.SetBit(1);
		bitfield.SetBit(BitsPerBlock + 5);
		bitfield.SetBit((BitsPerBlock * 2) + 127);

		Test.Assert(bitfield.PopCount() == 3);
	}

	[Test]
	public static void FindFirstSet_ReturnsLowestGlobalIndex()
	{
		BitfieldArray bitfield = .();
		defer bitfield.Dispose();

		bitfield.SetBit(BitsPerBlock + 7);
		Test.Assert(bitfield.FindFirstSet() == BitsPerBlock + 7);

		bitfield.SetBit(3);
		Test.Assert(bitfield.FindFirstSet() == 3);
	}

	[Test]
	public static void FindFirstClear_ReturnsFirstZero()
	{
		BitfieldArray bitfield = .();
		defer bitfield.Dispose();

		for (int i = 0; i < 16; i++)
		{
			if (i == 7)
				continue;
			bitfield.SetBit(i);
		}

		Test.Assert(bitfield.FindFirstClear() == 7);

		bitfield.SetBit(7);

		for (int i = 16; i < BitsPerBlock; i++)
		{
			bitfield.SetBit(i);
		}

		Test.Assert(bitfield.FindFirstClear() == -1);

		bitfield.SetBit(BitsPerBlock);
		bitfield.ClearBit(BitsPerBlock);
		Test.Assert(bitfield.FindFirstClear() == BitsPerBlock);
	}

	[Test]
	public static void ClearAll_ResetsAllBits()
	{
		BitfieldArray bitfield = .();
		defer bitfield.Dispose();

		bitfield.SetBit(0);
		bitfield.SetBit(BitsPerBlock - 1);
		bitfield.SetBit(BitsPerBlock * 3);

		bitfield.ClearAll();

		Test.Assert(bitfield.PopCount() == 0);
		Test.Assert(bitfield.FindFirstSet() == -1);
		Test.Assert(bitfield.FindFirstClear() == 0);
	}

	[Test]
	public static void Enumerator_YieldsSortedSetBits()
	{
		BitfieldArray bitfield = .();
		defer bitfield.Dispose();

		int[4] expected = .(5, BitsPerBlock, BitsPerBlock + 9, (BitsPerBlock * 2) + 63);
		for (int value in expected)
		{
			bitfield.SetBit(value);
		}

		int idx = 0;
		var enumerator = bitfield.GetEnumerator();
		while (true)
		{
			switch (enumerator.GetNext())
			{
			case .Ok(let bitIdx):
				Test.Assert(idx < expected.Count);
				Test.Assert(bitIdx == expected[idx]);
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
	public static void BitwiseOperators_CombineArrays()
	{
		BitfieldArray lhs = .();
		defer lhs.Dispose();
		lhs.SetBit(1);
		lhs.SetBit(BitsPerBlock + 5);
		lhs.SetBit((BitsPerBlock * 2) + 127);

		BitfieldArray rhs = .();
		defer rhs.Dispose();
		rhs.SetBit(1);
		rhs.SetBit(63);
		rhs.SetBit((BitsPerBlock * 2) + 127);
		rhs.SetBit((BitsPerBlock * 2) + 200);

		BitfieldArray andResult = lhs & rhs;
		defer andResult.Dispose();
		Test.Assert(andResult.GetBit(1));
		Test.Assert(andResult.GetBit((BitsPerBlock * 2) + 127));
		Test.Assert(!andResult.GetBit(BitsPerBlock + 5));

		BitfieldArray orResult = lhs | rhs;
		defer orResult.Dispose();
		Test.Assert(orResult.GetBit(63));
		Test.Assert(orResult.GetBit(BitsPerBlock + 5));
		Test.Assert(orResult.GetBit((BitsPerBlock * 2) + 200));

		BitfieldArray xorResult = lhs ^ rhs;
		defer xorResult.Dispose();
		Test.Assert(!xorResult.GetBit(1));
		Test.Assert(xorResult.GetBit(BitsPerBlock + 5));
		Test.Assert(xorResult.GetBit((BitsPerBlock * 2) + 200));

		BitfieldArray notResult = ~lhs;
		defer notResult.Dispose();
		Test.Assert(!notResult.GetBit(1));
		Test.Assert(!notResult.GetBit((BitsPerBlock * 2) + 127));
		Test.Assert(notResult.GetBit(0));
		Test.Assert(notResult.GetBit(63));
	}
}
