using System;
using Sizzle.Entities;
using Sizzle.Math;
namespace PortalEmulator.Sizzle.Entities;

// Always ensure that Transform has the highest priority
[RegisterComponentPriority<-10000000>]
class Transform3D : IGameComponent
{
	public Vector3 Position = Vector3.Zero;
	public Quaternion Rotation = Quaternion.Identity;
	public Vector3 Scale = Vector3.One;

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