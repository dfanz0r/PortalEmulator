using System;
using System.IO;
using System.Collections;
using System.Interop;
using Sizzle.Math;
using Sizzle.Core;
using Sizzle.Entities;
using Sizzle.Rendering;
using Sizzle.Rendering.GPU;
using Sizzle.Assets;
using SDL3;
using SDL3_shadercross;
using PortalEmulator.Components;
using Sizzle.Components;

namespace PortalEmulator.Systems;

static class GameSystem : ISystemInit
{
	private static Mesh mMesh;
	private static Mesh mTerrainMesh;
	private static Mesh mBuildingMesh;
	private static Mesh mSphereMesh;
	private static Material mMaterial;
	private static Material mTerrainMaterial;
	private static Material mBuildingMaterial;
	private static List<Material> mCubeMaterials = new .() ~ DeleteContainerAndItems!(_);
	private static List<Material> mLightMaterials = new .() ~ DeleteContainerAndItems!(_);
	private static GraphicsPipeline mPipeline;

	public static void Setup()
	{
		// Cube Vertices (8 vertices)
		List<Vertex> vertices = new List<Vertex>() { // Front
			Vertex(Vector3(-0.5f, -0.5f,  0.5f), Vector4(1.0f, 0.0f, 0.0f, 1.0f), .(0, 0, 1)), // 0
			Vertex(Vector3(0.5f, -0.5f,  0.5f), Vector4(0.0f, 1.0f, 0.0f, 1.0f), .(0, 0, 1)), // 1
			Vertex(Vector3(0.5f,  0.5f,  0.5f), Vector4(0.0f, 0.0f, 1.0f, 1.0f), .(0, 0, 1)), // 2
			Vertex(Vector3(-0.5f,  0.5f,  0.5f), Vector4(1.0f, 1.0f, 0.0f, 1.0f), .(0, 0, 1)), // 3
			// Back
			Vertex(Vector3(-0.5f, -0.5f, -0.5f), Vector4(1.0f, 0.0f, 1.0f, 1.0f), .(0, 0, -1)), // 4
			Vertex(Vector3(0.5f, -0.5f, -0.5f), Vector4(0.0f, 1.0f, 1.0f, 1.0f), .(0, 0, -1)), // 5
			Vertex(Vector3(0.5f,  0.5f, -0.5f), Vector4(1.0f, 1.0f, 1.0f, 1.0f), .(0, 0, -1)), // 6
			Vertex(Vector3(-0.5f,  0.5f, -0.5f), Vector4(0.0f, 0.0f, 0.0f, 1.0f), .(0, 0, -1)) // 7
		};
		defer delete vertices;

		// Cube Indices (36 indices)
		List<uint32> indices = new List<uint32>() { // Front
			0, 1, 2, 2, 3, 0, // Right
			1, 5, 6, 6, 2, 1, // Back
			7, 6, 5, 5, 4, 7, // Left
			4, 0, 3, 3, 7, 4, // Top
			3, 2, 6, 6, 7, 3, // Bottom
			4, 5, 1, 1, 0, 4
		};
		defer delete indices;

		MeshUtils.CalculateNormals(vertices, indices, true);

		// Create Shaders
		var vertShader = AssetManager.Load<GpuShader>("shaders/simple.vert.hlsl");
		var fragShader = AssetManager.Load<GpuShader>("shaders/simple.frag.hlsl");

		if (vertShader == null || fragShader == null) return;

		// Create Pipeline
		let builder = scope GraphicsPipelineBuilder();
		mPipeline = builder
			.SetShaders(vertShader, fragShader)
			.AddVertexBuffer(0, (uint32)sizeof(Vertex))
			.AddVertexAttribute(0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0) // Position
			.AddVertexAttribute(1, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, 12) // Color
			.AddVertexAttribute(2, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 28) // Normal
			.AddColorTarget(SDL_GetGPUSwapchainTextureFormat(Engine.Device.GetDeviceHandle(), Engine.Window.GetWindowHandle()))
			.SetDepthState(.SDL_GPU_TEXTUREFORMAT_D32_FLOAT)
			.SetMultisampleState(.SDL_GPU_SAMPLECOUNT_4)
			.SetPrimitiveType(.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST)
			.Build(Engine.Device);

		if (mPipeline == null)
		{
			Console.WriteLine("Failed to build pipeline.");
			return;
		}

		mMaterial = new Material(mPipeline);
		mMaterial.Albedo = .(1.0f, 1.0f, 1.0f);
		mMaterial.Roughness = 0.9f;
		mMaterial.Metallic = 0.0f;

		mTerrainMaterial = new Material(mPipeline);
		mTerrainMaterial.Albedo = .(0.5f, 0.4f, 0.3f); // Earthy brown
		mTerrainMaterial.Roughness = 0.95f; // Very rough
		mTerrainMaterial.Metallic = 0.0f;

		mBuildingMaterial = new Material(mPipeline);
		mBuildingMaterial.Albedo = .(0.7f, 0.7f, 0.75f); // Concrete grey
		mBuildingMaterial.Roughness = 0.8f;
		mBuildingMaterial.Metallic = 0.0f;

		// Create a palette of materials for cubes
		// Gold
		var gold = new Material(mPipeline);
		gold.Albedo = .(1.0f, 0.71f, 0.29f);
		gold.Metallic = 1.0f;
		gold.Roughness = 0.2f;
		mCubeMaterials.Add(gold);

		// Silver
		var silver = new Material(mPipeline);
		silver.Albedo = .(0.95f, 0.93f, 0.88f);
		silver.Metallic = 1.0f;
		silver.Roughness = 0.3f;
		mCubeMaterials.Add(silver);

		// Copper
		var copper = new Material(mPipeline);
		copper.Albedo = .(0.95f, 0.64f, 0.54f);
		copper.Metallic = 1.0f;
		copper.Roughness = 0.4f;
		mCubeMaterials.Add(copper);

		// Red Plastic
		var redPlastic = new Material(mPipeline);
		redPlastic.Albedo = .(1.0f, 0.1f, 0.1f);
		redPlastic.Metallic = 0.0f;
		redPlastic.Roughness = 0.1f;
		mCubeMaterials.Add(redPlastic);

		// Blue Rubber
		var blueRubber = new Material(mPipeline);
		blueRubber.Albedo = .(0.1f, 0.1f, 1.0f);
		blueRubber.Metallic = 0.0f;
		blueRubber.Roughness = 0.8f;
		mCubeMaterials.Add(blueRubber);

		// Debug Material
		var debugMaterial = new Material(mPipeline);
		debugMaterial.Albedo = .(0.5f, 0.5f, 0.5f);
		debugMaterial.Metallic = 0.0f;
		debugMaterial.Roughness = 0.5f;
		mCubeMaterials.Add(debugMaterial);

		mMesh = new Mesh();
		Vertex[] vertArray = new Vertex[vertices.Count];
		vertices.CopyTo(vertArray);
		mMesh.SetVertices(vertArray);
		delete vertArray;

		uint32[] idxArray = new uint32[indices.Count];
		indices.CopyTo(idxArray);
		mMesh.SetIndices(idxArray);
		delete idxArray;

		mMesh.Upload(Engine.Device);

		mSphereMesh = CreateSphere(0.5f, 16, 16);

		mTerrainMesh = AssetManager.Load<Mesh>("models/MP_Granite_ClubHouse_Portal_Terrain.glb");

		// --- Create Entities ---
		var graph = EntityGraph.GetOrCreate(0);

		// Create Building Entity
		if (mTerrainMesh != null)
		{
			var buildingEntity = graph.CreateEntity();
			MeshComponent meshComp;
			if (buildingEntity.TryCreateComponent<MeshComponent>(out meshComp))
			{
				meshComp.Material = mTerrainMaterial;
				meshComp.Mesh = mTerrainMesh;
			}
			Transform3D trans;
			if (buildingEntity.TryGetComponent<Transform3D>(out trans))
			{
				trans.Position = .(0, -50, 0);
				trans.Scale = .(1.0f, 1.0f, 1.0f); // Assuming it might be large
			}
		}

		mBuildingMesh = AssetManager.Load<Mesh>("models/MP_Granite_ClubHouse_Portal_Assets.glb");

		// Create Building Entity
		if (mBuildingMesh != null)
		{
			var buildingEntity = graph.CreateEntity();
			MeshComponent meshComp;
			if (buildingEntity.TryCreateComponent<MeshComponent>(out meshComp))
			{
				meshComp.Material = mBuildingMaterial;
				meshComp.Mesh = mBuildingMesh;
			}
			Transform3D trans;
			if (buildingEntity.TryGetComponent<Transform3D>(out trans))
			{
				trans.Position = .(0, -50, 0);
				trans.Scale = .(1.0f, 1.0f, 1.0f); // Assuming it might be large
			}
		}

		// Create Camera
		var cameraEntity = graph.CreateEntity();
		Transform3D camTrans;
		if (cameraEntity.TryGetComponent<Transform3D>(out camTrans))
		{
			camTrans.Position = .(0, 0, -40);
		}
		CameraComponent camComp;
		cameraEntity.TryCreateComponent<CameraComponent>(out camComp);
		CameraControllerComponent camController;
		cameraEntity.TryCreateComponent<CameraControllerComponent>(out camController);

		// Create Light
		var lightEntity = graph.CreateEntity();
		Transform3D lightTrans;
		if (lightEntity.TryGetComponent<Transform3D>(out lightTrans))
		{
			lightTrans.Rotation = Quaternion.FromEulerRadians(.(45.0f * Math.PI_f / 180.0f, 45.0f * Math.PI_f / 180.0f, 0));
		}
		LightComponent lightComp;
		if (lightEntity.TryCreateComponent<LightComponent>(out lightComp))
		{
			lightComp.Type = .Directional;
			lightComp.Color = .(1, 1, 1, 1);
			lightComp.Intensity = 1.0f;
		}

		// Enable Relative Mouse Mode for camera control
		SDL_SetWindowRelativeMouseMode(Engine.Window.GetWindowHandle(), true);

		let rng = scope Random();

		// Create Point Lights
		for (int i < 5)
		{
			var pointLight = graph.CreateEntity();
			Transform3D plTrans;
			if (pointLight.TryGetComponent<Transform3D>(out plTrans))
			{
				plTrans.Position = .((float)(rng.NextDouble() * 10 - 5), -20 + (float)(rng.NextDouble() * 6 - 3), (float)(rng.NextDouble() * 10 - 5));
				plTrans.Scale = .(2.0f, 2.0f, 2.0f);
			}
			LightComponent plComp;
			if (pointLight.TryCreateComponent<LightComponent>(out plComp))
			{
				plComp.Type = .Point;
				plComp.Color = .((float)rng.NextDouble(), (float)rng.NextDouble(), (float)rng.NextDouble(), 1.0f);
				plComp.Intensity = 100000.0f;
				plComp.Range = 100000.0f;
			}

			// Add sphere mesh to visualize light
			MeshComponent meshComp;
			if (pointLight.TryCreateComponent<MeshComponent>(out meshComp))
			{
				var mat = new Material(mPipeline);
				mat.Albedo = .(1.0f, 1.0f, 1.0f); // White albedo
				mat.Emissive = .(1.0f, 1.0f, 1.0f); // White emissive
				mat.Roughness = 0.5f;
				mat.Metallic = 0.0f;
				mLightMaterials.Add(mat);

				meshComp.Mesh = mSphereMesh;
				meshComp.Material = mat;
			}

			OrbitPointComponent orbit;
			if (pointLight.TryCreateComponent<OrbitPointComponent>(out orbit))
			{
				orbit.StartAngle = (float)(rng.NextDouble() * Math.PI_f * 2.0f);
				orbit.Direction = (rng.NextDouble() > 0.5) ? 1.0f : -1.0f;
			}
		}

		// Create Floor Plane
		{
			var planeEntity = graph.CreateEntity();
			MeshComponent meshComp;
			if (planeEntity.TryCreateComponent<MeshComponent>(out meshComp))
			{
				meshComp.Material = debugMaterial;
				meshComp.Mesh = mMesh;
			}
			Transform3D trans;
			if (planeEntity.TryGetComponent<Transform3D>(out trans))
			{
				trans.Position = .(0, -25.0f, 0);
				trans.Scale = .(100.0f, 1.0f, 100.0f);
			}
		}

		for (int i < 1000)
		{
			var entity = graph.CreateEntity();
			MeshComponent mesh;
			if (entity.TryCreateComponent<MeshComponent>(out mesh))
			{
				mesh.Material = debugMaterial;
				mesh.Mesh = mMesh;
			}
			Transform3D trans;
			if (entity.TryGetComponent<Transform3D>(out trans))
			{
				trans.Position = .((float)(rng.NextDouble() * 40 - 20), (float)(rng.NextDouble() * 40 - 20), (float)(rng.NextDouble() * 40 - 30));
			}
			RotatingCubeComponent rot;
			if (entity.TryCreateComponent<RotatingCubeComponent>(out rot))
			{
				rot.RotationAxis = .((float)rng.NextDouble(), (float)rng.NextDouble(), (float)rng.NextDouble());
			}
		}

		Engine.Device.SetVSync(Engine.Window, false);

		SystemsManager.RegisterStage(.Update, => InputSystem.Update);
		SystemsManager.RegisterStage(.Update, => FramerateSystem.Update);
		SystemsManager.RegisterStage(.LateUpdate, => RenderSystem.Render);
	}

	public static void Shutdown()
	{
		RenderSystem.Shutdown();
		delete mMesh;
		if (mSphereMesh != null) delete mSphereMesh;
		delete mMaterial;
		delete mTerrainMaterial;
		delete mBuildingMaterial;
		delete mPipeline;
	}

	private static Mesh CreateSphere(float radius, int slices, int stacks)
	{
		List<Vertex> vertices = new .();
		List<uint32> indices = new .();

		for (int i = 0; i <= stacks; ++i)
		{
			float v = (float)i / stacks;
			float phi = v * Math.PI_f;

			for (int j = 0; j <= slices; ++j)
			{
				float u = (float)j / slices;
				float theta = u * Math.PI_f * 2;

				float x = (float)(Math.Cos(theta) * Math.Sin(phi));
				float y = (float)(Math.Cos(phi));
				float z = (float)(Math.Sin(theta) * Math.Sin(phi));

				Vector3 pos = .(x * radius, y * radius, z * radius);
				Vector3 normal = .(x, y, z);
				
				vertices.Add(Vertex(pos, .(1, 1, 1, 1), normal));
			}
		}

		for (int i = 0; i < stacks; ++i)
		{
			for (int j = 0; j < slices; ++j)
			{
				uint32 a = (uint32)(i * (slices + 1) + j);
				uint32 b = (uint32)(a + slices + 1);

				indices.Add(a);
				indices.Add(a + 1);
				indices.Add(b);

				indices.Add(b);
				indices.Add(a + 1);
				indices.Add(b + 1);
			}
		}
		
		Mesh mesh = new Mesh();
		Vertex[] vertArray = new Vertex[vertices.Count];
		vertices.CopyTo(vertArray);
		mesh.SetVertices(vertArray);
		delete vertArray;

		uint32[] idxArray = new uint32[indices.Count];
		indices.CopyTo(idxArray);
		mesh.SetIndices(idxArray);
		delete idxArray;
		
		delete vertices;
		delete indices;

		mesh.Upload(Engine.Device);
		return mesh;
	}
}
