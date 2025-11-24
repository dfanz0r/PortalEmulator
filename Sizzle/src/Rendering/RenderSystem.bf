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

		// Collect Instance Data
		List<Matrix4x4> matrices = scope .();
		MeshComponent firstMesh = null;

		var graph = EntityGraph.GetOrCreate(0);
		var meshRegistry = ComponentSystem.GetRegistry<MeshComponent>();
		for (var mesh in meshRegistry)
		{
			if (mesh == null) continue;

			var entityId = mesh.GetEntityId();
			if (entityId.GlobalID == 0) continue;

			Matrix4x4 worldMatrix;
			if (graph.TryGetWorldMatrix(entityId, out worldMatrix))
			{
				matrices.Add(worldMatrix);
				if (firstMesh == null) firstMesh = mesh;
			}
		}

		if (matrices.Count > 0)
		{
			uint32 requiredSize = (uint32)(matrices.Count * sizeof(Matrix4x4));

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
				Internal.MemCpy(mappedPtr, matrices.Ptr, requiredSize);
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

			if (firstMesh != null && firstMesh.Material != null && firstMesh.Material.Pipeline != null && matrices.Count > 0)
			{
				renderPass.BindPipeline(firstMesh.Material.Pipeline);

				if (firstMesh.Mesh != null)
				{
					renderPass.BindVertexBuffer(0, firstMesh.Mesh.VertexBuffer);
					renderPass.BindVertexBuffer(1, mInstanceBuffer); // Bind Instance Buffer

					// Push ViewProj Uniform
					renderPass.PushVertexUniformData(0, &viewProj, sizeof(Matrix4x4));

					if (firstMesh.Mesh.IndexBuffer != null)
					{
						renderPass.BindIndexBuffer(firstMesh.Mesh.IndexBuffer, .SDL_GPU_INDEXELEMENTSIZE_16BIT);
						renderPass.DrawIndexed(firstMesh.Mesh.IndexCount, (uint32)matrices.Count, 0, 0);
					}
					else
					{
						renderPass.Draw(firstMesh.Mesh.VertexCount, (uint32)matrices.Count);
					}
				}
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
