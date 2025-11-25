using System;
using System.Collections;
using Sizzle.Math;

namespace Sizzle.Rendering;

static class MeshUtils
{
	public static void CalculateNormals(List<Vertex> vertices, List<uint32> indices, bool flatShading)
	{
		if (flatShading)
		{
			// Rebuild mesh for flat shading (unique vertices per face)
			List<Vertex> newVertices = new List<Vertex>();
			List<uint32> newIndices = new List<uint32>();

			for (int i = 0; i < indices.Count; i += 3)
			{
				uint32 i0 = indices[i];
				uint32 i1 = indices[i + 1];
				uint32 i2 = indices[i + 2];

				Vertex v0 = vertices[(int)i0];
				Vertex v1 = vertices[(int)i1];
				Vertex v2 = vertices[(int)i2];

				Vector3 edge1 = v1.Position - v0.Position;
				Vector3 edge2 = v2.Position - v0.Position;
				Vector3 normal = edge1.CrossProduct(edge2).Normalized();

				v0.Normal = normal;
				v1.Normal = normal;
				v2.Normal = normal;

				newVertices.Add(v0);
				newVertices.Add(v1);
				newVertices.Add(v2);

				newIndices.Add((uint32)(newVertices.Count - 3));
				newIndices.Add((uint32)(newVertices.Count - 2));
				newIndices.Add((uint32)(newVertices.Count - 1));
			}

			vertices.Clear();
			vertices.AddRange(newVertices);
			indices.Clear();
			indices.AddRange(newIndices);
			
			delete newVertices;
			delete newIndices;
		}
		else
		{
			// Smooth shading
			for (int i = 0; i < vertices.Count; i++)
				vertices[i].Normal = .Zero;

			for (int i = 0; i < indices.Count; i += 3)
			{
				uint32 i0 = indices[i];
				uint32 i1 = indices[i + 1];
				uint32 i2 = indices[i + 2];

				Vector3 p0 = vertices[(int)i0].Position;
				Vector3 p1 = vertices[(int)i1].Position;
				Vector3 p2 = vertices[(int)i2].Position;

				Vector3 edge1 = p1 - p0;
				Vector3 edge2 = p2 - p0;
				Vector3 normal = edge1.CrossProduct(edge2).Normalized();

				vertices[(int)i0].Normal += normal;
				vertices[(int)i1].Normal += normal;
				vertices[(int)i2].Normal += normal;
			}

			for (int i = 0; i < vertices.Count; i++)
				vertices[i].Normal = vertices[i].Normal.Normalized();
		}
	}
}
