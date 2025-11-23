using System;
using System.Threading;
using System.Collections;

using Sizzle.Core;

using internal Sizzle.Entities;
using internal Sizzle.Core;

namespace Sizzle.Entities;

/// @brief Describes how an entity is currently enabled or disabled.
/// @remarks Local disables originate from the entity itself, while parent disables propagate downward in a hierarchy.
enum EnableState : int8
{
	/// @brief Entity is enabled locally and by its parents.
	Enabled,
	/// @brief Entity is explicitly disabled via its own EnabledSelf flag.
	DisabledLocal = 1,
	/// @brief Entity remains disabled due to an ancestor in the hierarchy.
	DisabledFromParent = 2
}

// Entity ID holds both state about it's current EntityGraph and slot within the graph but it also holds the global unique id for it as well.
// In total using only the ID it allows us to precisely locate multiple aspects of where in the engine any given entity is located.
// As a whole the full uint64 EntityID is called the LocatorID.
// Additionally the bits in the LocatorID are partitioned in a way that we are not wasting any IDs of any one type.
// As such the total number of possible EntityGraphs * SlotsPerGraph = total global EntityIDs
//
// This imposes the following limits:
//    - 4096 possible active EntityGraphs
//    - 1,048,576 possible GameEntities per graph
//    - 4,294,967,296 total unique GameEntities within the engine
// The limits imposed are purposely larger than would typically be required but also are not insanely large and ensures
// that we have maximum flexibility about how Entities are grouped and structured depending on the use-cases required.
//
// Because the EntityID can change if an object is moved between EntityGraphs API users need to be careful about keeping
// any copies of the EntityID across any such move operations, internal engine code will manage this where required
// And maybe it's worth providing some utilities to help with this such as a callback for when ids are changed,
// but this can come later if ultimately required.
// If a persistent ID is required the GlobalId should be kept to look up the active EntityID struct,
// as these are Guaranteed to be globally unique during runtime however are potentially not unique across launches.
// EntityGraph 0 is reserved for global persistent Entities that always persist unless explicitly destroyed
[Union]
public struct EntityID
{
	public struct
	{
		[Bitfield(.Public, .Bits(12), "GraphId")]
		[Bitfield(.Public, .Bits(20), "GraphSlotId")]
		private uint32 Value;
		public uint32 GlobalID;
	};
	public uint64 LocatorID;
}

/// @brief Entity-component system container that manages up to 64 unique component types.
/// @remarks Components are stored in a slot-based system where slots persist even after removal,
/// allowing efficient re-addition of the same component type without reallocation.
class GameEntity
{
	/// @brief Maximum number of component types that can be attached to a single entity.
	const int MaxComponents = 255;

	/// @brief Maps component type IDs to their storage slots in the Components array.
	/// @remarks Once a slot is assigned for an object type they are not changed or moved.
	/// id 0 means unallocated. In order to map slot id's to the Component array it is slotId - 1
	private uint8[MaxComponents] SlotMapping = .();

	/// @brief BitfieldArray tracking which component type slots are currently actively within the component list
	private BitfieldArray ActiveSlots = .();

	/// @brief Dense array storing actual component instances, indexed via SlotMapping.
	/// @remarks Pre-allocates capacity for MaxComponents to minimize allocations.
	private List<IGameComponent> Components = new .(MaxComponents);

	/// @brief Unique runtime identifier for this entity, assigned at construction.
	/// @remarks Not persistent across application runs.
	private EntityID runtimeEntityId;

	public EntityID EntityId => runtimeEntityId;

	/// @brief Tracks the enabled state of this entity (local and inherited from parent).
	private EnableState enabledState;

	/// @brief Global counter used to generate unique entity IDs across all instances.
	private static uint32 globalEntityIdCursor = 0;
	private static Dictionary<uint32, GameEntity> sGlobalIdMap = new .() ~ delete _;

	public static bool TryGetEntityId(uint32 globalId, out EntityID entityId)
	{
		if (sGlobalIdMap == null)
		{
			entityId = default;
			return false;
		}
		var success = sGlobalIdMap.TryGetValue(globalId, var entity);
		entityId = entity.EntityId;
		return success;
	}

	public static EntityID GetEntityId(uint32 globalId)
	{
		if (sGlobalIdMap != null && sGlobalIdMap.TryGetValue(globalId, var entity))
		{
			var entityId = entity.EntityId;
			return entityId;
		}

		// If the map is null, we are likely shutting down, so return default to avoid crashing
		if (sGlobalIdMap == null)
			return default;

		Runtime.FatalError("Failed to resolve EntityID from GlobalID");
	}

	/// @brief Constructs a new entity with a unique runtime ID and empty component slots.
	public this(int32 graphId = 0)
	{
		runtimeEntityId.GraphId = (uint32)graphId;
		runtimeEntityId.GraphSlotId = 0; // 0 indicates unallocated/invalid slot
		runtimeEntityId.GlobalID = Interlocked.Increment(ref globalEntityIdCursor);
		if (sGlobalIdMap != null)
			sGlobalIdMap[runtimeEntityId.GlobalID] = this;
	}

	/// @brief Destroys the entity and deletes all attached component instances.
	public ~this()
	{
		if (sGlobalIdMap != null)
			sGlobalIdMap.Remove(runtimeEntityId.GlobalID);
		if (runtimeEntityId.GraphSlotId != 0)
		{
			// GraphSlotId is 1-based, so subtract 1 to get the actual slot index
			EntityGraph.SafeFreeSlot((int32)runtimeEntityId.GraphId, (int32)runtimeEntityId.GraphSlotId);
		}

		// Release all active components via the component registries
		if (!ComponentSystem.IsShutdown)
		{
			for (let componentId in ActiveSlots)
			{
				var slotId = (int)SlotMapping[componentId] - 1;

				if (slotId < 0) continue;

				ComponentSystem.FreeComponent((int8)componentId, Components[slotId]);
			}
		}
		ActiveSlots.Dispose();
		delete Components;
	}

	/// @brief Gets or sets whether this entity is locally enabled (ignoring parent state).
	/// @remarks When set to false, the entity and all its components are deactivated.
	/// This does not affect the DisabledFromParent flag.
	/// @returns True when the local enable flag is set; false otherwise.
	/// @param value New local enable flag. False disables the entity independent of parent state.
	public bool EnabledSelf
	{
		[Inline]
		get => !enabledState.HasFlag(EnableState.DisabledLocal);
		[Inline]
		set
		{
			// clear bit if value is true, set bit if value is false
			int8 mask = (int8)EnableState.DisabledLocal;
			enabledState = (EnableState)((int8)enabledState & ~mask | (value ? 0 : mask));
		}
	}

	/// @brief Gets whether this entity is fully enabled (both locally and from parent hierarchy).
	/// @remarks Returns true only if both EnabledSelf is true AND not disabled by a parent.
	/// @returns True when the entity is neither locally nor parent disabled.
	public bool Enabled
	{
		[Inline]
		get => enabledState == EnableState.Enabled;
	}

	public struct Enumerator
	{
		private List<IGameComponent> list;
		private int currentPosition = 0;

		internal this(List<IGameComponent> entityList)
		{
			list = entityList;
		}

		/// @brief Advances to the next non-null element in the collection.
		/// @returns Ok with the next non-null element, or Err if no more elements exist.
		public Result<IGameComponent> GetNext() mut
		{
			// Skip any null values in the array
			while (currentPosition < list.Count)
			{
				var element = list.Ptr[currentPosition++];
				if (element == null) continue;

				return .Ok(element);
			}

			return .Err;
		}
	}

	/// @brief Returns an iterator that skips over null component slots.
	/// @returns Enumerator for active (non-null) components only.
	public Enumerator GetComponentEnumerator()
	{
		return .(Components);
	}

	/// @brief Gets the internal array index for a component type.
	/// @returns Array index if the component type has a slot, otherwise undefined behavior.
	/// @remarks Does not check if the component is currently active; use HasComponentType first.
	[Inline]
	public int GetComponentIndex<T>() where T : IGameComponent, class, new
	{
		return SlotMapping[T.InternalTypeId] - 1;
	}

	/// @brief Tests whether a component of the specified type is currently attached and active.
	/// @returns True if the component exists and has not been removed.
	[Inline]
	public bool HasComponentType<T>() where T : IGameComponent, class, new
	{
		var typeId =  T.InternalTypeId;
		return ActiveSlots.GetBit(typeId) && SlotMapping[typeId] > 0;
	}

	/// @brief Internal method to attach or reactivate a component instance.
	/// @param instance Component to attach.
	/// @remarks Allocates a new slot if needed, otherwise reuses an existing slot.
	[Inline]
	private void InternalComponentSet<T>(T instance) where T : IGameComponent, class, new
	{
		if (instance == null)
			return;

		var typeId =  T.InternalTypeId;
		var slot = SlotMapping[typeId];

		// if slot is 0 a slot has not yet been allocated
		if (slot == 0)
		{
			if (Components.Count >= MaxComponents)
				Runtime.FatalError("GameEntity component capacity exceeded");

			SlotMapping[typeId] = (uint8)Components.Count + 1;
			Components.Add(instance);
		}
		else
		{
			// Reactivate previously removed component type
			Components[slot - 1] = instance;
		}
		ActiveSlots.SetBit(typeId);
		instance.EntityId = runtimeEntityId.GlobalID;
	}

	/// @brief Internal method to remove and delete a component, keeping its slot reserved.
	/// @remarks The slot is marked negative to indicate deletion but remains allocated for future reuse.
	[Inline]
	private void InternalComponentRemove<T>() where T : IGameComponent, class, new
	{
		var typeId = T.InternalTypeId;

		int slot = SlotMapping[typeId] - 1;
		ActiveSlots.ClearBit(typeId);

		ComponentSystem.FreeComponent(typeId, Components[slot]);
		Components[slot] = null;
	}


	/// @brief Creates and attaches a new component of the specified type.
	/// @param componentOut Receives the created component on success, null on failure.
	/// @returns True if the component was created; false if one already exists.
	public bool TryCreateComponent<T>(out T componentOut) where T : IGameComponent, class, new, delete
	{
		if (HasComponentType<T>())
		{
			componentOut = null;
			return false;
		}

		// Allocate the component from the shared registry slab allocator
		var registry = ComponentSystem.GetRegistry<T>();
		T instance = registry.Allocate();
		InternalComponentSet(instance);

		componentOut = instance;
		return componentOut != null;
	}

	/// @brief Retrieves a component of the specified type if it exists.
	/// @param componentOut Receives the component on success, null on failure.
	/// @returns True if the component was found.
	public bool TryGetComponent<T>(out T componentOut) where T : IGameComponent, class, new
	{
		if (HasComponentType<T>())
		{
			componentOut = (T)Components[GetComponentIndex<T>()];
			return true;
		}

		componentOut = null;
		return false;
	}

	/// @brief Removes and deletes a component of the specified type.
	/// @returns True if the component existed and was removed.
	public bool TryRemoveComponent<T>() where T : IGameComponent, class, new
	{
		if (HasComponentType<T>())
		{
			InternalComponentRemove<T>();
			return true;
		}
		return false;
	}

	/// @brief Removes and deletes a component of the specified type (type-inferred overload).
	/// @param component Parameter is used for type inference.
	/// @returns True if the component existed and was removed.
	public bool TryRemoveComponent<T>(T component) where T : IGameComponent, class, new
	{
		if (HasComponentType<T>())
		{
			InternalComponentRemove<T>();
			return true;
		}
		return false;
	}
}