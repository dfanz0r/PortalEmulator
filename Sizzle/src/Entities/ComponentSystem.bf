using System;
using System.Collections;
using PortalEmulator.Sizzle.Core;

namespace Sizzle.Entities;

using internal Sizzle.Entities;

/// @brief Global component system keyed by compile-time internal component IDs.
static class ComponentSystem
{
	// Max 64 component types (matches GameEntity.MaxComponents)
	private const int MAX_COMPONENT_TYPES = 64;

	// Array of type-erased registries, indexed by component InternalTypeId
	private static IComponentRegistryUntyped[MAX_COMPONENT_TYPES] sRegistries = .() ~ Shutdown();
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

	/// @brief Releases a component previously allocated via the registry identified by <c>typeId</c>.
	public static void FreeComponent(int8 typeId, IGameComponent component)
	{
		if (component == null)
			return;

		Runtime.Assert(typeId >= 0 && typeId < MAX_COMPONENT_TYPES, "Invalid component type ID");
		Runtime.Assert(!sIsShutdown, "ComponentSystem has already been shut down");
		var registry = sRegistries[typeId];
		Runtime.Assert(registry != null, "Component registry not initialized");
		registry.FreeUntyped(component);
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