using System;
using Sizzle.Core;
using Sizzle.Entities;

namespace Sizzle.Tests;

struct SlabTestStruct
{
	public int value;
}

struct ZeroSizedStruct
{
}

[RegisterComponent]
class TestComponentA : IGameComponent
{
	public int Id;

	public void OnStart() { }
	public void OnEnable() { }
	public void OnDisable() { }
}

[RegisterComponent]
class TestComponentB : IGameComponent
{
	public void OnStart() { }
	public void OnEnable() { }
	public void OnDisable() { }
}

static class ComponentSystemTests
{
	[Test]
	public static void SlabAllocator_AllocAndFreeReusesSlots()
	{
		SlabAllocator<SlabTestStruct> allocator = .(2);
		defer allocator.Dispose();

		SlabTestStruct* first = (SlabTestStruct*)allocator.AllocTyped(typeof(SlabTestStruct), sizeof(SlabTestStruct), alignof(SlabTestStruct));
		SlabTestStruct* second = (SlabTestStruct*)allocator.AllocTyped(typeof(SlabTestStruct), sizeof(SlabTestStruct), alignof(SlabTestStruct));
		allocator.Free(second);
		SlabTestStruct* third = (SlabTestStruct*)allocator.AllocTyped(typeof(SlabTestStruct), sizeof(SlabTestStruct), alignof(SlabTestStruct));

		Test.Assert(first != null);
		Test.Assert(second != null);
		Test.Assert(third == second);
	}

	[Test]
	public static void SlabAllocator_HandlesZeroSizedTypes()
	{
		SlabAllocator<ZeroSizedStruct> allocator = .(1);
		defer allocator.Dispose();

		void* slot = allocator.AllocTyped(typeof(ZeroSizedStruct), sizeof(ZeroSizedStruct), alignof(ZeroSizedStruct));
		allocator.Free(slot);

		Test.Assert(slot == null);
	}

	[Test]
	public static void SlabAllocator_GrowsWhenCapacityExceeded()
	{
		SlabAllocator<SlabTestStruct> allocator = .(1);
		defer allocator.Dispose();

		SlabTestStruct* first = (SlabTestStruct*)allocator.AllocTyped(typeof(SlabTestStruct), sizeof(SlabTestStruct), alignof(SlabTestStruct));
		SlabTestStruct* second = (SlabTestStruct*)allocator.AllocTyped(typeof(SlabTestStruct), sizeof(SlabTestStruct), alignof(SlabTestStruct));

		Test.Assert(first != null && second != null);
		Test.Assert(first != second);
	}

	[Test]
	public static void ComponentRegistry_AllocateAndEnumerate()
	{
		ComponentRegistry<TestComponentA> registry = new .(2);
		defer delete registry;

		TestComponentA compA = registry.Allocate();
		compA.Id = 123;
		TestComponentA compB = registry.Allocate();
		compB.Id = 456;

		int found = 0;
		for (var component in registry)
		{
			if (component.Id == 123 || component.Id == 456)
				found++;
		}

		Test.Assert(registry.Count == 2);
		Test.Assert(found == 2);
	}

	[Test]
	public static void ComponentRegistry_FreeReusesSlots()
	{
		ComponentRegistry<TestComponentA> registry = new .(2);
		defer delete registry;

		TestComponentA first = registry.Allocate();
		TestComponentA second = registry.Allocate();
		Test.Assert(second != null);
		registry.Free(first);

		TestComponentA third = registry.Allocate();
		Test.Assert(registry.Count == 2);
		Test.Assert(third == first);
	}

	[Test]
	public static void ComponentRegistry_GrowsBeyondInitialCapacity()
	{
		ComponentRegistry<TestComponentA> registry = new .(4);
		defer delete registry;

		const int target = 260;
		for (int i = 0; i < target; i++)
		{
			registry.Allocate();
		}

		Test.Assert(registry.Count == target);
		Test.Assert(registry.Capacity >= 512);
	}

	[Test]
	public static void ComponentSystem_GetRegistryReturnsSingletonPerType()
	{
		var firstCall = ComponentSystem.GetRegistry<TestComponentA>();
		var secondCall = ComponentSystem.GetRegistry<TestComponentA>();
		var otherType = ComponentSystem.GetRegistry<TestComponentB>();

		Test.Assert((Object)firstCall == (Object)secondCall);
		Test.Assert((Object)firstCall != (Object)otherType);
	}
}
