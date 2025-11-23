using System;
using System.Reflection;
using System.Collections;

namespace Sizzle.Entities;

/// @brief Component lifecycle interface for attaching behaviors to GameEntity instances.
/// @remarks All components must provide a unique compile-time type ID via GetTypeId().
/// Only one component of each type can exist per entity.
public interface IGameComponent
{

	/// @brief Called once when the component is first initialized after creation.
	void OnStart();

	/// @brief Called when the component becomes active on its entity.
	void OnEnable();

	/// @brief Called when the component becomes inactive on its entity.
	void OnDisable();

	/// @brief The unique runtime ID of the entity this component is attached to.
	/// @remarks Zero indicates the component is not attached to any entity.
	uint32 EntityId { get; internal set; }

	EntityID GetEntityId();

	/// @brief Returns the compile-time unique type identifier for this component type.
	/// @remarks Used internally by GameEntity for slot assignment and lookup.
	internal static int8 InternalTypeId { [Inline] get; }

	/// @brief Allows components to influence ordering when the engine iterates over them.
	/// @returns Integer priority where higher values execute later; defaults to zero.
	public static int32 ExecutionPriority { get => 0; } // default execution priority
}
/// @brief Specialized component interface for systems that require per-frame or fixed-step updates.
/// @remarks The engine keeps a dedicated registry of these types for fast iteration.
public interface IUpdatableComponent : IGameComponent
{
	/// @brief Called every frame to update the component's state.
	void OnUpdate();

	/// @brief Called at fixed time intervals for physics and time-sensitive updates.
	void OnFixedUpdate();
}

/// @brief Static container for all generated raw component IDs for the Entity system
public static struct InternalComponentData
{
	/// @brief Tests whether a type declares a specific attribute instance.
	/// @param inType Type to inspect.
	/// @param searchAttrType Attribute type to look for.
	/// @returns True when the attribute is present on the given type declaration.
	private static bool HasCustomAttribute(Type inType, Type searchAttrType)
	{
		if (!searchAttrType.IsSubtypeOf(typeof(Attribute)))
		{
			return false;
		}
		int32 attrIdx = -1;
		Type attrType = null;
		repeat
		{
			attrType = Type.[Friend]Comptime_Type_GetCustomAttributeType((int32)inType.TypeId, ++attrIdx);
			if (attrType == searchAttrType)
				return true;
		}
		while (attrType != null);
		return false;
	}

	[Comptime, OnCompile(.TypeInit)]
	/// @brief Discovers all registered component types and emits compile-time IDs sorted by priority.
	/// @remarks Called at compile-time to ensure every component receives a stable unique index.
	public static void OnCompile()
	{
		let names = new String(128);
		List<(String name, int priority)> types = scope .();
		for (var typeDecl in Type.TypeDeclarations)
		{
			for (let attr in typeDecl.GetCustomAttributes())
			{
				let typeVal = attr.VariantType;
				if (typeVal.IsSubtypeOf(typeof(RegisterComponentAttribute)) && HasCustomAttribute(typeDecl.ResolvedType, typeVal))
				{
					int priority = 0;
					if (typeVal is SpecializedGenericType)
					{
						var typeValGeneric = (SpecializedGenericType)typeVal;
						var arg = typeValGeneric.GetGenericArg(0);
						var value = scope:: $"{arg}";
						var startIndex = value.IndexOf(' ');
						var value2 = int64.Parse(value.Substring(startIndex + 1));

						if (value2 case .Ok(int val))
						{
							priority = value2;
						}
					}

					var value = scope:: String();
					typeDecl.GetName(value);
					types.Add((value, priority));
				}
			}
		}
		// Sort the component id's by the execution priority
		types.Sort((lhs, rhs) => lhs.priority <=> rhs.priority);
		int currIdx = 0;
		for (var type in types)
			names.AppendF($"public const int8 {type.name} = {currIdx++}; \n");
		Compiler.EmitTypeBody(typeof(Self), names);
	}
}

[AttributeUsage(.Class)]
struct DontGenerateEntityIdAttribute : Attribute
{
}

/// @brief Attribute that registers a component type and injects boilerplate IDs during compilation.
[AttributeUsage(.Class)]
struct RegisterComponentAttribute : Attribute, IOnTypeInit
{
	[Comptime]
	/// @brief Emits InternalTypeId and EntityId properties for annotated component types.
	/// @param type Component type being initialized.
	/// @param prev Previous attribute instance, if any.
	public void OnTypeInit(Type type, Self* prev)
	{
		let newName = scope String(128);
		type.GetName(newName);
		Compiler.EmitTypeBody(type, scope $"public static int8 InternalTypeId => InternalComponentData.{newName};\n");

		bool hasDontGenerate = false;
		for (let attr in type.GetCustomAttributes())
			if (attr.VariantType == typeof(DontGenerateEntityIdAttribute))
				hasDontGenerate = true;

		if (!hasDontGenerate)
		{
			Compiler.EmitTypeBody(type, scope $"public uint32 EntityId \{ [Inline] get; [Inline] set; \}\n");
			Compiler.EmitTypeBody(type, scope $"[Inline] public Sizzle.Entities.EntityID GetEntityId() => Sizzle.Entities.GameEntity.GetEntityId(EntityId);\n");
		}
	}
}


[AttributeUsage(.Class)]
/// @brief Attribute variant that additionally records an explicit execution priority.
struct RegisterComponentPriorityAttribute<T> : RegisterComponentAttribute, IOnTypeInit where T : const int
{
	[Comptime]
	/// @brief Emits InternalTypeId, EntityId, and InternalPriority members for prioritized components.
	/// @param type Component type being initialized.
	/// @param prev Previous attribute instance, if any.
	public void OnTypeInit(Type type, Self* prev)
	{
		let newName = scope String(128);
		type.GetName(newName);
		Compiler.EmitTypeBody(type, scope $"public static int8 InternalTypeId => InternalComponentData.{newName};\n");

		bool hasDontGenerate = false;
		for (let attr in type.GetCustomAttributes())
			if (attr.VariantType == typeof(DontGenerateEntityIdAttribute))
				hasDontGenerate = true;

		if (!hasDontGenerate)
		{
			Compiler.EmitTypeBody(type, scope $"public uint32 EntityId \{ [Inline] get; [Inline] set; \}\n");
			Compiler.EmitTypeBody(type, scope $"[Inline] public Sizzle.Entities.EntityID GetEntityId() => Sizzle.Entities.GameEntity.GetEntityId(EntityId);\n");
		}

		Compiler.EmitTypeBody(type, scope $"[Inline] public static int32 InternalPriority => {T};\n");
	}
}