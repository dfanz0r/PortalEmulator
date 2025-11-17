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

/// @brief Entity-component system container that manages up to 64 unique component types.
/// @remarks Components are stored in a slot-based system where slots persist even after removal,
/// allowing efficient re-addition of the same component type without reallocation.
class GameEntity
{
	/// @brief Maximum number of component types that can be attached to a single entity.
	const int MaxComponents = 64;

	/// @brief Bitmask tracking which component type slots have ever been allocated (up to 64 types).
	/// @remarks Each bit corresponds to a type ID. Set bits indicate the type has been allocated a slot.
	private uint64 Mask = 0;

	/// @brief Maps component type IDs to their storage slots in the Components array.
	/// @remarks -128 = never allocated, -127 to -1 = allocated but deleted, 1 to 127 = active component.
	/// When a component is deleted the slot ID is negated to mark it as deleted while preserving the slot assignment.
	private int8[MaxComponents] SlotMapping = .(?);

	/// @brief Dense array storing actual component instances, indexed via SlotMapping.
	/// @remarks Pre-allocates capacity for MaxComponents to minimize allocations.
	private List<IGameComponent> Components = new .(MaxComponents);

	/// @brief Unique runtime identifier for this entity, assigned at construction.
	/// @remarks Not persistent across application runs.
	private uint64 runtimeEntityId;

	/// @brief Tracks the enabled state of this entity (local and inherited from parent).
	private EnableState enabledState;

	/// @brief Global counter used to generate unique entity IDs across all instances.
	private static uint64 entityIdCursor = 0;

	/// @brief Sentinel value indicating a component type has never been allocated a slot.
	private const int8 SLOT_MISSING = -128;

	/// @brief Constructs a new entity with a unique runtime ID and empty component slots.
	public this()
	{
		SlotMapping.SetAll(SLOT_MISSING);
		runtimeEntityId = Interlocked.Increment(ref entityIdCursor);
	}

	/// @brief Destroys the entity and deletes all attached component instances.
	public ~this()
	{
		// Release all active components via the component registries
		for (int typeIndex = 1; typeIndex < MaxComponents; typeIndex++)
		{
			if (SlotMapping[typeIndex] > 0)
				RemoveComponentForTypeIndex(typeIndex);
		}

		while (Components.Count > 0)
			Components.PopBack();
		delete Components;
	}

	/// @brief Gets or sets whether this entity is locally enabled (ignoring parent state).
	/// @remarks When set to false, the entity and all its components are deactivated.
	/// This does not affect the DisabledFromParent flag.
	/// @returns True when the local enable flag is set; false otherwise.
	/// @param value New local enable flag. False disables the entity independent of parent state.
	public bool EnabledSelf
	{
		get => !enabledState.HasFlag(EnableState.DisabledLocal);
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
		get => enabledState == EnableState.Enabled;
	}

	/// @brief Returns an iterator that skips over null component slots.
	/// @returns Enumerator for active (non-null) components only.
	public NullSkipEnumerator<IGameComponent> GetComponentEnumerator()
	{
		return NullSkipEnumerator<IGameComponent>(Components);
	}

	/// @brief Gets the internal array index for a component type.
	/// @returns Array index if the component type has a slot, otherwise undefined behavior.
	/// @remarks Does not check if the component is currently active; use HasComponentType first.
	[Inline]
	public int GetComponentIndex<T>() where T : IGameComponent, class, new
	{
		return SlotMapping[T.InternalTypeId + 1]; // internal id's start at 0
	}

	/// @brief Tests whether a component of the specified type is currently attached and active.
	/// @returns True if the component exists and has not been removed.
	[Inline]
	public bool HasComponentType<T>() where T : IGameComponent, class, new
	{
		var typeId =  T.InternalTypeId + 1; // internal id's start at 0
		return (Mask & (1 << typeId)) != 0 && SlotMapping[typeId] > 0;
	}

	/// @brief Internal method to attach or reactivate a component instance.
	/// @param instance Component to attach.
	/// @remarks Allocates a new slot if needed, otherwise reuses an existing slot.
	[Inline]
	private void InternalComponentSet<T>(T instance) where T : IGameComponent, class, new
	{
		var slotIndex =  T.InternalTypeId + 1; // internal id's start at 0

		var slot = SlotMapping[slotIndex];
		if (slot == SLOT_MISSING)
		{
			// First time this type is added - allocate new slot
			Mask |= (1 << slotIndex);
			SlotMapping[slotIndex] = (int8)Components.Count;
			Components.Add(instance);
		}
		else
		{
			// Reactivate previously deleted slot
			slot = Math.Abs(slot);
			SlotMapping[slotIndex] = slot;
			Components[slot] = instance;
		}
		instance.EntityId = runtimeEntityId;
	}

	/// @brief Internal method to remove and delete a component, keeping its slot reserved.
	/// @remarks The slot is marked negative to indicate deletion but remains allocated for future reuse.
	[Inline]
	private void InternalComponentRemove<T>() where T : IGameComponent, class, new
	{
		var slotIndex =  T.InternalTypeId + 1; // internal id's start at 0
		RemoveComponentForTypeIndex(slotIndex);
	}

	/// @brief Removes the component backing the provided slot index and releases its storage appropriately.
	private void RemoveComponentForTypeIndex(int slotIndex)
	{
		int slot = SlotMapping[slotIndex];
		if (slot <= 0)
			return;

		var component = Components[slot];
		Components[slot] = null;
		SlotMapping[slotIndex] = (int8)(-slot);

		if (component == null)
			return;

		ComponentSystem.FreeComponent((int8)(slotIndex - 1), component);
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