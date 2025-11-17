using System;
using System.Collections;
namespace PortalEmulator.Sizzle.Core;

/// @brief Generic slab allocator optimized for fixed-size objects.
/// @details Allocates memory in contiguous slabs and tracks free slots via a bitfield for O(1) reuse.
struct SlabAllocator<T> : ITypedAllocator, IDisposable
{
	struct Slab
	{
		public void* memory; // Aligned address used for allocations
		public void* rawMemory; // Original pointer returned by malloc for proper free
		public int capacity;
		public Slab* next;
	}

	const int DEFAULT_SLAB_CAPACITY = 64;

	Slab* mSlabs;
	int mSlabCapacity;
	int mTotalCapacity;
	int mAllocCount;
	int mObjectSize;
	int mObjectAlign;
	BitfieldArray mFreeBits; // Bitfield tracking free slots (1 = free, 0 = used)

	/// @brief Ensures the allocator knows the true object size/alignment before carving slabs.
	private void EnsureObjectLayout(int size, int align) mut
	{
		int requestedAlign = Math.Max(align, 1);
		bool needsAlignUpdate = requestedAlign > mObjectAlign;
		bool needsSizeUpdate = size > mObjectSize;

		if (!(needsAlignUpdate || needsSizeUpdate))
			return;

		Runtime.Assert(mTotalCapacity == 0, "SlabAllocator object layout changed after allocations");

		if (needsAlignUpdate)
			mObjectAlign = requestedAlign;
		if (needsSizeUpdate)
			mObjectSize = size;

		mObjectSize = (int)Math.Align(mObjectSize, mObjectAlign);
	}

	/// @brief Creates a slab allocator for objects of type T.
	/// @param slabCapacity Number of objects each slab should store.
	public this(int slabCapacity = DEFAULT_SLAB_CAPACITY)
	{
		mSlabCapacity = slabCapacity;
		mObjectSize = sizeof(T);
		mObjectAlign = Math.Max(alignof(T), 1);

		// Align object size to its alignment requirement
		mObjectSize = (int)Math.Align(mObjectSize, mObjectAlign);

		mSlabs = null;
		mTotalCapacity = 0;
		mAllocCount = 0;
		mFreeBits = .();
	}

	/// @brief Releases all slabs and clears internal bookkeeping.
	public void Dispose() mut
	{
		// Free all slabs
		Slab* current = mSlabs;
		while (current != null)
		{
			Slab* next = current.next;
			Internal.Free(current.rawMemory);
			Internal.Free(current);
			current = next;
		}

		mFreeBits.Dispose();
	}

	/// @brief Adds a fresh slab and marks its slots as free.
	private void AllocateSlab() mut
	{
		// Allocate new slab with aligned memory
		Slab* slab = (Slab*)Internal.Malloc(sizeof(Slab));
		slab.capacity = mSlabCapacity;

		// Allocate extra space to ensure we can align the first element
		int totalSize = mObjectSize * mSlabCapacity + mObjectAlign;
		void* rawMemory = (void*)Internal.Malloc(totalSize);

		// Align the start of usable memory
		slab.rawMemory = rawMemory;
		slab.memory = (void*)(int)Math.Align((int)rawMemory, mObjectAlign);
		slab.next = mSlabs;
		mSlabs = slab;

		// Mark all new slots as free in the bitfield
		int oldCapacity = mTotalCapacity;
		mTotalCapacity += mSlabCapacity;

		for (int i = oldCapacity; i < mTotalCapacity; i++)
		{
			mFreeBits.SetBit(i);
		}
	}

	/// @brief Resolves the backing pointer for a logical slot index.
	/// @param slotIndex Zero-based slot index across all slabs.
	/// @returns Pointer to the slot storage or null for zero-sized types.
	private void* GetSlotPointer(int slotIndex)
	{
		// Handle zero-sized types
		if (mObjectSize == 0)
			return null;

		int slabIndex = slotIndex / mSlabCapacity;
		int slotInSlab = slotIndex % mSlabCapacity;

		// Walk slab linked list to find the right slab
		Slab* slab = mSlabs;

		// Note: slabs are in reverse order (newest first)
		// We need to count total slabs first, then skip from the end
		int totalSlabs = 0;
		Slab* counter = mSlabs;
		while (counter != null)
		{
			totalSlabs++;
			counter = counter.next;
		}

		// Skip to the correct slab (from the end)
		int targetSlabFromEnd = totalSlabs - 1 - slabIndex;
		for (int i = 0; i < targetSlabFromEnd && slab != null; i++)
		{
			slab = slab.next;
		}

		Runtime.Assert(slab != null, "Invalid slab index");
		return (uint8*)slab.memory + (slotInSlab * mObjectSize);
	}

	// IRawAllocator implementation
	/// @brief IRawAllocator entry point that delegates to the typed allocator path.
	public void* Alloc(int size, int align) mut
	{
		EnsureObjectLayout(size, align);
		return AllocTyped(typeof(T), size, align);
	}

	// ITypedAllocator implementation
	/// @brief Allocates space for one object of type T.
	public void* AllocTyped(Type type, int size, int align) mut
	{
		Runtime.Assert(type == typeof(T), "SlabAllocator received a mismatched type");

		EnsureObjectLayout(size, align);

		// Find first free slot using bitfield
		int slot = mFreeBits.FindFirstSet();

		// If no free slot, allocate a new slab
		if (slot < 0)
		{
			AllocateSlab();
			slot = mFreeBits.FindFirstSet();
			Runtime.Assert(slot >= 0, "Should have free slot after allocation");
		}

		// Mark slot as used
		mFreeBits.ClearBit(slot);
		mAllocCount++;

		// Get pointer to the slot
		return GetSlotPointer(slot);
	}

	// IRawAllocator implementation
	/// @brief Frees a previously allocated slot.
	/// @param ptr Pointer returned by Alloc/AllocTyped.
	public void Free(void* ptr) mut
	{
		if (ptr == null)
			return;

		// Handle zero-sized types
		if (mObjectSize == 0)
			return;

		Runtime.Assert(mAllocCount > 0, "Free called more times than Alloc");

		int slot = GetSlotIndex((T*)ptr);
		Runtime.Assert(slot >= 0, "Invalid pointer passed to Free");
		Runtime.Assert(!mFreeBits.GetBit(slot), "Double free detected");

		// Mark slot as free
		mFreeBits.SetBit(slot);
		mAllocCount--;
	}

	/// @brief Returns the logical slot index backing a pointer previously returned by Alloc.
	/// @returns Slot index, or <c>-1</c> if the pointer does not belong to this allocator.
	public int GetSlotIndex(T* ptr) mut
	{
		if (ptr == null)
			return -1;

		if (mObjectSize == 0)
			return -1;

		int currentSlot = 0;
		Slab* slab = mSlabs;

		// Walk slabs in reverse order (newest first) but search oldest-to-newest
		List<Slab*> slabList = scope .();
		while (slab != null)
		{
			slabList.Add(slab);
			slab = slab.next;
		}

		for (int i = slabList.Count - 1; i >= 0; i--)
		{
			slab = slabList[i];
			uint8* slabStart = (uint8*)slab.memory;
			uint8* slabEnd = slabStart + (mObjectSize * slab.capacity);

			if (ptr >= slabStart && ptr < slabEnd)
			{
				int offsetInSlab = ((uint8*)ptr - slabStart) / mObjectSize;
				return currentSlot + offsetInSlab;
			}

			currentSlot += slab.capacity;
		}

		return -1;
	}
}