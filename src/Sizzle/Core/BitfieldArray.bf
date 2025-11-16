using System;
using System.Collections;

namespace PortalEmulator.Sizzle.Core;

/// @brief A single bitfield block that can track 256 bits using 4 uint64 values.
/// @remarks Blocks can be chained together via the next pointer to form a larger bitfield.
struct BitfieldBlock
{
	const int BITS_PER_BLOCK = 256;
	const int UINT64_PER_BLOCK = 4;

	public uint64[UINT64_PER_BLOCK] bits;
	public BitfieldBlock* next;

	[Inline]
	/// @brief Sets the bit at the specified index within this block.
	/// @param index Local bit index (0-255).
	public void SetBit(int index) mut
	{
		int wordIdx = index >> 6; // Divide by 64
		int bitIdx = index & 63; // Modulo 64
		bits[wordIdx] |= 1UL << bitIdx;
	}

	[Inline]
	/// @brief Clears the bit at the specified index within this block.
	/// @param index Local bit index (0-255).
	public void ClearBit(int index) mut
	{
		int wordIdx = index >> 6;
		int bitIdx = index & 63;
		bits[wordIdx] &= ~(1UL << bitIdx);
	}

	[Inline]
	/// @brief Checks whether a bit is set within this block.
	/// @param index Local bit index (0-255).
	/// @returns True if the bit is set; otherwise false.
	public bool GetBit(int index)
	{
		int wordIdx = index >> 6;
		int bitIdx = index & 63;
		return (bits[wordIdx] & (1UL << bitIdx)) != 0;
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
		for (int i = 0; i < UINT64_PER_BLOCK; i++)
		{
			count += BitHelpers.GetBitCount(bits[i]);
		}
		return count;
	}


	/// @brief Finds the index of the first set bit in this block.
	/// @returns Index of first set bit (0-255), or -1 if no bits are set.
	public int FindFirstSet()
	{
		for (int i = 0; i < UINT64_PER_BLOCK; i++)
		{
			if (bits[i] != 0)
			{
				// Find first set bit in this word
				int bitIdx = BitHelpers.TrailingZeroCount(bits[i]);
				return (i * 64) + bitIdx;
			}
		}
		return -1;
	}

	/// @brief Finds the index of the first clear bit in this block.
	/// @returns Index of first clear bit (0-255), or -1 if all bits are set.
	public int FindFirstClear()
	{
		for (int i = 0; i < UINT64_PER_BLOCK; i++)
		{
			if (bits[i] != ~0UL)
			{
				// Find first clear bit in this word
				uint64 inverted = ~bits[i];
				int bitIdx = BitHelpers.TrailingZeroCount(inverted);
				return (i * 64) + bitIdx;
			}
		}
		return -1;
	}
}

/// @brief Growable bitfield that maintains cache locality through colocated dynamic blocks.
/// @remarks First block is stored inline (SOO), additional blocks are reallocated together on growth.
struct BitfieldArray
{
	const int BITS_PER_BLOCK = 256;
	const int WORDS_PER_BLOCK = BITS_PER_BLOCK / 64;
	const int BITS_PER_BLOCK_MASK = BITS_PER_BLOCK - 1;
	const int BLOCK_SHIFT_DIVIDE = 8;

	private BitfieldBlock mFirstBlock = .(); // Inline first block (small object optimization)
	private int mBlockCount; // Total blocks including first
	private int mCapacity; // Total bits across all blocks

	public int Capacity => mCapacity;

	/// @brief Initializes the bitfield with a single inline block.
	public this()
	{
		mFirstBlock.next = null;
		mBlockCount = 1;
		mCapacity = BITS_PER_BLOCK;
	}

	/// @brief Releases any dynamically allocated blocks.
	public void Dispose() mut
	{
		if (mFirstBlock.next != null)
		{
			Internal.Free(mFirstBlock.next);
			mFirstBlock.next = null;
		}
		mBlockCount = 0;
		mCapacity = 0;
	}

	/// @brief Ensures capacity for at least the specified number of bits.
	/// @param minBits Minimum bit capacity required.
	public void Reserve(int minBits) mut
	{
		while (mCapacity < minBits)
		{
			GrowCapacity();
		}
	}

	/// @brief Adds another block to the array, reallocating dynamic storage.
	private void GrowCapacity() mut
	{
		mBlockCount++;
		mCapacity += BITS_PER_BLOCK;

		// Allocate new colocated block array (excluding first inline block)
		int dynamicBlockCount = mBlockCount - 1;
		BitfieldBlock* newBlocks = (BitfieldBlock*)Internal.Malloc(sizeof(BitfieldBlock) * dynamicBlockCount);

		// Copy old dynamic blocks if they exist
		if (mFirstBlock.next != null)
		{
			Internal.MemCpy(newBlocks, mFirstBlock.next, sizeof(BitfieldBlock) * (dynamicBlockCount - 1));
			Internal.Free(mFirstBlock.next);
		}

		// Initialize new block
		Internal.MemSet(&newBlocks[dynamicBlockCount - 1], 0, sizeof(BitfieldBlock));

		// Link blocks together
		mFirstBlock.next = &newBlocks[0];
		for (int i = 0; i < dynamicBlockCount - 1; i++)
		{
			newBlocks[i].next = &newBlocks[i + 1];
		}
		newBlocks[dynamicBlockCount - 1].next = null;
	}

	[Inline]
	/// @brief Retrieves the block that contains the provided bit index.
	private BitfieldBlock* GetBlock(int index) mut
	{
		int blockIdx = index >> BLOCK_SHIFT_DIVIDE;

		if (blockIdx == 0)
			return &mFirstBlock;

		// Navigate through the linked list (blocks are colocated so this is cache-friendly)
		return &mFirstBlock.next[blockIdx - 1];
	}

	[Inline]
	/// @brief Retrieves a block by its block index instead of bit index.
	private static BitfieldBlock* GetBlockByIndex(ref BitfieldArray array, int blockIdx)
	{
		if (blockIdx == 0)
			return &array.mFirstBlock;
		return &array.mFirstBlock.next[blockIdx - 1];
	}

	[Inline]
	/// @brief Sets a bit by global index, growing the array when necessary.
	/// @param index Zero-based bit index.
	public void SetBit(int index) mut
	{
		if (index >= mCapacity)
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
		if (index >= mCapacity)
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
		if (index >= mCapacity)
			return false;

		BitfieldBlock* block = GetBlock(index);
		return block.GetBit(index & BITS_PER_BLOCK_MASK);
	}

	/// @brief Clears all bits across every block.
	public void ClearAll() mut
	{
		mFirstBlock.Clear();

		BitfieldBlock* current = mFirstBlock.next;
		for (int i = 0; i < mBlockCount - 1; i++)
		{
			current[i].Clear();
		}
	}

	/// @brief Counts total number of set bits across all blocks.
	public int PopCount()
	{
		int count = mFirstBlock.PopCount();

		BitfieldBlock* current = mFirstBlock.next;
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

		BitfieldBlock* current = mFirstBlock.next;
		for (int i = 0; i < mBlockCount - 1; i++)
		{
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

		BitfieldBlock* current = mFirstBlock.next;
		for (int i = 0; i < mBlockCount - 1; i++)
		{
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
		private int mBlockIdx;
		private int mWordIdx;
		private uint64 mCurrentWord;
		private int mBaseIndex;

		/// @brief Creates an enumerator for the provided array.
		public this(BitfieldArray* array)
		{
			mArray = array;
			mBlockIdx = 0;
			mWordIdx = 0;
			mCurrentWord = 0;
			mBaseIndex = 0;
		}

		/// @brief Advances the enumerator and reports the next set bit index.
		public Result<int> GetNext() mut
		{
			if (mCurrentWord == 0)
			{
				if (!AdvanceToNextWord())
					return .Err;
			}

			int bitIdx = BitHelpers.TrailingZeroCount(mCurrentWord);
			mCurrentWord &= mCurrentWord - 1; // Clear lowest set bit
			return .Ok(mBaseIndex + bitIdx);
		}

		/// @brief Loads the next block/word combination that contains at least one set bit.
		private bool AdvanceToNextWord() mut
		{
			for (; mBlockIdx < mArray.mBlockCount; mBlockIdx++)
			{
				BitfieldBlock* blockPtr = (mBlockIdx == 0)
					? &mArray.mFirstBlock
					: &mArray.mFirstBlock.next[mBlockIdx - 1];

				for (; mWordIdx < WORDS_PER_BLOCK; mWordIdx++)
				{
					uint64 word = blockPtr.bits[mWordIdx];
					if (word == 0)
						continue;

					mCurrentWord = word;
					mBaseIndex = (mBlockIdx * BITS_PER_BLOCK) + (mWordIdx * 64);
					mWordIdx++; // Resume search at the following word next time
					return true;
				}

				mWordIdx = 0; // Exhausted this block, reset for the next block
			}

			return false;
		}
	}

	/// @brief Creates an enumerator usable in <c>for</c> loops.
	public SetBitEnumerator GetEnumerator() mut
	{
		return SetBitEnumerator(&this);
	}

	private interface IBitwiseWordOp
	{
		static uint64 Eval(uint64 lhsWord, uint64 rhsWord);
	}

	private static struct BitwiseAndOp : IBitwiseWordOp
	{
		[Inline]
		public static uint64 Eval(uint64 lhsWord, uint64 rhsWord) => lhsWord & rhsWord;
	}

	private static struct BitwiseOrOp : IBitwiseWordOp
	{
		[Inline]
		public static uint64 Eval(uint64 lhsWord, uint64 rhsWord) => lhsWord | rhsWord;
	}

	private static struct BitwiseXorOp : IBitwiseWordOp
	{
		[Inline]
		public static uint64 Eval(uint64 lhsWord, uint64 rhsWord) => lhsWord ^ rhsWord;
	}

	/// @brief Combines two arrays word-by-word using the specified bitwise operation.
	private static BitfieldArray CombineBinary<TOp>(ref BitfieldArray lhs, ref BitfieldArray rhs) where TOp : IBitwiseWordOp
	{
		int blockCount = Math.Max(lhs.mBlockCount, rhs.mBlockCount);
		if (blockCount == 0)
			return BitfieldArray();

		BitfieldArray result = .();
		result.Reserve(blockCount * BITS_PER_BLOCK);

		for (int blockIdx = 0; blockIdx < blockCount; blockIdx++)
		{
			BitfieldBlock* destBlock = GetBlockByIndex(ref result, blockIdx);
			BitfieldBlock* lhsBlock = (blockIdx < lhs.mBlockCount) ? GetBlockByIndex(ref lhs, blockIdx) : null;
			BitfieldBlock* rhsBlock = (blockIdx < rhs.mBlockCount) ? GetBlockByIndex(ref rhs, blockIdx) : null;

			for (int wordIdx = 0; wordIdx < WORDS_PER_BLOCK; wordIdx++)
			{
				uint64 lhsWord = (lhsBlock != null) ? lhsBlock.bits[wordIdx] : 0;
				uint64 rhsWord = (rhsBlock != null) ? rhsBlock.bits[wordIdx] : 0;
				destBlock.bits[wordIdx] = TOp.Eval(lhsWord, rhsWord);
			}
		}

		return result;
	}

	/// @brief Produces a new array with every bit inverted relative to the source.
	private static BitfieldArray Invert(ref BitfieldArray source)
	{
		if (source.mBlockCount == 0)
			return BitfieldArray();

		BitfieldArray result = .();
		result.Reserve(source.mBlockCount * BITS_PER_BLOCK);

		for (int blockIdx = 0; blockIdx < source.mBlockCount; blockIdx++)
		{
			BitfieldBlock* destBlock = GetBlockByIndex(ref result, blockIdx);
			BitfieldBlock* srcBlock = GetBlockByIndex(ref source, blockIdx);
			for (int wordIdx = 0; wordIdx < WORDS_PER_BLOCK; wordIdx++)
				destBlock.bits[wordIdx] = ~srcBlock.bits[wordIdx];
		}

		return result;
	}

	/// @brief Returns a new array containing the bitwise AND of both operands.
	public static BitfieldArray operator &(BitfieldArray lhs, BitfieldArray rhs)
	{
		BitfieldArray lhsCopy = lhs;
		BitfieldArray rhsCopy = rhs;
		return CombineBinary<BitwiseAndOp>(ref lhsCopy, ref rhsCopy);
	}

	/// @brief Returns a new array containing the bitwise OR of both operands.
	public static BitfieldArray operator |(BitfieldArray lhs, BitfieldArray rhs)
	{
		BitfieldArray lhsCopy = lhs;
		BitfieldArray rhsCopy = rhs;
		return CombineBinary<BitwiseOrOp>(ref lhsCopy, ref rhsCopy);
	}

	/// @brief Returns a new array containing the bitwise XOR of both operands.
	public static BitfieldArray operator ^(BitfieldArray lhs, BitfieldArray rhs)
	{
		BitfieldArray lhsCopy = lhs;
		BitfieldArray rhsCopy = rhs;
		return CombineBinary<BitwiseXorOp>(ref lhsCopy, ref rhsCopy);
	}

	/// @brief Returns a new array whose bits are inverted relative to the source array.
	public static BitfieldArray operator ~(BitfieldArray value)
	{
		BitfieldArray valueCopy = value;
		return Invert(ref valueCopy);
	}
}