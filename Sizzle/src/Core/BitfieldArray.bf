using System;
using System.Collections;
using System.Numerics;
using System.Numerics.X86;
using Sizzle.Math;

namespace Sizzle.Core;
using internal Sizzle.Math;
using internal Sizzle.Core;

/// @brief A single bitfield block that can track 256 bits using 4 uint64 values.
/// @remarks Blocks carry only their bit storage; <see cref="BitfieldArray"/> arranges them contiguously in memory.
[Union]
struct BitfieldBlock
{
	const int BITS_PER_BLOCK = 256;
	const int UINT64_PER_BLOCK = 4;

	// WARNING: BitfieldBlock must remain trivially copyable. 
	// Do not add non-POD members.
	public uint64[UINT64_PER_BLOCK] bits;

	[Inline]
	/// @brief Sets the bit at the specified index within this block.
	/// @param index Local bit index (0-255).
	public void SetBit(int index) mut
	{
		bits[index >> 6] |= 1UL << (index & 63);
	}

	[Inline]
	/// @brief Clears the bit at the specified index within this block.
	/// @param index Local bit index (0-255).
	public void ClearBit(int index) mut
	{
		bits[index >> 6] &= ~(1UL << (index & 63));
	}

	[Inline]
	/// @brief Checks whether a bit is set within this block.
	/// @param index Local bit index (0-255).
	/// @returns True if the bit is set; otherwise false.
	public bool GetBit(int index)
	{
		return (bits[index >> 6] & (1UL << (index & 63))) != 0;
	}

	[Inline]
	/// @brief Resets all bits to zero within this block.
	public void Clear() mut
	{
		Internal.MemSet(&bits, 0, sizeof(uint64) * UINT64_PER_BLOCK);
	}

	[Inline]
	/// @brief Determines whether the block contains no set bits.
	/// @returns True when every bit is zero.
	public bool IsEmpty()
	{
		return bits[0] == 0 && bits[1] == 0 && bits[2] == 0 && bits[3] == 0;
	}

	[Inline]
	/// @brief Determines whether the block has every bit set.
	/// @returns True when all bits are one.
	public bool IsFull()
	{
		return bits[0] == ~0UL && bits[1] == ~0UL && bits[2] == ~0UL && bits[3] == ~0UL;
	}

	/// @brief Counts the number of set bits in this block.
	public int PopCount()
	{
		int count = 0;
		count += BitHelpers.GetBitCount(bits[0]);
		count += BitHelpers.GetBitCount(bits[1]);
		count += BitHelpers.GetBitCount(bits[2]);
		count += BitHelpers.GetBitCount(bits[3]);
		return count;
	}


	/// @brief Finds the index of the first set bit in this block.
	/// @returns Index of first set bit (0-255), or -1 if no bits are set.
	public int FindFirstSet()
	{
		// Determine if each word is non-zero.
		int w0_nz = (bits[0] != 0) ? 1 : 0;
		int w1_nz = (bits[1] != 0) ? 1 : 0;
		int w2_nz = (bits[2] != 0) ? 1 : 0;
		int w3_nz = (bits[3] != 0) ? 1 : 0;

		// Determine which word is the FIRST non-zero word.
		// w0_sel will be 1 if bits[0] is the first, otherwise 0.
		// w1_sel will be 1 if bits[1] is the first, otherwise 0. And so on.
		int w0_sel = w0_nz;
		int w1_sel = w1_nz & (1 - w0_nz); // Select if w1 is non-zero AND w0 was zero.
		int w2_sel = w2_nz & (1 - (w0_nz | w1_nz)); // Select if w2 is non-zero AND w0,w1 were zero.
		int w3_sel = w3_nz & (1 - (w0_nz | w1_nz | w2_nz)); // Select if w3 is non-zero AND w0,w1,w2 were zero.

		// Calculate the TrailingZeroCount for each word unconditionally.
		// The selector logic ensures we only use the result from the correct non-zero word.
		int tzc0 = BitHelpers.TrailingZeroCount(bits[0]);
		int tzc1 = BitHelpers.TrailingZeroCount(bits[1]);
		int tzc2 = BitHelpers.TrailingZeroCount(bits[2]);
		int tzc3 = BitHelpers.TrailingZeroCount(bits[3]);

		// Combine the results using the selectors. Only one selector can be 1,
		// so this effectively picks one of the results.
		int result = (w0_sel * tzc0)
			+ (w1_sel * (64 + tzc1))
			+ (w2_sel * (128 + tzc2))
			+ (w3_sel * (192 + tzc3));

		// Handle the case where no bits are set in the entire block.
		int any_word_found = w0_nz | w1_nz | w2_nz | w3_nz; // Will be 1 if any word is non-zero, else 0.
		int not_found_mask = any_word_found - 1; // Becomes -1 (all bits set) if nothing found, 0 otherwise.
		
		// If nothing was found, this ORs the result with -1. Otherwise, it ORs with 0.
		return result | not_found_mask;
	}

	/// @brief Finds the index of the first clear bit in this block.
	/// @returns Index of first clear bit (0-255), or -1 if all bits are set.
	public int FindFirstClear()
	{
		// Invert the bits to find the first "clear" bit, which is now the first "set" bit.
		uint64 b0 = ~bits[0];
		uint64 b1 = ~bits[1];
		uint64 b2 = ~bits[2];
		uint64 b3 = ~bits[3];

		// Determine if each inverted word is non-zero.
		int w0_nz = (b0 != 0) ? 1 : 0;
		int w1_nz = (b1 != 0) ? 1 : 0;
		int w2_nz = (b2 != 0) ? 1 : 0;
		int w3_nz = (b3 != 0) ? 1 : 0;

		// The rest of the logic is identical to FindFirstSet.
		int w0_sel = w0_nz;
		int w1_sel = w1_nz & (1 - w0_nz);
		int w2_sel = w2_nz & (1 - (w0_nz | w1_nz));
		int w3_sel = w3_nz & (1 - (w0_nz | w1_nz | w2_nz));

		int tzc0 = BitHelpers.TrailingZeroCount(b0);
		int tzc1 = BitHelpers.TrailingZeroCount(b1);
		int tzc2 = BitHelpers.TrailingZeroCount(b2);
		int tzc3 = BitHelpers.TrailingZeroCount(b3);

		int result = (w0_sel * tzc0)
			+ (w1_sel * (64 + tzc1))
			+ (w2_sel * (128 + tzc2))
			+ (w3_sel * (192 + tzc3));

		int any_word_found = w0_nz | w1_nz | w2_nz | w3_nz;
		int not_found_mask = any_word_found - 1;

		return result | not_found_mask;
	}

}

/// @brief Growable bitfield that maintains cache locality through colocated dynamic blocks.
/// @remarks First block is stored inline (SOO) while additional blocks live in a single contiguous allocation tracked by mDynamicBlocks
struct BitfieldArray : IDisposable
{
	const int BITS_PER_BLOCK = 256;
	const int WORDS_PER_BLOCK = BITS_PER_BLOCK / 64;
	const int BITS_PER_BLOCK_MASK = BITS_PER_BLOCK - 1;
	const int BLOCK_SHIFT_DIVIDE = 8;

	private BitfieldBlock mFirstBlock = .(); // Inline first block (small object optimization)
	private BitfieldBlock* mDynamicBlocks; // Contiguous heap storage for additional blocks
	private int mBlockCount; // Total blocks including first

	[Inline]
	public int Capacity => BITS_PER_BLOCK * mBlockCount;

	/// @brief Initializes the bitfield with a single inline block.
	public this()
	{
		mDynamicBlocks = null;
		mBlockCount = 1;
	}

	/// @brief Releases any dynamically allocated blocks.
	public void Dispose() mut
	{
		if (mDynamicBlocks != null)
		{
			// We only ever allocate all dynamic blocks together in a single allocation
			// so we can just free them all at once.
			Internal.Free(mDynamicBlocks);
			mDynamicBlocks = null;
		}
		mFirstBlock.Clear();
		mBlockCount = 0;
	}

	/// @brief Ensures capacity for at least the specified number of bits.
	/// @param minBits Minimum bit capacity required.
	public void Reserve(int minBits) mut
	{
		if (minBits <= Capacity)
			return;

		int requiredBlockCount = Math.Max(1, (minBits + BITS_PER_BLOCK - 1) >> BLOCK_SHIFT_DIVIDE);
		GrowCapacity(requiredBlockCount);
	}

	/// @brief Grows the array to accommodate the requested block count.
	private void GrowCapacity(int targetBlockCount) mut
	{
		if (targetBlockCount <= mBlockCount)
			return;

		int oldBlockCount = mBlockCount;
		int oldDynamicCount = Math.Max(oldBlockCount - 1, 0);
		int newDynamicCount = Math.Max(targetBlockCount - 1, 0);

		mBlockCount = targetBlockCount;

		// Handle case of shrinking to zero dynamic blocks
		if (newDynamicCount == 0)
		{
			if (mDynamicBlocks != null)
			{
				Internal.Free(mDynamicBlocks);
				mDynamicBlocks = null;
			}
			return;
		}

		// Allocate new dynamic blocks and copy existing data
		BitfieldBlock* newBlocks = (BitfieldBlock*)Internal.Malloc(sizeof(BitfieldBlock) * newDynamicCount);

		if (oldDynamicCount > 0 && mDynamicBlocks != null)
		{
			Internal.MemCpy(newBlocks, mDynamicBlocks, sizeof(BitfieldBlock) * oldDynamicCount);
			Internal.Free(mDynamicBlocks);
		}
		else if (mDynamicBlocks != null)
		{
			Internal.Free(mDynamicBlocks);
		}

		// Zero out any newly allocated blocks
		int freshlyAllocatedCount = newDynamicCount - oldDynamicCount;
		if (freshlyAllocatedCount > 0)
		{
			Internal.MemSet(&newBlocks[oldDynamicCount], 0, sizeof(BitfieldBlock) * freshlyAllocatedCount);
		}

		mDynamicBlocks = newBlocks;
	}

	[Inline]
	/// @brief Retrieves the block that contains the provided bit index.
	private BitfieldBlock* GetBlock(int index) mut
	{
		int blockIdx = index >> BLOCK_SHIFT_DIVIDE;
		return blockIdx == 0 ? &mFirstBlock : &mDynamicBlocks[blockIdx - 1];
	}

	
	[Inline]
	/// @brief Retrieves a block by its block index instead of bit index.
	private BitfieldBlock* GetBlockByIndex(int blockIdx) mut
	{
		return blockIdx == 0 ? &mFirstBlock : &mDynamicBlocks[blockIdx - 1];
	}


	[Inline]
	/// @brief Sets a bit by global index, growing the array when necessary.
	/// @param index Zero-based bit index.
	public void SetBit(int index) mut
	{
		if (index >= Capacity)
		{
			Reserve(index + 1);
		}

		BitfieldBlock* block = GetBlock(index);
		block.SetBit(index & BITS_PER_BLOCK_MASK);
	}

	[Inline]
	/// @brief Clears a bit by global index if it exists.
	/// @param index Zero-based bit index.
	public void ClearBit(int index) mut
	{
		if (index >= Capacity)
			return;

		BitfieldBlock* block = GetBlock(index);
		block.ClearBit(index & BITS_PER_BLOCK_MASK);
	}

	[Inline]
	/// @brief Reads the bit at the specified index.
	/// @param index Zero-based bit index.
	/// @returns True if the bit is set; otherwise false.
	public bool GetBit(int index) mut
	{
		return index >= Capacity ? false : GetBlock(index).GetBit(index & BITS_PER_BLOCK_MASK);
	}

	/// @brief Clears all bits across every block.
	public void ClearAll() mut
	{
		mFirstBlock.Clear();

		BitfieldBlock* current = mDynamicBlocks;
		for (int i = 0; i < mBlockCount - 1; i++)
		{
			current[i].Clear();
		}
	}

	/// @brief Counts total number of set bits across all blocks.
	public int PopCount()
	{
		int count = mFirstBlock.PopCount();

		BitfieldBlock* current = mDynamicBlocks;
		for (int i = 0; i < mBlockCount - 1; i++)
		{
			count += current[i].PopCount();
		}

		return count;
	}

	/// @brief Finds the first set bit across all blocks.
	/// @returns Global bit index, or -1 if no bits are set.
	public int FindFirstSet()
	{
		int localIdx = mFirstBlock.FindFirstSet();
		if (localIdx >= 0)
			return localIdx;

		BitfieldBlock* current = mDynamicBlocks;
		for (int i = 0; i < mBlockCount - 1; i++)
		{
			if (current[i].IsEmpty())
				continue;
			localIdx = current[i].FindFirstSet();
			if (localIdx >= 0)
				return ((i + 1) * BITS_PER_BLOCK) + localIdx;
		}

		return -1;
	}

	/// @brief Finds the first clear bit across all blocks.
	/// @returns Global bit index, or -1 if all bits are set.
	public int FindFirstClear()
	{
		int localIdx = mFirstBlock.FindFirstClear();
		if (localIdx >= 0)
			return localIdx;

		BitfieldBlock* current = mDynamicBlocks;
		for (int i = 0; i < mBlockCount - 1; i++)
		{
			if (current[i].IsFull())
				continue;
			localIdx = current[i].FindFirstClear();
			if (localIdx >= 0)
				return ((i + 1) * BITS_PER_BLOCK) + localIdx;
		}

		return -1;
	}

	/// @brief Iterate over all set bit indices.
	public struct SetBitEnumerator : IEnumerator<int>
	{
		private BitfieldArray* mArray;
		private uint64 mCurrentWord;
		private int mNextGlobalWordIdx; // The single, multi-block spanning word index.
		private const int WORDS_PER_BLOCK = 4;
		private const int WORD_BLOCK_SHIFT = 2;
		private const int WORD_IN_BLOCK_MASK = 3;

		/// @brief Creates an enumerator for the provided array.
		public this(BitfieldArray* array)
		{
			mArray = array;
			mCurrentWord = 0;
			mNextGlobalWordIdx = 0;
		}

		/// @brief Advances the enumerator and reports the next set bit index.
		public Result<int> GetNext() mut
		{
			if (mCurrentWord == 0)
			{
				// Find the next word in the entire array that has bits set.
				if (!AdvanceToNextWord())
					return .Err; // No more set bits anywhere.
			}

			// At this point, mCurrentWord is guaranteed to be non-zero.
			int bitIdx = BitHelpers.TrailingZeroCount(mCurrentWord);
			mCurrentWord &= mCurrentWord - 1; // Clear the lowest set bit to consume it.

			// The base index is the start of the word we *just* found.
			// Since mNextGlobalWordIdx was already advanced, we subtract 1.
			int baseIndex = (mNextGlobalWordIdx - 1) * 64;
			return .Ok(baseIndex + bitIdx);
		}

		/// @brief Finds the next word in the array that contains at least one set bit.
		private bool AdvanceToNextWord() mut
		{
			int totalWords = mArray.mBlockCount * WORDS_PER_BLOCK;

			// Linearly scan through all remaining words in the entire array.
			for (; mNextGlobalWordIdx < totalWords; mNextGlobalWordIdx++)
			{
				// Decompose the global index into block and word-in-block indices.
				int blockIdx = mNextGlobalWordIdx >> WORD_BLOCK_SHIFT;
				int wordInBlockIdx = mNextGlobalWordIdx & WORD_IN_BLOCK_MASK;

				// Get the correct block pointer.
				BitfieldBlock* blockPtr = (blockIdx == 0) ? &mArray.mFirstBlock : &mArray.mDynamicBlocks[blockIdx - 1];
				uint64 word = blockPtr.bits[wordInBlockIdx];

				if (word != 0)
				{
					mCurrentWord = word;
					mNextGlobalWordIdx++; // Advance the index for the *next* search.
					return true;
				}
			}

			return false; // Reached the end of the array.
		}
	}

	/// @brief Creates an enumerator usable in <c>for</c> loops.
	public SetBitEnumerator GetEnumerator() mut
	{
		return SetBitEnumerator(&this);
	}

	private interface IBitwiseWordOp
	{
		static void Apply(ref BitfieldBlock destBlock, in BitfieldBlock lhsBlock, in BitfieldBlock rhsBlock);
	}

	private static struct BitwiseAndOp : IBitwiseWordOp
	{
		[Inline]
		public static void Apply(ref BitfieldBlock destBlock, in BitfieldBlock lhsBlock, in BitfieldBlock rhsBlock)
		{
			destBlock.bits[0] = lhsBlock.bits[0] & rhsBlock.bits[0];
			destBlock.bits[1] = lhsBlock.bits[1] & rhsBlock.bits[1];
			destBlock.bits[2] = lhsBlock.bits[2] & rhsBlock.bits[2];
			destBlock.bits[3] = lhsBlock.bits[3] & rhsBlock.bits[3];
		}
	}

	private static struct BitwiseOrOp : IBitwiseWordOp
	{
		[Inline]
		public static void Apply(ref BitfieldBlock destBlock, in BitfieldBlock lhsBlock, in BitfieldBlock rhsBlock)
		{
			destBlock.bits[0] = lhsBlock.bits[0] | rhsBlock.bits[0];
			destBlock.bits[1] = lhsBlock.bits[1] | rhsBlock.bits[1];
			destBlock.bits[2] = lhsBlock.bits[2] | rhsBlock.bits[2];
			destBlock.bits[3] = lhsBlock.bits[3] | rhsBlock.bits[3];
		}
	}

	private static struct BitwiseXorOp : IBitwiseWordOp
	{
		[Inline]
		public static void Apply(ref BitfieldBlock destBlock, in BitfieldBlock lhsBlock, in BitfieldBlock rhsBlock)
		{
			destBlock.bits[0] = lhsBlock.bits[0] ^ rhsBlock.bits[0];
			destBlock.bits[1] = lhsBlock.bits[1] ^ rhsBlock.bits[1];
			destBlock.bits[2] = lhsBlock.bits[2] ^ rhsBlock.bits[2];
			destBlock.bits[3] = lhsBlock.bits[3] ^ rhsBlock.bits[3];
		}
	}

	/// @brief Performs an in-place bitwise AND with another array.
	public void operator &=(BitfieldArray rhs) mut
	{
		int commonBlocks = Math.Min(mBlockCount, rhs.mBlockCount);

		BitwiseAndOp.Apply(ref mFirstBlock, mFirstBlock, rhs.mFirstBlock);

		for (int i = 0; i < commonBlocks-1; i++)
		{
			BitwiseAndOp.Apply(ref mDynamicBlocks[i], mDynamicBlocks[i], rhs.mDynamicBlocks[i]);
		}

		// Clear any remaining blocks in lhs that exceed rhs length
		for (int i = commonBlocks; i < mBlockCount; i++)
		{
			GetBlockByIndex(i).Clear();
		}
	}

	/// @brief Performs an in-place bitwise OR with another array.
	public void operator |=(BitfieldArray rhs) mut
	{
		if (rhs.mBlockCount > mBlockCount)
			GrowCapacity(rhs.mBlockCount);

		BitwiseOrOp.Apply(ref mFirstBlock, mFirstBlock, rhs.mFirstBlock);

		for (int i = 0; i < mBlockCount-1; i++)
		{
			BitwiseOrOp.Apply(ref mDynamicBlocks[i], mDynamicBlocks[i], rhs.mDynamicBlocks[i]);
		}
	}

	/// @brief Performs an in-place bitwise XOR with another array.
	public void operator ^=(BitfieldArray rhs) mut
	{
		if (rhs.mBlockCount > mBlockCount)
			GrowCapacity(rhs.mBlockCount);

		BitwiseXorOp.Apply(ref mFirstBlock, mFirstBlock, rhs.mFirstBlock);

		for (int i = 0; i < mBlockCount-1; i++)
		{
			BitwiseXorOp.Apply(ref mDynamicBlocks[i], mDynamicBlocks[i], rhs.mDynamicBlocks[i]);
		}
	}

	/// @brief Combines two arrays word-by-word using the specified bitwise operation.
	[Inline]
	private static BitfieldArray CombineBinary<TOp>(ref BitfieldArray lhs, ref BitfieldArray rhs) where TOp : IBitwiseWordOp
	{
		int blockCount = Math.Max(lhs.mBlockCount, rhs.mBlockCount);
		if (blockCount == 0)
			return BitfieldArray();

		BitfieldArray result = .();
		result.Reserve(blockCount * BITS_PER_BLOCK);

		BitfieldBlock zeroBlock = .();

		// Handle first block
		{
			BitfieldBlock* lhsBlock = (lhs.mBlockCount > 0) ? &lhs.mFirstBlock : &zeroBlock;
			BitfieldBlock* rhsBlock = (rhs.mBlockCount > 0) ? &rhs.mFirstBlock : &zeroBlock;
			TOp.Apply(ref result.mFirstBlock, *lhsBlock, *rhsBlock);
		}

		// Handle dynamic blocks
		for (int i = 0; i < blockCount - 1; i++)
		{
			BitfieldBlock* destBlock = &result.mDynamicBlocks[i];
			BitfieldBlock* lhsBlock = (i + 1 < lhs.mBlockCount) ? &lhs.mDynamicBlocks[i] : &zeroBlock;
			BitfieldBlock* rhsBlock = (i + 1 < rhs.mBlockCount) ? &rhs.mDynamicBlocks[i] : &zeroBlock;
			TOp.Apply(ref *destBlock, *lhsBlock, *rhsBlock);
		}

		return result;
	}

	/// @brief Produces a new array with every bit inverted relative to the source.
	[Inline]
	private static BitfieldArray Invert(ref BitfieldArray source)
	{
		if (source.mBlockCount == 0)
			return BitfieldArray();

		BitfieldArray result = .();
		result.Reserve(source.mBlockCount * BITS_PER_BLOCK);

		for (int blockIdx = 0; blockIdx < source.mBlockCount; blockIdx++)
		{
			BitfieldBlock* destBlock = result.GetBlockByIndex(blockIdx);
			BitfieldBlock* srcBlock = source.GetBlockByIndex(blockIdx);
			destBlock.bits[0] = ~srcBlock.bits[0];
			destBlock.bits[1] = ~srcBlock.bits[1];
			destBlock.bits[2] = ~srcBlock.bits[2];
			destBlock.bits[3] = ~srcBlock.bits[3];
		}

		return result;
	}

	/// @brief Returns a new array containing the bitwise AND of both operands.
	public static BitfieldArray operator &(ref BitfieldArray lhs, ref BitfieldArray rhs)
	{
		return CombineBinary<BitwiseAndOp>(ref lhs, ref rhs);
	}

	/// @brief Returns a new array containing the bitwise OR of both operands.
	public static BitfieldArray operator |(ref BitfieldArray lhs, ref BitfieldArray rhs)
	{
		return CombineBinary<BitwiseOrOp>(ref lhs, ref rhs);
	}

	/// @brief Returns a new array containing the bitwise XOR of both operands.
	public static BitfieldArray operator ^(ref BitfieldArray lhs, ref BitfieldArray rhs)
	{
		return CombineBinary<BitwiseXorOp>(ref lhs, ref rhs);
	}

	/// @brief Returns a new array whose bits are inverted relative to the source array.
	public static BitfieldArray operator ~(ref BitfieldArray value)
	{
		return Invert(ref value);
	}
}