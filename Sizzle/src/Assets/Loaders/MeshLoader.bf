using System;
using System.Collections;
using Sizzle.Rendering;
using Sizzle.Rendering.GPU;
using Sizzle.Core;
using Assimp;
using Sizzle.Math;

namespace Sizzle.Assets.Loaders;

class MeshLoader : IAssetLoader
{
	public Result<Object> Load(String path, RenderDevice device)
	{
		String fullPath = scope .();
		Utils.GetAssetPath(fullPath, path);

		uint32 flags = (uint32)(
			Assimp.aiPostProcessSteps.Triangulate |
			Assimp.aiPostProcessSteps.GenSmoothNormals |
			Assimp.aiPostProcessSteps.FlipUVs |
			Assimp.aiPostProcessSteps.JoinIdenticalVertices
		);

		Assimp.aiScene* scene = Assimp.aiImportFile(fullPath, flags);
		if (scene == null || (scene.mFlags & (uint32)Assimp.aiSceneFlags.INCOMPLETE) != 0 || scene.mRootNode == null)
		{
			return .Err;
		}

		// For now, just take the first mesh
		if (scene.mNumMeshes > 0)
		{
			Assimp.aiMesh* aiMesh = scene.mMeshes[0];
			Mesh mesh = new Mesh();
			
			List<Vertex> vertices = scope .();
			List<uint32> indices = scope .();

			for (uint32 i = 0; i < aiMesh.mNumVertices; i++)
			{
				Vector3 pos = .(aiMesh.mVertices[i].x, aiMesh.mVertices[i].y, aiMesh.mVertices[i].z);
				Vector4 color = .(1, 1, 1, 1); // Default white
				Vector3 normal = .(0, 1, 0);

				if (aiMesh.mColors[0] != null)
				{
					color = .(aiMesh.mColors[0][i].r, aiMesh.mColors[0][i].g, aiMesh.mColors[0][i].b, aiMesh.mColors[0][i].a);
				}

				if (aiMesh.mNormals != null)
				{
					normal = .(aiMesh.mNormals[i].x, aiMesh.mNormals[i].y, aiMesh.mNormals[i].z);
				}
				
				// Console.WriteLine($"Vertex {i}: {pos.x}, {pos.y}, {pos.z}");
				vertices.Add(Vertex(pos, color, normal));
			}

			for (uint32 i = 0; i < aiMesh.mNumFaces; i++)
			{
				Assimp.aiFace face = aiMesh.mFaces[i];
				// Console.Write($"Face {i}: ");
				for (uint32 j = 0; j < face.mNumIndices; j++)
				{
					// Console.Write($"{face.mIndices[j]} ");
					indices.Add((uint32)face.mIndices[j]);
				}
				// Console.WriteLine();
			}

			Vertex[] vertArray = new Vertex[vertices.Count];
			vertices.CopyTo(vertArray);
			mesh.SetVertices(vertArray);
			delete vertArray;

			uint32[] idxArray = new uint32[indices.Count];
			indices.CopyTo(idxArray);
			mesh.SetIndices(idxArray);
			delete idxArray;

			mesh.Upload(device);
			
			Assimp.aiReleaseImport(scene);
			return .Ok(mesh);
		}

		Assimp.aiReleaseImport(scene);
		return .Err;
	}

	public void Free(Object asset)
	{
		let mesh = (Mesh)asset;
		delete mesh;
	}
}
