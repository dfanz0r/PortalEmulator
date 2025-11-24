using System;
using Sizzle.Entities;
using Sizzle.Math;
using Sizzle.Core;
using Sizzle.Components;

namespace PortalEmulator.Components;

[RegisterComponent]
class RotatingCubeComponent : IUpdatableComponent
{
	public Vector3 RotationAxis = .(0, 1, 0);

	public void OnStart() { }
	public void OnEnable() { }
	public void OnDisable() { }
	public void OnFixedUpdate() { }

	public void OnUpdate()
	{
		Transform3D trans;
		if (EntityGraph.GetOrCreate(EntityGraph.GetGraphId(GetEntityId())).TryGetComponent<Transform3D>(GetEntityId(), out trans))
		{
			trans.Rotation = Quaternion.FromEulerRadians(RotationAxis * (float)Time.TotalTime);
			trans.MarkDirty();
		}
	}
}
