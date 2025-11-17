using System;
using SDL3;
using Sizzle.Core;

namespace Sizzle.Rendering.GPU;

/// @brief A wrapper around an SDL_GPUCommandBuffer.
/// @details Manages the lifecycle of acquiring, recording, and submitting commands.
/// The destructor will automatically cancel the command buffer if it has not been submitted.
public class CommandBuffer
{
	private RenderDevice mRenderDevice;
	private SDL_GPUCommandBuffer* mHandle;
	private bool mIsSubmitted = false;

	/// @brief Acquires a new command buffer from the device.
	public this(RenderDevice device)
	{
		mRenderDevice = device;
		mHandle = SDL_AcquireGPUCommandBuffer(mRenderDevice.GetDeviceHandle());

		if (mHandle == null)
		{
			Console.WriteLine("FATAL: Failed to acquire command buffer from SDL. The internal pool may be exhausted due to a leak.");
		}
	}

	/// @brief Destructor that acts as a safety net, canceling the command buffer if it was never submitted.
	public ~this()
	{
		if (mHandle != null && !mIsSubmitted)
		{
			// This prevents leaks of the underlying native command buffer if Submit() is never called.
			SDL_CancelGPUCommandBuffer(mHandle);
		}
	}

	/// @brief Gets the underlying SDL_GPUCommandBuffer handle.
	public SDL_GPUCommandBuffer* GetHandle() => mHandle;

	/// @brief Records a command to upload data from a transfer buffer to a GPU buffer.
	public void UploadToBuffer(
		GpuTransferBuffer transferBuffer,
		uint32 transferOffset,
		GpuBuffer destinationBuffer,
		uint32 destOffset,
		uint32 size)
	{
		if (mHandle == null) return;
		var copyPass = SDL_BeginGPUCopyPass(mHandle);

		var src = SDL_GPUTransferBufferLocation()
			{
				transfer_buffer = transferBuffer.GetHandle(),
				offset = transferOffset
			};

		var dst = SDL_GPUBufferRegion()
			{
				buffer = destinationBuffer.GetHandle(),
				offset = destOffset,
				size = size
			};

		SDL_UploadToGPUBuffer(copyPass, &src, &dst, false);
		SDL_EndGPUCopyPass(copyPass);
	}

	/// @brief Begins a render pass that targets a single color attachment.
	public RenderPass BeginRenderPass(ref ColorAttachmentInfo colorInfo)
	{
		if (mHandle == null) return null; // Don't crash if constructor failed
		return new RenderPass(this, ref colorInfo);
	}

	/// @brief Begins a render pass that targets a color attachment and a depth/stencil attachment.
	public RenderPass BeginRenderPass(
		ref ColorAttachmentInfo colorAttachment,
		ref DepthStencilAttachmentInfo depthAttachment)
	{
		if (mHandle == null) return null; // Don't crash if constructor failed
		return new RenderPass(this, ref colorAttachment, ref depthAttachment);
	}

	/// @brief Submits the command buffer to the GPU for execution.
	public void Submit()
	{
		if (mHandle != null && !mIsSubmitted)
		{
			SDL_SubmitGPUCommandBuffer(mHandle);
			mIsSubmitted = true;
			// After submission, the handle is invalid. Setting it to null prevents reuse.
			mHandle = null;
		}
	}
}