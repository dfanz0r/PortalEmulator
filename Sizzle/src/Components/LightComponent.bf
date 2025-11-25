using System;
using Sizzle.Math;
using Sizzle.Entities;

namespace Sizzle.Components;

public enum LightType : int32
{
	Directional = 0,
	Point = 1,
	Spot = 2
}

[RegisterComponent]
public class LightComponent : IGameComponent
{
	public LightType Type = .Directional;
	public Vector4 Color = .(1, 1, 1, 1);
	public float Intensity = 1.0f;
	public float Range = 10.0f;
	public float InnerCone = 0.9f;
	public float OuterCone = 0.8f;

	public this() { }
	public ~this() { }

	public void OnStart() { }
	public void OnEnable() { }
	public void OnDisable() { }
}
