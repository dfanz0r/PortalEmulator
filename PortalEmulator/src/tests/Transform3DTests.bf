using System;
using Sizzle.Core;
using Sizzle.Entities;
using Sizzle.Math;
using Sizzle.Components;

namespace Sizzle.Tests;

static class Transform3DTests
{
	[Test]
	public static void Transform3D_DefaultsToIdentity()
	{
		GameEntity entity = new GameEntity(4);
		Transform3D t;
		entity.TryCreateComponent<Transform3D>(out t);

		Console.WriteLine($"Pos: {t.Position}, Rot: {t.Rotation}, Scale: {t.Scale}");
		Test.Assert(t.Position == Vector3.Zero);
		Test.Assert(t.Rotation == Quaternion.Identity);
		Test.Assert(t.Scale == Vector3.One);

		delete entity;
	}

	[Test]
	public static void Transform3D_SettersUpdateValues()
	{
		GameEntity entity = new GameEntity(4);
		Transform3D t;
		entity.TryCreateComponent<Transform3D>(out t);

		Console.WriteLine($"Pos: {t.Position}, Rot: {t.Rotation}, Scale: {t.Scale}");
		t.Position = .(1, 2, 3);
		Test.Assert(t.Position == .(1, 2, 3));

		t.Scale = .(2, 2, 2);
		Test.Assert(t.Scale == .(2, 2, 2));

		Quaternion q = Quaternion.FromEulerRadians(.(0, 1, 0));
		t.Rotation = q;
		Test.Assert(t.Rotation == q);

		delete entity;
	}

	[Test]
	public static void Transform3D_ParentingProperty()
	{
		var graph = EntityGraph.GetOrCreate(4);

		GameEntity parentEntity = new GameEntity(4);
		Transform3D parent;
		parentEntity.TryCreateComponent<Transform3D>(out parent);
		graph.TryRegisterEntity(parentEntity);

		GameEntity childEntity = new GameEntity(4);
		Transform3D child;
		childEntity.TryCreateComponent<Transform3D>(out child);
		graph.TryRegisterEntity(childEntity);

		child.Parent = parent;
		Test.Assert(child.Parent == parent);

		Transform3D p;
		graph.TryGetParentTransform(childEntity.EntityId, out p);
		Test.Assert(p == parent);

		child.Parent = null;
		Test.Assert(child.Parent == null);

		bool hasParent = graph.TryGetParentTransform(childEntity.EntityId, out p);
		Test.Assert(!hasParent);

		delete parentEntity;
		delete childEntity;
	}

	[Test]
	public static void Transform3D_Hierarchy_Translation()
	{
		var graph = EntityGraph.GetOrCreate(5); // Use a different graph ID to avoid potential conflicts

		GameEntity parentEntity = new GameEntity(5);
		Transform3D parent;
		parentEntity.TryCreateComponent<Transform3D>(out parent);
		graph.TryRegisterEntity(parentEntity);

		GameEntity childEntity = new GameEntity(5);
		Transform3D child;
		childEntity.TryCreateComponent<Transform3D>(out child);
		graph.TryRegisterEntity(childEntity);

		child.Parent = parent;

		parent.Position = .(10, 0, 0);
		child.Position = .(5, 0, 0);

		graph.UpdateTransforms();

		Matrix4x4 worldMatrix;
		bool success = graph.TryGetWorldMatrix(childEntity.EntityId, out worldMatrix);
		Test.Assert(success);

		// Child local (5,0,0) + Parent (10,0,0) = World (15,0,0)
		Vector3 worldPos = worldMatrix.ExtractPosition();
		Test.Assert(worldPos == .(15, 0, 0));

		delete parentEntity;
		delete childEntity;
	}

	[Test]
	public static void Transform3D_Hierarchy_Scaling()
	{
		var graph = EntityGraph.GetOrCreate(6);

		GameEntity parentEntity = new GameEntity(6);
		Transform3D parent;
		parentEntity.TryCreateComponent<Transform3D>(out parent);
		graph.TryRegisterEntity(parentEntity);

		GameEntity childEntity = new GameEntity(6);
		Transform3D child;
		childEntity.TryCreateComponent<Transform3D>(out child);
		graph.TryRegisterEntity(childEntity);

		child.Parent = parent;

		// Parent scale 2
		parent.Scale = .(2, 2, 2);
		// Child position 1 unit away on X
		child.Position = .(1, 0, 0);

		graph.UpdateTransforms();

		Matrix4x4 worldMatrix;
		bool success = graph.TryGetWorldMatrix(childEntity.EntityId, out worldMatrix);
		Test.Assert(success);

		// Child local (1,0,0) * Parent Scale (2) = World (2,0,0)
		Vector3 worldPos = worldMatrix.ExtractPosition();
		Test.Assert(worldPos == .(2, 0, 0));

		delete parentEntity;
		delete childEntity;
	}

	[Test]
	public static void Transform3D_Hierarchy_Rotation()
	{
		var graph = EntityGraph.GetOrCreate(7);

		GameEntity parentEntity = new GameEntity(7);
		Transform3D parent;
		parentEntity.TryCreateComponent<Transform3D>(out parent);
		graph.TryRegisterEntity(parentEntity);

		GameEntity childEntity = new GameEntity(7);
		Transform3D child;
		childEntity.TryCreateComponent<Transform3D>(out child);
		graph.TryRegisterEntity(childEntity);

		child.Parent = parent;

		// Rotate parent 90 degrees around Y
		parent.Rotation = Quaternion.FromEulerRadians(.(0, (float)Math.PI_d / 2.0f, 0));
		// Child at (1, 0, 0)
		child.Position = .(1, 0, 0);

		graph.UpdateTransforms();

		Matrix4x4 worldMatrix;
		bool success = graph.TryGetWorldMatrix(childEntity.EntityId, out worldMatrix);
		Test.Assert(success);

		// (1,0,0) rotated 90 deg around Y becomes (0, 0, -1) (assuming right handed, or similar)
		// Let's check the actual math.
		// If Z is forward, X is right. 90 deg Y rotation: X -> -Z?
		// Let's use approximate comparison for floats
		Vector3 worldPos = worldMatrix.ExtractPosition();

		// Expected: close to (0, 0, -1)
		Test.Assert(Math.Abs(worldPos.x) < 0.0001f);
		Test.Assert(Math.Abs(worldPos.y) < 0.0001f);
		Test.Assert(Math.Abs(worldPos.z - (-1.0f)) < 0.0001f);

		delete parentEntity;
		delete childEntity;
	}
}
