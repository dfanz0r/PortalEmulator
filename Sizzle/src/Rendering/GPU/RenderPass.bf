using System;
using SDL3;

namespace Sizzle.Rendering.GPU;

/// @brief A short-lived encoder for recording commands within a render pass.
/// @details Its destructor automatically ends the render pass, making it ideal for use
/// within a 'scope' block or with 'defer delete'. It should only be created by CommandBuffer.BeginRenderPass().
public class RenderPass
{
	private SDL_GPURenderPass* mHandle;
	private SDL_GPUCommandBuffer* mCmdHandle;

	// Store the SDL structs as member fields to guarantee their memory is valid
	// for the lifetime of the RenderPass object.
	private SDL_GPUColorTargetInfo mColorInfo;
	private SDL_GPUDepthStencilTargetInfo mDepthInfo;

	/// @brief Constructs a RenderPass for a single color target.
	/// @param commandBuffer The command buffer that owns this render pass.
	/// @param colorAttachment The description of the color target to render to.
	public this(CommandBuffer commandBuffer, ref ColorAttachmentInfo colorAttachment)
	{
		mCmdHandle = commandBuffer.GetHandle();
		// 1. Initialize our member field. Its memory is now stable.
		mColorInfo = colorAttachment.ToSDL();

		// 2. Call the underlying SDL function, passing a pointer to our stable member field.
		mHandle = SDL_BeginGPURenderPass(
			mCmdHandle,
			&mColorInfo, // Pass the pointer to our class member.
			1, // We know it's one color target.
			null // No depth/stencil target in this constructor.
			);
	}


	/// @brief Constructs a RenderPass for a color target and a depth/stencil target.
	/// @param commandBuffer The command buffer that owns this render pass.
	/// @param colorAttachment The description of the color target.
	/// @param depthAttachment The description of the depth/stencil target.
	public this(
		CommandBuffer commandBuffer,
		ref ColorAttachmentInfo colorAttachment,
		ref DepthStencilAttachmentInfo depthAttachment)
	{
		mCmdHandle = commandBuffer.GetHandle();
		// 1. Initialize our member fields. Their memory is now stable.
		mColorInfo = colorAttachment.ToSDL();
		mDepthInfo = depthAttachment.ToSDL();

		// 2. Call the underlying SDL function, passing pointers to our stable member fields.
		mHandle = SDL_BeginGPURenderPass(
			mCmdHandle,
			&mColorInfo,
			1,
			&mDepthInfo
			);
	}

	/// @brief Destructor that automatically ends the underlying SDL_GPURenderPass.
	public ~this()
	{
		if (mHandle != null)
		{
			SDL_EndGPURenderPass(mHandle);
		}
	}

	/// @brief Binds a graphics pipeline for subsequent draw calls.
	/// @param pipeline The GraphicsPipeline to bind.
	public void BindPipeline(GraphicsPipeline pipeline)
	{
		SDL_BindGPUGraphicsPipeline(mHandle, pipeline.GetHandle());
	}

	/// @brief Binds a single vertex buffer to a specific binding slot.
	/// @param slot The binding slot for the buffer.
	/// @param buffer The GpuBuffer to bind.
	/// @param offset An optional byte offset into the buffer.
	public void BindVertexBuffer(uint32 slot, GpuBuffer buffer, uint32 offset = 0)
	{
		var binding = SDL_GPUBufferBinding() { buffer = buffer.GetHandle(), offset = offset };
		SDL_BindGPUVertexBuffers(mHandle, slot, &binding, 1);
	}

	/// @brief Binds an index buffer for subsequent indexed draw calls.
	/// @param buffer The GpuBuffer to bind as an index buffer.
	/// @param indexSize The size of each index (16-bit or 32-bit).
	/// @param offset An optional byte offset into the buffer.
	public void BindIndexBuffer(GpuBuffer buffer, SDL_GPUIndexElementSize indexSize, uint32 offset = 0)
	{
		var binding = SDL_GPUBufferBinding() { buffer = buffer.GetHandle(), offset = offset };
		SDL_BindGPUIndexBuffer(mHandle, &binding, indexSize);
	}

	/// @brief Records a non-indexed draw call.
	/// @param vertexCount The number of vertices to draw.
	/// @param instanceCount The number of instances to draw.
	/// @param firstVertex An optional offset into the vertex buffer.
	/// @param firstInstance An optional offset for SV_InstanceID.
	public void Draw(uint32 vertexCount, uint32 instanceCount = 1, uint32 firstVertex = 0, uint32 firstInstance = 0)
	{
		SDL_DrawGPUPrimitives(mHandle, vertexCount, instanceCount, firstVertex, firstInstance);
	}

	/// @brief Records an indexed draw call.
	/// @param indexCount The number of indices to draw.
	/// @param instanceCount The number of instances to draw.
	/// @param firstIndex An optional offset into the index buffer.
	/// @param vertexOffset An optional value added to each vertex index before lookup.
	/// @param firstInstance An optional offset for SV_InstanceID.
	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1, uint32 firstIndex = 0, int32 vertexOffset = 0, uint32 firstInstance = 0)
	{
		SDL_DrawGPUIndexedPrimitives(mHandle, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance);
	}

	/// @brief Pushes data to a uniform slot on the vertex shader.
	/// @param slotIndex The uniform slot index (register).
	/// @param data Pointer to the data to push.
	/// @param lengthInBytes Size of the data in bytes.
	public void PushVertexUniformData(uint32 slotIndex, void* data, uint32 lengthInBytes)
	{
		SDL_PushGPUVertexUniformData(mCmdHandle, slotIndex, data, lengthInBytes);
	}

	/// @brief Pushes data to a uniform slot on the fragment shader.
	/// @param slotIndex The uniform slot index (register).
	/// @param data Pointer to the data to push.
	/// @param lengthInBytes Size of the data in bytes.
	public void PushFragmentUniformData(uint32 slotIndex, void* data, uint32 lengthInBytes)
	{
		SDL_PushGPUFragmentUniformData(mCmdHandle, slotIndex, data, lengthInBytes);
	}

	/// @brief Binds a storage buffer to the fragment shader.
	/// @param slot The binding slot.
	/// @param buffer The GpuBuffer to bind.
	/// @param offset Byte offset.
	public void BindFragmentStorageBuffer(uint32 slot, GpuBuffer buffer, uint32 offset = 0)
	{
		var bufferHandle = buffer.GetHandle();
		SDL_BindGPUFragmentStorageBuffers(mHandle, slot, &bufferHandle, 1);
	}

	/// @brief Binds a storage buffer to the vertex shader.
	/// @param slot The binding slot.
	/// @param buffer The GpuBuffer to bind.
	public void BindVertexStorageBuffer(uint32 slot, GpuBuffer buffer)
	{
		var bufferHandle = buffer.GetHandle();
		SDL_BindGPUVertexStorageBuffers(mHandle, slot, &bufferHandle, 1);
	}
}