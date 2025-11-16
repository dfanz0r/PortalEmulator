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
			mCurrentWord = array.mFirstBlock.bits[0];
			mBaseIndex = 0;
		}

		/// @brief Advances the enumerator and reports the next set bit index.
		public Result<int> GetNext() mut
		{
			while (true)
			{
				// Process current word
				if (mCurrentWord != 0)
				{
					int bitIdx = BitHelpers.TrailingZeroCount(mCurrentWord);
					mCurrentWord &= mCurrentWord - 1; // Clear lowest set bit
					return .Ok(mBaseIndex + bitIdx);
				}

				// Move to next word
				mWordIdx++;
				if (mWordIdx < 4)
				{
					mBaseIndex = (mBlockIdx * BITS_PER_BLOCK) + (mWordIdx * 64);
					if (mBlockIdx == 0)
						mCurrentWord = mArray.mFirstBlock.bits[mWordIdx];
					else
						mCurrentWord = mArray.mFirstBlock.next[mBlockIdx - 1].bits[mWordIdx];
					continue;
				}

				// Move to next block
				mBlockIdx++;
				if (mBlockIdx >= mArray.mBlockCount)
					return .Err;

				mWordIdx = 0;
				mBaseIndex = mBlockIdx * BITS_PER_BLOCK;
				if (mBlockIdx == 0)
					mCurrentWord = mArray.mFirstBlock.bits[0];
				else
					mCurrentWord = mArray.mFirstBlock.next[mBlockIdx - 1].bits[0];
			}
		}
	}

	/// @brief Creates an enumerator usable in <c>for</c> loops.
	public SetBitEnumerator GetEnumerator() mut
	{
		return SetBitEnumerator(&this);
	}
}