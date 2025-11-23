using System;
using Sizzle.Math;

namespace Sizzle.Entities;

[CRepr]
public struct TransformData
{
	public Quaternion Rotation;
	public Vector3 Position;
	public Vector3 Scale;

	public this(Quaternion rotation, Vector3 position, Vector3 scale)
	{
		Rotation = rotation;
		Position = position;
		Scale = scale;
	}

	public static TransformData Identity => .(Quaternion.Identity, Vector3.Zero, Vector3.One);
}

// Always ensure that Transform has the highest priority
[RegisterComponentPriority<-10000000>]
class Transform3D : IGameComponent
{
	public using TransformData mInternalState = .Identity;

	public this()
	{
	}

	public Transform3D Parent
	{
		[Inline]
		get
		{
			let entityId = GetEntityId();
			let graphId = EntityGraph.GetGraphId(entityId);
			Transform3D parent;
			if (EntityGraph.GetOrCreate(graphId).TryGetParentTransform(entityId, out parent))
				return parent;
			return null;
		}
		[Inline]
		set
		{
			let entityId = GetEntityId();
			let graphId = EntityGraph.GetGraphId(entityId);
			EntityGraph.GetOrCreate(graphId).SetParent(entityId, value);
		}
	}

	public void MarkDirty()
	{
		let entityId = GetEntityId();
		let graphId = EntityGraph.GetGraphId(entityId);
		EntityGraph.GetOrCreate(graphId).MarkDirty(entityId);
	}

	public void OnStart()
	{
	}

	public void OnEnable()
	{
	}

	public void OnDisable()
	{
	}
}