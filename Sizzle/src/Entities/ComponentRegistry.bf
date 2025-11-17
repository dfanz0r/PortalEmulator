using PortalEmulator.Sizzle.Core;
using System.Collections;
using System;
namespace Sizzle.Entities;


using internal Sizzle.Entities;

interface IComponentRegistryUntyped
{
	void FreeUntyped(IGameComponent component);
}

/// @brief Dense component registry backed by the slab allocator for storage.
/// @details Tracks active slots via a bitfield so iteration touches only live components.
class ComponentRegistry<T> : IComponentRegistryUntyped where T : IGameComponent, class, new, delete
{
	// TODO - We should technically be able to use the SlabAllocator memory directly instead of storing a separate array of pointers
	// This however will require SlabAllocator to implement more features such as iteration over allocated slots.
	private SlabAllocator<T> mAllocator ~ _.Dispose(); // Slab allocator for component memory
	private List<T> mComponents = new .() ~ delete mComponents; // Dense array of all component slots
	private BitfieldArray mActiveBits; // Bitfield tracking active components
	private int mActiveCount;

	public int Count => mActiveCount;
	public int Capacity => mComponents.Count;

	const int BLOCK_SIZE = 256; // Start with one bitfield block

	/// @brief Creates a registry with the requested slab capacity.
	/// @param slabCapacity Number of component instances to store per slab.
	public this(int slabCapacity = 64)
	{
		mAllocator = .(slabCapacity);
		mActiveCount = 0;
		mComponents.Reserve(BLOCK_SIZE);
		for (int i = 0; i < BLOCK_SIZE; i++)
			mComponents.Add(null);

		// Initialize bitfield
		mActiveBits = .();
	}

	/// @brief Releases all active components and backing storage.
	public ~this()
	{
		// TODO - Investigate freeing the whole slab allocator at once.
		// Only issue with that is destructors? Maybe there is some optimization
		// internally where the allocator can more optimally 
		// Free all active components
		for (int i in mActiveBits)
		{
			if (mComponents[i] != null)
			{
				delete:mAllocator mComponents[i];
			}
		}

		mActiveBits.Dispose();
	}

	/// @brief Expands the dense component array by one bitfield block (256 slots).
	private void GrowCapacity()
	{
		mComponents.Reserve(mComponents.Capacity + BLOCK_SIZE);

		for (int i = 0; i < BLOCK_SIZE; i++)
			mComponents.Add(null);
	}

	/// @brief Reserves and constructs a new component instance.
	/// @returns Reference to the newly allocated component.
	public T Allocate()
	{
		// Find free slot using bitfield's FindFirstClear
		int slot = mActiveBits.FindFirstClear();

		// Grow if needed
		if (slot < 0 || slot >= mComponents.Count)
		{
			slot = mComponents.Count;
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

	/// @brief Releases a component instance without requiring its concrete type at the call-site.
	public void FreeUntyped(IGameComponent component)
	{
		Runtime.Assert(component is T, "Component type mismatch in FreeUntyped");
		Free((T)component);
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