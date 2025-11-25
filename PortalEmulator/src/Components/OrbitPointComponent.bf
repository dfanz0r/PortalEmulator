using System;
using Sizzle.Entities;
using Sizzle.Math;
using Sizzle.Core;
using Sizzle.Components;
using SDL3;

namespace PortalEmulator.Components;

[RegisterComponent]
class OrbitPointComponent : IUpdatableComponent
{
	public float StartAngle = 0.0f;
	public float Direction = 1.0f;

	public void OnStart()
	{
		let rng = scope Random((int)SDL_GetTicks() ^ (int)GetEntityId().GlobalID);
		StartAngle = (float)(rng.NextDouble() * Math.PI_d * 2);
		Direction = (rng.NextDouble() > 0.5) ? 1.0f : -1.0f;
	}

	public void OnEnable() { }
	public void OnDisable() { }
	public void OnFixedUpdate() { }

	public void OnUpdate()
	{
		Transform3D trans;
		if (EntityGraph.GetOrCreate(EntityGraph.GetGraphId(GetEntityId())).TryGetComponent<Transform3D>(GetEntityId(), out trans))
		{
			float time = (float)SDL_GetTicks() / 1000.0f;
			float angle = time * Direction + StartAngle;

			trans.Position.x += (float)Math.Sin(angle) * 0.1f;
			trans.Position.z += (float)Math.Cos(angle) * 0.1f;
			trans.MarkDirty();
		}
	}
}
