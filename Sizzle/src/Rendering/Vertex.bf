using System;
using Sizzle.Math;

namespace Sizzle.Rendering;

[CRepr]
public struct Vertex
{
	public Vector3 Position;
	public Vector4 Color;
	public Vector3 Normal;

	public this(Vector3 pos, Vector4 col, Vector3 normal)
	{
		Position = pos;
		Color = col;
		Normal = normal;
	}
}
