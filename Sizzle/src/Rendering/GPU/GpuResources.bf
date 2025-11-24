using System;
using SDL3;

namespace Sizzle.Rendering.GPU;

public abstract class GpuResource<T>
{
	protected RenderDevice mRenderDevice;
	protected T* mHandle;

	public this(RenderDevice device)
	{
		mRenderDevice = device;
	}

	/// @brief Checks if the handle was created successfully.
	/// @return True if the handle is valid, false otherwise.
	public bool IsHandleValid() => mHandle != null;

	/// @brief Gets the underlying handle.
	public T* GetHandle() => mHandle;
}

public class GpuBuffer : GpuResource<SDL_GPUBuffer>
{
	private uint32 mSize;

	/// @brief Creates a GPU buffer from the SDL creation info struct.
	public this(RenderDevice device, ref SDL_GPUBufferCreateInfo createInfo) : base(device)
	{
		mHandle = SDL_CreateGPUBuffer(device.GetDeviceHandle(), &createInfo);
		if (mHandle == null)
		{
			Console.WriteLine($"Failed to create GPU Buffer: {SDL_GetError()}");
		}
		mSize = createInfo.size;
	}

	/// @brief Destructor that automatically releases the GPU resource.
	public ~this()
	{
		if (mHandle != null)
		{
			SDL_ReleaseGPUBuffer(mRenderDevice.GetDeviceHandle(), mHandle);
		}
	}

	public uint32 GetSize() => mSize;
}

public class GpuTransferBuffer : GpuResource<SDL_GPUTransferBuffer>
{
	private uint32 mSize;
	private bool mIsMapped;

	/// @brief Creates a GPU transfer buffer from the SDL creation info struct.
	public this(RenderDevice device, ref SDL_GPUTransferBufferCreateInfo createInfo) : base(device)
	{
		mHandle = SDL_CreateGPUTransferBuffer(device.GetDeviceHandle(), &createInfo);
		if (mHandle == null)
		{
			Console.WriteLine($"Failed to create GPU Transfer Buffer: {SDL_GetError()}");
		}
		mSize = createInfo.size;
		mIsMapped = false;
	}

	/// @brief Destructor that automatically releases the GPU resource.
	public ~this()
	{
		if (mHandle != null)
		{
			if (mIsMapped)
			{
				Console.WriteLine("Warning: GpuTransferBuffer being destroyed while still mapped. Unmapping automatically.");
				SDL_UnmapGPUTransferBuffer(mRenderDevice.GetDeviceHandle(), mHandle);
				mIsMapped = false;
			}
			SDL_ReleaseGPUTransferBuffer(mRenderDevice.GetDeviceHandle(), mHandle);
		}
	}

	public uint32 GetSize() => mSize;

	/// @brief Attempts to map the transfer buffer's memory so the CPU can write to (or read from) it.
	/// @param cycle If true, cycles the internal buffer if it's currently in use by the GPU.
	/// @param buffer Receives a pointer to the mapped memory if successful.
	/// @return True if the mapping succeeded, false otherwise.
	public bool TryMap(bool cycle, out void* buffer)
	{
		if (mIsMapped)
		{
			Console.WriteLine("Warning: Attempting to map an already-mapped GpuTransferBuffer.");
			buffer = null;
			return false;
		}

		if (mHandle == null)
		{
			Console.WriteLine("Error: Attempted to map a null Transfer Buffer.");
			buffer = null;
			mIsMapped = false;
			return false;
		}

		buffer = SDL_MapGPUTransferBuffer(mRenderDevice.GetDeviceHandle(), mHandle, cycle);
		mIsMapped = buffer != null;
		return mIsMapped;
	}

	/// @brief Unmaps a previously mapped transfer buffer, making the data visible to the GPU.
	public void Unmap()
	{
		if (!mIsMapped)
		{
			Console.WriteLine("Warning: Attempting to unmap a GpuTransferBuffer that is not currently mapped.");
			return;
		}

		SDL_UnmapGPUTransferBuffer(mRenderDevice.GetDeviceHandle(), mHandle);
		mIsMapped = false;
	}
}

public class GpuTexture : GpuResource<SDL_GPUTexture>
{
	private bool mIsOwned;
	public uint32 Width { get; private set; }
	public uint32 Height { get; private set; }

	/// @brief Creates a GPU texture by wrapping an existing SDL handle.
	/// @param device The render device.
	/// @param handle The SDL_GPUTexture handle.
	/// @param isOwned If true, the texture will be released when this object is destroyed.
	public this(RenderDevice device, SDL_GPUTexture* handle, bool isOwned, uint32 width, uint32 height) : base(device)
	{
		mHandle = handle;
		mIsOwned = isOwned;
		Width = width;
		Height = height;
	}

	/// @brief Creates a GPU texture from the SDL creation info struct.
	public this(RenderDevice device, ref SDL_GPUTextureCreateInfo createInfo)
		: this(device, SDL_CreateGPUTexture(device.GetDeviceHandle(), &createInfo), true, createInfo.width, createInfo.height)
	{
		if (mHandle == null)
		{
			Console.WriteLine($"Failed to create GPU Texture: {SDL_GetError()}");
		}
	}

	/// @brief Destructor that releases the GPU resource if owned.
	public ~this()
	{
		if (mIsOwned && mHandle != null)
		{
			SDL_ReleaseGPUTexture(mRenderDevice.GetDeviceHandle(), mHandle);
		}
	}
}

/// @brief Manages an SDL_GPUShader resource. Represents a single compiled shader stage.
public class GpuShader : GpuResource<SDL_GPUShader>
{

	/// @brief Creates a GpuShader from its low-level creation info struct.
	public this(RenderDevice device, ref SDL_GPUShaderCreateInfo createInfo) : base(device)
	{
		mHandle = SDL_CreateGPUShader(device.GetDeviceHandle(), &createInfo);
		if (mHandle == null)
		{
			Console.WriteLine($"Failed to create GPU Shader: {SDL_GetError()}");
		}
	}

	/// @brief Destructor that automatically releases the GPU resource.
	public ~this()
	{
		if (mHandle != null)
		{
			SDL_ReleaseGPUShader(mRenderDevice.GetDeviceHandle(), mHandle);
		}
	}
}



/// @brief Manages an SDL_GPUGraphicsPipeline resource. Defines the full state for a graphics render pass.
public class GraphicsPipeline : GpuResource<SDL_GPUGraphicsPipeline>
{
	/// @brief Creates a graphics pipeline from its low-level creation info struct.
	public this(RenderDevice device, ref SDL_GPUGraphicsPipelineCreateInfo createInfo) : base(device)
	{
		mHandle = SDL_CreateGPUGraphicsPipeline(device.GetDeviceHandle(), &createInfo);
		if (mHandle == null)
		{
			Console.WriteLine($"Failed to create GPU Graphics Pipeline: {SDL_GetError()}");
		}
	}

	/// @brief Destructor that automatically releases the GPU resource.
	public ~this()
	{
		if (mHandle != null)
		{
			SDL_ReleaseGPUGraphicsPipeline(mRenderDevice.GetDeviceHandle(), mHandle);
		}
	}
}

/// @brief Manages an SDL_GPUComputePipeline resource. Defines the full state for a compute dispatch.
public class ComputePipeline : GpuResource<SDL_GPUComputePipeline>
{
	/// @brief Creates a ComputePipeline by wrapping an existing SDL handle.
	public this(RenderDevice device, SDL_GPUComputePipeline* handle) : base(device)
	{
		mHandle = handle;
		if (mHandle == null) { Console.WriteLine($"Failed to create GPU Compute Pipeline (handle was null)."); }
	}

	/// @brief Destructor that automatically releases the GPU resource.
	public ~this()
	{
		if (mHandle != null)
		{
			SDL_ReleaseGPUComputePipeline(mRenderDevice.GetDeviceHandle(), mHandle);
		}
	}
}