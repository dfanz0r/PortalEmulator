using System;
using Sizzle.Core;
using Sizzle.Entities;
using Sizzle.Math;
using Sizzle.Components;

using internal Sizzle.Entities;
namespace Sizzle.Tests;

static class EntityGraphTests
{
	[Test]
	public static void EntityGraph_AllocateAndFreeSlots()
	{
		var graph = EntityGraph.GetOrCreate(1); // Use a non-default graph for testing

		int32 slot1 = graph.AllocateSlot();
		int32 slot2 = graph.AllocateSlot();

		Test.Assert(slot1 != slot2);

		graph.FreeSlot(slot1);

		int32 slot3 = graph.AllocateSlot();
		// The allocator might reuse slot1, but it's not strictly guaranteed by the interface contract to be immediate LIFO,
		// but usually bitfield allocators do. Let's just assert it's a valid slot.
		Test.Assert(slot3 >= 0);

		graph.FreeSlot(slot2);
		graph.FreeSlot(slot3);
	}

	[Test]
	public static void EntityGraph_SetParent_EstablishesHierarchy()
	{
		var graph = EntityGraph.GetOrCreate(2);

		// Create two entities
		GameEntity parentEntity = new GameEntity(2);
		Transform3D parentTrans;
		parentEntity.TryCreateComponent<Transform3D>(out parentTrans);
		graph.TryRegisterEntity(parentEntity);

		GameEntity childEntity = new GameEntity(2);
		Transform3D childTrans;
		childEntity.TryCreateComponent<Transform3D>(out childTrans);
		graph.TryRegisterEntity(childEntity);

		// Set parent
		graph.SetParent(childEntity.EntityId, parentTrans);

		// Verify
		Transform3D retrievedParent;
		graph.TryGetParentTransform(childEntity.EntityId, out retrievedParent);
		Test.Assert(retrievedParent == parentTrans);

		// Cleanup
		delete parentEntity;
		delete childEntity;
	}

	[Test]
	public static void EntityGraph_UpdateTransforms_CalculatesMatrices()
	{
		var graph = EntityGraph.GetOrCreate(3);

		GameEntity entity = new GameEntity(3);
		Transform3D trans;
		entity.TryCreateComponent<Transform3D>(out trans);
		graph.TryRegisterEntity(entity);

		trans.Position = .(10, 20, 30);

		// Should be dirty now
		graph.UpdateTransforms();

		Matrix4x4 worldMatrix;
		graph.TryGetWorldMatrix(entity.EntityId, out worldMatrix);
		Vector3<float> pos = worldMatrix.ExtractPosition();

		Test.Assert(Math.Abs(pos.x - 10) < 0.001f);
		Test.Assert(Math.Abs(pos.y - 20) < 0.001f);
		Test.Assert(Math.Abs(pos.z - 30) < 0.001f);

		GameEntity childEntity = new GameEntity(3);
		Transform3D childTrans;
		childEntity.TryCreateComponent<Transform3D>(out childTrans);
		graph.TryRegisterEntity(childEntity);

		childTrans.Position = .(1, 0, 0);
		graph.SetParent(childEntity.EntityId, trans);

		graph.UpdateTransforms();

		Matrix4x4 childWorldMatrix;
		graph.TryGetWorldMatrix(childEntity.EntityId, out childWorldMatrix);
		Vector3<float> childPos = childWorldMatrix.ExtractPosition();

		// Parent is at (10, 20, 30), child is at (1, 0, 0) local.
		// World should be (11, 20, 30).
		Test.Assert(Math.Abs(childPos.x - 11) < 0.001f);
		Test.Assert(Math.Abs(childPos.y - 20) < 0.001f);
		Test.Assert(Math.Abs(childPos.z - 30) < 0.001f);

		delete entity;
		delete childEntity;
	}
}
