using Sizzle.Math;
using System;

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