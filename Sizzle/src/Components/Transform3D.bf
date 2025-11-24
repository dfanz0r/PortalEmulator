using System;
using Sizzle.Math;
using Sizzle.Entities;

namespace Sizzle.Components;

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