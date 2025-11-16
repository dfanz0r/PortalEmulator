using System;
using System.Collections;
namespace PortalEmulator.Sizzle.Core;

public static class BitHelpers
{
	/// @brief Returns the most significant set bit of the provided value.
	/// @param bits Input bit mask whose highest set bit is requested.
	/// @returns A mask containing only the highest set bit, or zero when no bits are set.
	[Inline]
	public static T GetHighestBit<T>(T bits)
		where uint32 : operator explicit T
		where T :
		operator explicit uint32,
		operator T + T,
		operator T &+ T,
		operator T >> T,
		operator T | T,
		operator T & T,
		operator ~ T
	{
		var bits; // Shadow copy the parameter

		bits |= bits >> (T)1;
		bits |= bits >> (T)2;
		bits |= bits >> (T)4;
		bits |= bits >> (T)8;
		bits |= bits >> (T)16;
		return bits & ~(bits >> (T)1);
	}

	/// @brief Returns the least significant set bit of the provided value.
	/// @param bits Input bit mask whose lowest set bit is requested.
	/// @returns A mask containing only the lowest set bit, or zero when no bits are set.
	[Inline]
	public static T GetLowestBit<T>(T bits)
		where uint32 : operator explicit T
		where T :
		operator implicit int,
		operator T - T,
		operator T &- T,
		operator T & T,
		operator ~ T
	{
		// There is 3 different ways i know of to get the lowest bit
		// int & -int            good for signed values abuses 2's complement 
		// bits & (~(bits - 1))  good for unsigned values takes advantage of borrow propagation
		// bits & (~bits + 1)    good for unsigned values emulates twos complement negation on unsigned values

		T one = (T)1;
		return (T)(bits & (~(bits &- one)));
	}

	/// @brief Returns the Nth set bit within the mask.
	/// @param bits Source mask to scan.
	/// @param pos Zero-based index of the set bit to return.
	/// @returns Mask containing the requested set bit, or zero if <c>pos</c> exceeds the number of bits.
	[Inline]
	public static T GetFlagAtPos<T>(T bits, int pos)
		where uint32 : operator explicit T
		where T :
		operator implicit int,
		operator T - T,
		operator T &- T,
		operator T & T,
		operator ~ T
	{
		var bits; // Shadow copy the parameter
		int count = 0;
		T one = (T)1;

		// This takes advantage of the fact that when you subtract 1 from a bit it sets the bits under it all to 1
		// Which when & with itself clears both the original bit and all lower bits and exposes the next bit to count.

		while (bits != 0)
		{
			if (count == pos)
			{
				return (T)(bits & (~(bits &- one)));
			}

			bits &= bits &- one;
			count++;
		}

		return 0;
	}

	/// @brief Counts the number of set bits in the provided value.
	/// @param bits Input mask to count.
	/// @returns Total count of bits set to one.
	[Inline]
	public static int GetBitCount<T>(T bits)
		where uint32 : operator explicit T
		where int : operator explicit T
		where T :
		operator explicit int,
		operator T - T,
		operator T &- T,
		operator T & T
	{
		var bits; // Shadow copy the parameter
		int count = 0;
		T one = (T)1;

		// This takes advantage of the fact that when you subtract 1 from a bit it sets the bits under it all to 1
		// Which when & with itself clears both the original bit and all lower bits and exposes the next bit to count.

		while (bits != 0U)
		{
			count++;
			bits &= bits &- one;
		}

		return count;
	}

	private const int32[?] DeBruijnLookupTable = int32[](
		0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
		31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
		);

	/// @brief Get the zero-based position of the least significant set bit.
	/// @param bits Input mask to examine.
	/// @returns The index of the least significant set bit, or -1 if no bits are set.
	[Inline]
	public static int GetLSBitPosition(uint32 bits)
	{
		if (bits == 0)
		{
			return -1;
		}

		uint32 lsBit = bits & (~bits &+ 1U);
		uint32 index = (lsBit &* 0x077CB531U) >> 27;
		return DeBruijnLookupTable[index];
	}

	/// @brief Counts trailing zero bits in a 64-bit mask.
	/// @param v Value to analyze.
	/// @returns Number of zero bits preceding the lowest set bit, or 64 when <c>v</c> is zero.
	[Inline]
	public static int TrailingZeroCount(uint64 v)
	{
		if (v == 0)
		{
			return 64;
		}

		uint32 lower = (uint32)v;
		if (lower != 0)
		{
			return GetLSBitPosition(lower);
		}

		return 32 + GetLSBitPosition((uint32)(v >> 32));
	}

	/// @brief Truncates a floating-point value to the desired number of decimal digits.
	/// @param value Value to truncate.
	/// @param digits Number of digits to keep after the decimal point.
	/// @returns Truncated value without rounding.
	[Inline]
	public static float Truncate(float value, int digits)
	{
		float mult = (float)Math.Pow(10, digits);
		return (int64)(value * mult) / mult;
	}

	/// @brief Truncates a double-precision value to the desired number of decimal digits.
	/// @param value Value to truncate.
	/// @param digits Number of digits to keep after the decimal point.
	/// @returns Truncated value without rounding.
	[Inline]
	public static double Truncate(double value, int digits)
	{
		double mult = Math.Pow(10, digits);
		return (int64)(value * mult) / mult;
	}

	/// @brief Enumerates each set bit value contained in a mask.
	public struct BitFlagEnumerator<T> : IEnumerator<T>
		where uint32 : operator explicit T
		where T :
		operator implicit int,
		operator T - T,
		operator T &- T,
		operator T & T,
		operator T ^ T,
		operator ~ T
	{
		private T remainingBits;

		public this(T bits)
		{
			remainingBits = bits;
		}

		/// @brief Advances the enumerator and returns the next set bit mask.
		/// @returns .Ok(mask) for the next bit or .Err when the sequence is exhausted.
		public Result<T> GetNext() mut
		{
			if (remainingBits == 0)
			{
				return .Err;
			}

			T flag = GetLowestBit(remainingBits);
			remainingBits &= remainingBits &- (T)1;
			return .Ok(flag);
		}
	}

	/// @brief Enumerable wrapper that exposes the BitFlag enumerator to <c>for</c> loops.
	public struct BitFlagEnumerable<T> : IEnumerable<T>
		where uint32 : operator explicit T
		where T :
		operator implicit int,
		operator T - T,
		operator T &- T,
		operator T & T,
		operator T ^ T,
		operator ~ T
	{
		private T bits;

		public this(T bits)
		{
			this.bits = bits;
		}

			/// @brief Creates a new enumerator over the captured mask.
			public BitFlagEnumerator<T> GetEnumerator()
		{
			return .(bits);
		}
	}

	/// @brief Enumerates each individual bit flag contained within a mask.
	/// @param bits Mask to iterate.
	/// @returns Enumerable value suitable for <c>for</c> loops.
	public static BitFlagEnumerable<T> EnumerateBitFlags<T>(T bits)
		where uint32 : operator explicit T
		where T :
		operator implicit int,
		operator T - T,
		operator T &- T,
		operator T & T,
		operator T ^ T,
		operator ~ T
		=> .(bits);

	/// @brief Enumerates the indices of set bits within a 32-bit mask.
	public struct BitCountEnumerator : IEnumerator<int32>
	{
		private uint32 bits;

		public this(uint32 bits)
		{
			this.bits = bits;
		}

		/// @brief Advances the enumerator and returns the next set bit index.
		/// @returns .Ok(index) for the next set bit or .Err when the mask is empty.
		public Result<int32> GetNext() mut
		{
			if (bits == 0)
			{
				return .Err;
			}

			uint32 lsBit = bits & (~bits &+ 1U);
			uint32 index = (lsBit &* 0x077CB531U) >> 27;
			bits &= ~lsBit;
			return .Ok(DeBruijnLookupTable[index]);
		}
	}

	/// @brief Enumerable wrapper exposing BitCountEnumerator to range-based loops.
	public struct BitCountEnumerable : IEnumerable<int32>
	{
		private uint32 bits;

		public this(uint32 bits)
		{
			this.bits = bits;
		}

		/// @brief Creates a new enumerator over the provided mask snapshot.
		public BitCountEnumerator GetEnumerator()
		{
			return .(bits);
		}
	}

	/// @brief Enumerates the indices of set bits in ascending order.
	/// @param bits Mask to iterate.
	/// @returns Enumerable value whose enumerator yields each set bit index.
	[Inline]
	public static BitCountEnumerable GetNextBitPos(uint32 bits) => .(bits);
}