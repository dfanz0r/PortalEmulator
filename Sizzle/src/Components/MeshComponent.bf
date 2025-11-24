using System;
using Sizzle.Rendering;
using Sizzle.Rendering.GPU;
using Sizzle.Entities;

namespace Sizzle.Components;

[RegisterComponent]
public class MeshComponent : IGameComponent
{
	public Mesh Mesh;
	public Material Material;

	public this()
	{
	}

	public ~this()
	{
	}

	public void OnStart() { }
	public void OnEnable() { }
	public void OnDisable() { }
}
