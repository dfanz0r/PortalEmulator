using System;
using Benchmarks.Framework;
using Sizzle.Entities;
using Sizzle.Math;
using System.Collections;
using Sizzle.Components;

namespace Benchmarks.Benchmarks;

[RegisterComponent]
class TestComponent : IGameComponent
{
	public int32 Value;

	public void OnStart() { }
	public void OnEnable() { }
	public void OnDisable() { }
}

static class RealEntityBenchmarks
{
	private static List<GameEntity> mEntities;
	private static List<GameEntity> mTransformEntities;
	public static int64 sAccumulator = 0;
	private static EntityGraph entityGraph;

	public static void Setup()
	{
		ComponentSystem.Setup();
		EntityGraph.Setup();

		mEntities = new .();

		for (int i = 0; i < 1000; i++)
		{
			let entity = new GameEntity();

			// Set some random-ish bits (Sparse)
			// Match the pattern in EntityBenchmarks for fair comparison
			// "if ((i + j) % 10 == 0)" - but here we are iterating entities, not components per entity in the same way.
			// In EntityBenchmarks, we had 1000 entities, each with 256 potential bits.
			// Here GameEntity has MaxComponents = 255.
			
			// To match "Entity_SparseMap_Check", we need to check a specific component type.
			// In EntityBenchmarks: "if (e.ActiveSlots.GetBit(5))"
			// So we need to ensure that for some entities, TestComponent (which will have some ID) is present.
			
			// Let's just add the component to every 10th entity to match the sparsity roughly?
			// Actually, EntityBenchmarks did:
			// for (int j = 0; j < 256; j++) if ((i + j) % 10 == 0) ...
			// And checked bit 5.
			// So bit 5 is set if (i + 5) % 10 == 0.

			if ((i + TestComponent.InternalTypeId) % 10 == 0)
			{
				TestComponent comp;
				entity.TryCreateComponent(out comp);
				comp.Value = (int32)i;
			}

			mEntities.Add(entity);
		}

		BenchmarkRegistry.Register("RealEntity_Check", new => RealEntity_Check, 10000, 5, 15, "Entity_Check_Sparse");
		BenchmarkRegistry.Register("RealEntity_Iterate", new => RealEntity_Iterate, 10000, 5, 15, "Entity_Iterate_Sparse");
		BenchmarkRegistry.Register("RealEntity_GetComponent", new => RealEntity_GetComponent, 10000, 5, 15, "Entity_GetComponent");

		mTransformEntities = new .();
		entityGraph = EntityGraph.GetOrCreate(0);
		for (int i = 0; i < 100000; i++)
		{
			mTransformEntities.Add(entityGraph.CreateEntity());
		}
		BenchmarkRegistry.Register("RealEntity_TransformUpdate", new => RealEntity_TransformUpdate, 250, 5, 15, "Entity_Transform_Update");
	}

	public static void Teardown()
	{
		DeleteContainerAndItems!(mEntities);
		DeleteContainerAndItems!(mTransformEntities);
		ComponentSystem.Shutdown();
		EntityGraph.Shutdown();
	}

	public static void RealEntity_Check()
	{
		for (let e in mEntities)
		{
			if (e.HasComponentType<TestComponent>()) sAccumulator++;
		}
	}

	public static void RealEntity_Iterate()
	{
		for (let e in mEntities)
		{
			var enumerator = e.GetComponentEnumerator();
			while (enumerator.GetNext() case .Ok(let comp))
			{
				if (let testComp = comp as TestComponent)
				{
					sAccumulator += testComp.Value;
				}
			}
		}
	}

	public static void RealEntity_GetComponent()
	{
		for (let e in mEntities)
		{
			TestComponent comp;
			if (e.TryGetComponent(out comp))
			{
				sAccumulator += comp.Value;
			}
		}
	}

	public static void RealEntity_TransformUpdate()
	{
		for (let e in mTransformEntities)
		{
			if (e.TryGetComponent<Transform3D>(var t))
			{
				t.Position += .(0.001f, 0, 0);
				entityGraph.MarkDirty(e.EntityId);
			}
		}

		entityGraph.UpdateTransforms();
	}
}
