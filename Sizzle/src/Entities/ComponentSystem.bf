using System;
using System.Collections;
using Sizzle.Core;

namespace Sizzle.Entities;

using internal Sizzle.Entities;

/// @brief Global component system keyed by compile-time internal component IDs.
static class ComponentSystem : ISystemInit
{
	// Max 64 component types (matches GameEntity.MaxComponents)
	private const int MAX_COMPONENT_TYPES = 64;

	// Array of type-erased registries, indexed by component InternalTypeId
	private static IComponentRegistryUntyped[MAX_COMPONENT_TYPES] sRegistries = .();
	private static bool sIsShutdown = false;

	public static void Setup()
	{
		sIsShutdown = false;
	}

	public struct RegistryEnumerator : IEnumerator<IComponentRegistryUntyped>
	{
		private int mIndex = 0;

		public Result<IComponentRegistryUntyped> GetNext() mut
		{
			while (mIndex < MAX_COMPONENT_TYPES)
			{
				var reg = sRegistries[mIndex++];
				if (reg != null)
					return .Ok(reg);
			}
			return .Err;
		}
	}

	public static RegistryEnumerator Registries => RegistryEnumerator();

	/// @brief Retrieves (or lazily creates) the registry for component type T.
	public static ComponentRegistry<T> GetRegistry<T>() where T : class, IGameComponent, new, delete
	{
		if (sIsShutdown)
			return null;

		// Get component ID
		int8 typeId = T.InternalTypeId;

		Runtime.Assert(typeId >= 0 && typeId < MAX_COMPONENT_TYPES, "Invalid component type ID");

		if (sRegistries[typeId] == null)
		{
			sRegistries[typeId] = new ComponentRegistry<T>(64); // 64 components per slab
		}

		return (ComponentRegistry<T>)sRegistries[typeId];
	}

	/// @brief Releases a component previously allocated via the registry identified by typeId.
	public static void FreeComponent(int8 typeId, IGameComponent component)
	{
		if (component == null || sIsShutdown)
			return;

		Runtime.Assert(typeId >= 0 && typeId < MAX_COMPONENT_TYPES, "Invalid component type ID");
		var registry = sRegistries[typeId];
		Runtime.Assert(registry != null, "Component registry not initialized");
		registry.FreeUntyped(component);
	}

	/// @brief Disposes all registries and releases component memory.
	public static void Shutdown()
	{
		if (sIsShutdown)
			return;

		sIsShutdown = true;

		for (int i = 0; i < MAX_COMPONENT_TYPES; i++)
		{
			if (sRegistries[i] != null)
			{
				delete sRegistries[i];
				sRegistries[i] = null;
			}
		}
	}

	public static bool IsShutdown => sIsShutdown;
}