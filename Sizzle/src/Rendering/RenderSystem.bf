using System;
using System.Collections;
using Sizzle.Core;
using Sizzle.Entities;
using Sizzle.Rendering.GPU;
using Sizzle.Math;
using SDL3;
using Sizzle.Components;

namespace Sizzle.Rendering;

public static class RenderSystem
{
	private static GpuBuffer mInstanceBuffer ~ delete _;
	private static uint32 mInstanceCapacity = 0;

	private static GpuTransferBuffer[3] mTransferBuffers;
	private static uint32 mTransferBufferCapacity = 0;
	private static uint64 mFrameCount = 0;

	private static GpuTexture mDepthTexture ~ delete _;

	class RenderBatch
	{
		public Mesh Mesh;
		public Material Material;
		public List<Matrix4x4> Instances = new .() ~ delete _;

		public this(Mesh mesh, Material material)
		{
			Mesh = mesh;
			Material = material;
		}
	}

	private static List<RenderBatch> mBatches = new .() ~ DeleteContainerAndItems!(_);

	public static void Render()
	{
		mFrameCount++;

		// Update transforms
		EntityGraph.GetOrCreate(0).UpdateTransforms();

		var cmd = Engine.Device.AcquireCommandBuffer();
		defer delete cmd;

		var swapchainTexture = Engine.Device.AcquireSwapchainTexture(cmd, Engine.Window);
		defer delete swapchainTexture;

		if (swapchainTexture == null)
		{
			cmd.Submit();
			return;
		}

		// Manage Depth Texture
		if (mDepthTexture == null || mDepthTexture.Width != (uint32)Engine.Window.Size.x || mDepthTexture.Height != (uint32)Engine.Window.Size.y)
		{
			if (mDepthTexture != null) delete mDepthTexture;
			mDepthTexture = Engine.Device.CreateTexture(ref TextureDescriptor((uint32)Engine.Window.Size.x, (uint32)Engine.Window.Size.y, .SDL_GPU_TEXTUREFORMAT_D16_UNORM) { Usage = .SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET });
		}

		// Clear Batches
		for (var batch in mBatches)
			batch.Instances.Clear();

		// Collect Instance Data
		var graph = EntityGraph.GetOrCreate(0);
		var meshRegistry = ComponentSystem.GetRegistry<MeshComponent>();
		uint32 totalInstances = 0;

		for (var mesh in meshRegistry)
		{
			if (mesh == null || mesh.Mesh == null || mesh.Material == null) continue;

			var entityId = mesh.GetEntityId();
			if (entityId.GlobalID == 0) continue;

			Matrix4x4 worldMatrix;
			if (graph.TryGetWorldMatrix(entityId, out worldMatrix))
			{
				RenderBatch batch = null;
				for (var b in mBatches)
				{
					if (b.Mesh == mesh.Mesh && b.Material == mesh.Material)
					{
						batch = b;
						break;
					}
				}

				if (batch == null)
				{
					batch = new RenderBatch(mesh.Mesh, mesh.Material);
					mBatches.Add(batch);
				}

				batch.Instances.Add(worldMatrix);
				totalInstances++;
			}
		}

		if (totalInstances > 0)
		{
			uint32 requiredSize = (uint32)(totalInstances * sizeof(Matrix4x4));

			// Resize Instance Buffer
			if (mInstanceBuffer == null || mInstanceCapacity < requiredSize)
			{
				if (mInstanceBuffer != null) delete mInstanceBuffer;
				mInstanceCapacity = Math.Max(requiredSize, mInstanceCapacity * 2);
				if (mInstanceCapacity == 0) mInstanceCapacity = 1024 * sizeof(Matrix4x4);

				mInstanceBuffer = Engine.Device.CreateBuffer(ref BufferDescriptor(.SDL_GPU_BUFFERUSAGE_VERTEX, mInstanceCapacity));
			}

			// Manage Transfer Buffer
			int frameIndex = (int)(mFrameCount % 3);
			if (mTransferBuffers[frameIndex] == null || mTransferBufferCapacity < requiredSize)
			{
				if (mTransferBuffers[frameIndex] != null) delete mTransferBuffers[frameIndex];
				mTransferBufferCapacity = Math.Max(requiredSize, mTransferBufferCapacity * 2);
				if (mTransferBufferCapacity == 0) mTransferBufferCapacity = 1024 * sizeof(Matrix4x4);

				mTransferBuffers[frameIndex] = Engine.Device.CreateTransferBuffer(ref BufferDescriptor(.SDL_GPU_BUFFERUSAGE_VERTEX, mTransferBufferCapacity));
			}
			var transferBuffer = mTransferBuffers[frameIndex];

			// Upload Data
			if (transferBuffer.TryMap(false, var mappedPtr))
			{
				uint8* ptr = (uint8*)mappedPtr;
				for (var batch in mBatches)
				{
					if (batch.Instances.Count > 0)
					{
						uint32 batchSize = (uint32)(batch.Instances.Count * sizeof(Matrix4x4));
						Internal.MemCpy(ptr, batch.Instances.Ptr, batchSize);
						ptr += batchSize;
					}
				}
				transferBuffer.Unmap();
			}

			cmd.UploadToBuffer(transferBuffer, 0, mInstanceBuffer, 0, requiredSize);
		}

		var colorAttachment = ColorAttachmentInfo()
			{
				Texture = swapchainTexture,
				LoadOp = .SDL_GPU_LOADOP_CLEAR,
				ClearColor = SDL_FColor() { r = 0.1f, g = 0.1f, b = 0.15f, a = 1.0f }
			};
		
		var depthAttachment = DepthStencilAttachmentInfo()
			{
				Texture = mDepthTexture,
				DepthLoadOp = .SDL_GPU_LOADOP_CLEAR,
				DepthStoreOp = .SDL_GPU_STOREOP_DONT_CARE,
				ClearDepth = 1.0f,
				Cycle = true
			};

		{
			var renderPass = cmd.BeginRenderPass(ref colorAttachment, ref depthAttachment);
			defer delete renderPass;

			// Camera setup
			Matrix4x4 viewProj = Matrix4x4.Identity();
			bool cameraFound = false;

			var cameraRegistry = ComponentSystem.GetRegistry<CameraComponent>();
			for (var camera in cameraRegistry)
			{
				if (camera == null) continue;
				var entityId = camera.GetEntityId();
				if (entityId.GlobalID == 0) continue;

				Transform3D transform;
				if (graph.TryGetComponent<Transform3D>(entityId, out transform))
				{
					Vector3 pos = transform.Position;
					Quaternion rot = transform.Rotation;

					Vector3 forward = rot.Rotate(Vector3.Forward);
					Vector3 up = rot.Rotate(Vector3.Up);

					Matrix4x4 view = Matrix4x4.LookAt(pos, pos + forward, up);

					camera.AspectRatio = (float)Engine.Window.Size.x / (float)Engine.Window.Size.y;
					Matrix4x4 proj = camera.GetProjectionMatrix();

					viewProj = proj * view;
					cameraFound = true;
					break;
				}
			}

			if (!cameraFound)
			{
				// Fallback camera
				Vector3 cameraPos = .(0, 0, -40);
				Vector3 target = .(0, 0, 0);
				Vector3 up = .(0, 1, 0);
				Matrix4x4 view = Matrix4x4.LookAt(cameraPos, target, up);

				float aspect = (float)Engine.Window.Size.x / (float)Engine.Window.Size.y;
				Matrix4x4 proj = Matrix4x4.PerspectiveFov(Math.PI_f / 4.0f, aspect, 0.1f, 1000.0f);

				viewProj = proj * view;
			}

			uint32 instanceOffset = 0;
			for (var batch in mBatches)
			{
				if (batch.Instances.Count == 0) continue;

				if (batch.Material != null && batch.Material.Pipeline != null)
				{
					renderPass.BindPipeline(batch.Material.Pipeline);

					if (batch.Mesh != null)
					{
						renderPass.BindVertexBuffer(0, batch.Mesh.VertexBuffer);
						renderPass.BindVertexBuffer(1, mInstanceBuffer, instanceOffset * sizeof(Matrix4x4)); // Bind Instance Buffer with offset

						// Push ViewProj Uniform
						renderPass.PushVertexUniformData(0, &viewProj, sizeof(Matrix4x4));

						if (batch.Mesh.IndexBuffer != null)
						{
							renderPass.BindIndexBuffer(batch.Mesh.IndexBuffer, .SDL_GPU_INDEXELEMENTSIZE_32BIT);
							renderPass.DrawIndexed(batch.Mesh.IndexCount, (uint32)batch.Instances.Count, 0, 0);
						}
						else
						{
							renderPass.Draw(batch.Mesh.VertexCount, (uint32)batch.Instances.Count);
						}
					}
				}
				instanceOffset += (uint32)batch.Instances.Count;
			}
		}

		cmd.Submit();
	}

	public static void Shutdown()
	{
		if (mDepthTexture != null)
		{
			delete mDepthTexture;
			mDepthTexture = null;
		}

		if (mInstanceBuffer != null)
		{
			delete mInstanceBuffer;
			mInstanceBuffer = null;
		}

		for (int i = 0; i < mTransferBuffers.Count; i++)
		{
			if (mTransferBuffers[i] != null)
			{
				delete mTransferBuffers[i];
				mTransferBuffers[i] = null;
			}
		}
	}
}
