using System;
using System.Collections;
using PortalEmulator.Sizzle.Core;

namespace Sizzle.Entities;

using internal Sizzle.Entities;

/// @brief Generic slab allocator optimized for fixed-size objects.
/// @details Allocates memory in contiguous slabs and tracks free slots via a bitfield for O(1) reuse.
struct SlabAllocator<T> : ITypedAllocator, IDisposable
{
	struct Slab
	{
		public void* memory;    // Aligned address used for allocations
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

	/// @brief Creates a slab allocator for objects of type <c>T</c>.
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
	/// @returns Pointer to the slot storage or <c>null</c> for zero-sized types.
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
	/// @brief Allocates space for one object of type <c>T</c>.
	public void* AllocTyped(Type type, int size, int align) mut
	{
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
	/// @param ptr Pointer returned by <c>Alloc</c>/<c>AllocTyped</c>.
	public void Free(void* ptr) mut
	{
		if (ptr == null)
			return;

		// Handle zero-sized types
		if (mObjectSize == 0)
			return;

		Runtime.Assert(mAllocCount > 0, "Free called more times than Alloc");

		// Find which slot this pointer corresponds to
		int slot = -1;
		int currentSlot = 0;
		Slab* slab = mSlabs;

		// Walk slabs in reverse order (newest first) but we need to search oldest first
		// So we'll build the order correctly
		List<Slab*> slabList = scope .();
		while (slab != null)
		{
			slabList.Add(slab);
			slab = slab.next;
		}

		// Now search in correct order (oldest to newest)
		for (int i = slabList.Count - 1; i >= 0; i--)
		{
			slab = slabList[i];
			uint8* slabStart = (uint8*)slab.memory;
			uint8* slabEnd = slabStart + (mObjectSize * slab.capacity);

			if (ptr >= slabStart && ptr < slabEnd)
			{
				int offsetInSlab = ((uint8*)ptr - slabStart) / mObjectSize;
				slot = currentSlot + offsetInSlab;
				break;
			}

			currentSlot += slab.capacity;
		}

		Runtime.Assert(slot >= 0, "Invalid pointer passed to Free");
		Runtime.Assert(!mFreeBits.GetBit(slot), "Double free detected");

		// Mark slot as free
		mFreeBits.SetBit(slot);
		mAllocCount--;
	}
}

/// @brief Dense component registry backed by the slab allocator for storage.
/// @details Tracks active slots via a bitfield so iteration touches only live components.
class ComponentRegistry<T> where T : class, new, delete
{
	private SlabAllocator<T> mAllocator ~ _.Dispose(); // Slab allocator for component memory
	private T* mComponents; // Dense array of all component slots
	private BitfieldArray mActiveBits; // Bitfield tracking active components
	private int mCapacity;
	private int mActiveCount;

	public int Count => mActiveCount;
	public int Capacity => mCapacity;

	const int INITIAL_CAPACITY = 256; // Start with one bitfield block

	/// @brief Creates a registry with the requested slab capacity.
	/// @param slabCapacity Number of component instances to store per slab.
	public this(int slabCapacity = 64)
	{
		mAllocator = .(slabCapacity);
		mCapacity = INITIAL_CAPACITY;
		mActiveCount = 0;

		// Allocate initial component array
		mComponents = (T*)Internal.Malloc(sizeof(T*) * mCapacity);
		Internal.MemSet(mComponents, 0, sizeof(T*) * mCapacity);

		// Initialize bitfield
		mActiveBits = .();
	}

	/// @brief Releases all active components and backing storage.
	public ~this()
	{
		// Free all active components
		for (int i in mActiveBits)
		{
			if (mComponents[i] != null)
			{
				delete:mAllocator mComponents[i];
			}
		}

		Internal.Free(mComponents);
		mActiveBits.Dispose();
	}

	/// @brief Expands the dense component array by one bitfield block (256 slots).
	private void GrowCapacity()
	{
		int newCapacity = mCapacity + 256; // Grow by one bitfield block

		// Reallocate component array
		T* newComponents = (T*)Internal.Malloc(sizeof(T*) * newCapacity);
		Internal.MemCpy(newComponents, mComponents, sizeof(T*) * mCapacity);
		Internal.MemSet((uint8*)newComponents + (sizeof(T*) * mCapacity), 0, sizeof(T*) * 256);
		Internal.Free(mComponents);
		mComponents = newComponents;

		mCapacity = newCapacity;
	}

	/// @brief Reserves and constructs a new component instance.
	/// @returns Reference to the newly allocated component.
	public T Allocate()
	{
		// Find free slot using bitfield's FindFirstClear
		int slot = mActiveBits.FindFirstClear();

		// Grow if needed
		if (slot < 0 || slot >= mCapacity)
		{
			slot = mCapacity;
			GrowCapacity();
		}

		// Allocate component using the slab allocator
		T instance = new:mAllocator T();
		mComponents[slot] = instance;
		mActiveBits.SetBit(slot);
		mActiveCount++;

		return instance;
	}

	/// @brief Destroys and frees a component instance if found.
	/// @param instance Pointer previously returned by <c>Allocate</c>.
	public void Free(T instance)
	{
		// Find component index using bitfield iteration
		for (int i in mActiveBits)
		{
			if (mComponents[i] == instance)
			{
				mActiveBits.ClearBit(i);
				mComponents[i] = null;
				mActiveCount--;
				delete:mAllocator instance;
				return;
			}
		}
	}

	/// @brief Enumerator that yields only the active components tracked by the registry.
	public struct Enumerator : IEnumerator<T>
	{
		private ComponentRegistry<T> mRegistry;
		private BitfieldArray.SetBitEnumerator mBitEnumerator;

		/// @brief Creates an enumerator bound to the provided registry.
		public this(ComponentRegistry<T> registry)
		{
			mRegistry = registry;
			mBitEnumerator = registry.mActiveBits.GetEnumerator();
		}

		/// @brief Advances to the next active component instance.
		public Result<T> GetNext() mut
		{
			switch (mBitEnumerator.GetNext())
			{
			case .Ok(let index):
				return .Ok(mRegistry.mComponents[index]);
			case .Err:
				return .Err;
			}
		}
	}

	/// @brief Enables <c>for</c>-loop iteration over active components.
	public Enumerator GetEnumerator()
	{
		return Enumerator(this);
	}
}

/// @brief Global component system keyed by compile-time internal component IDs.
static class ComponentSystem
{
	// Max 64 component types (matches GameEntity.MaxComponents)
	private const int MAX_COMPONENT_TYPES = 64;

	// Array of type-erased registries, indexed by component InternalTypeId
	private static Object[MAX_COMPONENT_TYPES] sRegistries = .() ~ Shutdown();
	private static bool sIsShutdown = false;

	/// @brief Retrieves (or lazily creates) the registry for component type <c>T</c>.
	public static ComponentRegistry<T> GetRegistry<T>() where T : class, IGameComponent, new, delete
	{
		if (sIsShutdown)
			 sIsShutdown = false;

		// Get component ID
		int8 typeId = T.InternalTypeId;

		Runtime.Assert(typeId >= 0 && typeId < MAX_COMPONENT_TYPES, "Invalid component type ID");

		if (sRegistries[typeId] == null)
		{
			sRegistries[typeId] = new ComponentRegistry<T>(64); // 64 components per slab
		}

		return (ComponentRegistry<T>)sRegistries[typeId];
	}

	/// @brief Disposes all registries and releases component memory.
	public static void Shutdown()
	{
		if (sIsShutdown)
			return;

		for (int i = 0; i < MAX_COMPONENT_TYPES; i++)
		{
			delete sRegistries[i];
			sRegistries[i] = null;
		}

		sIsShutdown = true;
	}
}