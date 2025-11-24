using System;
using System.IO;
using System.Interop;
using Sizzle.Math;
using Sizzle.Core;
using Sizzle.Entities;
using Sizzle.Rendering;
using Sizzle.Rendering.GPU;
using SDL3;
using SDL3_shadercross;
using PortalEmulator.Components;
using Sizzle.Components;

namespace PortalEmulator.Systems;

static class GameSystem : ISystemInit
{
	[CRepr]
	struct Vertex
	{
		public Vector3 Position;
		public Vector4 Color;

		public this(Vector3 pos, Vector4 col)
		{
			Position = pos;
			Color = col;
		}
	}

	private static Mesh mMesh;
	private static Material mMaterial;
	private static GraphicsPipeline mPipeline;

	public static void Setup()
	{
		// Cube Vertices (8 vertices)
		Vertex[] vertices = new Vertex[]( // Front
			Vertex(Vector3(-0.5f, -0.5f,  0.5f), Vector4(1.0f, 0.0f, 0.0f, 1.0f)), // 0
			Vertex(Vector3(0.5f, -0.5f,  0.5f), Vector4(0.0f, 1.0f, 0.0f, 1.0f)), // 1
			Vertex(Vector3(0.5f,  0.5f,  0.5f), Vector4(0.0f, 0.0f, 1.0f, 1.0f)), // 2
			Vertex(Vector3(-0.5f,  0.5f,  0.5f), Vector4(1.0f, 1.0f, 0.0f, 1.0f)), // 3
			// Back
			Vertex(Vector3(-0.5f, -0.5f, -0.5f), Vector4(1.0f, 0.0f, 1.0f, 1.0f)), // 4
			Vertex(Vector3(0.5f, -0.5f, -0.5f), Vector4(0.0f, 1.0f, 1.0f, 1.0f)), // 5
			Vertex(Vector3(0.5f,  0.5f, -0.5f), Vector4(1.0f, 1.0f, 1.0f, 1.0f)), // 6
			Vertex(Vector3(-0.5f,  0.5f, -0.5f), Vector4(0.0f, 0.0f, 0.0f, 1.0f)) // 7
			);
		defer delete vertices;

		// Cube Indices (36 indices)
		uint16[] indices = new uint16[]( // Front
			0, 1, 2, 2, 3, 0, // Right
			1, 5, 6, 6, 2, 1, // Back
			7, 6, 5, 5, 4, 7, // Left
			4, 0, 3, 3, 7, 4, // Top
			3, 2, 6, 6, 7, 3, // Bottom
			4, 5, 1, 1, 0, 4
			);
		defer delete indices;

		// Create Shaders
		var vertSource = new String();
		defer delete vertSource;
		String vertPath = new String();
		defer delete vertPath;
		Utils.GetAssetPath(vertPath, "shaders/simple.vert.hlsl");
		if (File.ReadAllText(vertPath, vertSource) case .Err)
		{
			Console.WriteLine("Failed to read vertex shader.");
			return;
		}

		var fragSource = new String();
		defer delete fragSource;
		var fragPath = new String();
		defer delete fragPath;
		Utils.GetAssetPath(fragPath, "shaders/simple.frag.hlsl");
		if (File.ReadAllText(fragPath, fragSource) case .Err)
		{
			Console.WriteLine("Failed to read fragment shader.");
			return;
		}

		var vertShader = Engine.Device.CreateShaderFromHLSL(vertSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX);
		defer delete vertShader;
		var fragShader = Engine.Device.CreateShaderFromHLSL(fragSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT);
		defer delete fragShader;

		if (vertShader == null || fragShader == null) return;

		// Create Pipeline
		let builder = scope GraphicsPipelineBuilder();
		mPipeline = builder
			.SetShaders(vertShader, fragShader)
			.AddVertexBuffer(0, (uint32)sizeof(Vertex))
			.AddVertexAttribute(0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3, 0) // Position
			.AddVertexAttribute(1, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, (uint32)sizeof(Vector3)) // Color
			// Instance Data (Model Matrix)
			.AddVertexBuffer(1, (uint32)sizeof(Matrix4x4), .SDL_GPU_VERTEXINPUTRATE_INSTANCE)
			.AddVertexAttribute(2, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, 0)
			.AddVertexAttribute(3, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, 16)
			.AddVertexAttribute(4, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, 32)
			.AddVertexAttribute(5, 1, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, 48)
			.AddColorTarget(SDL_GetGPUSwapchainTextureFormat(Engine.Device.GetDeviceHandle(), Engine.Window.GetWindowHandle()))
			.SetPrimitiveType(.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST)
			.Build(Engine.Device);

		if (mPipeline == null)
		{
			Console.WriteLine("Failed to build pipeline.");
			return;
		}

		mMaterial = new Material(mPipeline);

		mMesh = new Mesh();
		mMesh.SetVertices(vertices);
		mMesh.SetIndices(indices);
		mMesh.Upload(Engine.Device);

		// --- Create Entities ---
		var graph = EntityGraph.GetOrCreate(0);

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

		// Enable Relative Mouse Mode for camera control
		SDL_SetWindowRelativeMouseMode(Engine.Window.GetWindowHandle(), true);

		let rng = scope Random();

		for (int i < 1000)
		{
			var entity = graph.CreateEntity();
			MeshComponent mesh;
			if (entity.TryCreateComponent<MeshComponent>(out mesh))
			{
				mesh.Material = mMaterial;
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
		delete mMaterial;
		delete mPipeline;
	}
}
