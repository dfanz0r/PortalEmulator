using System;
using Sizzle.Math;

namespace Sizzle.Rendering;

[CRepr]
public struct Vertex
{
	public Vector3 Position;
	public Vector4 Color;

	public this(Vector3 pos, Vector4 col)
	{
		Position = pos;
		Color = col;
	}
}
