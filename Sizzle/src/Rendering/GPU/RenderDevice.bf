using System;
using SDL3;
using Sizzle.Core;
using SDL3_shadercross;

namespace Sizzle.Rendering.GPU;

/// @brief Main class for interacting with the GPU. Manages the device, swapchain,
/// and acts as a factory for GPU resources and command buffers.
public class RenderDevice
{
	private SDL_GPUDevice* device;
	private SDL_GPUShaderFormat mTargetShaderFormat; // To store the backend's preferred format

	/// @brief Creates a new, uninitialized RenderDevice.
	public this() { }

	/// @brief Initializes the RenderDevice and claims a window for rendering.
	/// @param window The main window to be used for rendering.
	/// @return True on success, false on failure.
	public bool Create(in Window window)
	{
		// We tell SDL we can provide SPIR-V (from HLSL) or DXIL (from HLSL).
		var supportedFormats = SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPUShaderFormat.SDL_GPU_SHADERFORMAT_DXIL;

		// To test D3D12, we explicitly request it. To go back to Vulkan, set this to null.
		char8* preferredBackend =  "direct3d12"; // null;
		//char8* preferredBackend = null; // for Vulkan

		device = SDL_CreateGPUDevice(supportedFormats, true, preferredBackend);
		if (device == null)
		{
			Console.WriteLine($"Failed to create GPU Device: {scope String(SDL_GetError())}");
			return false;
		}

		// Store the format that the chosen backend actually requires.
		mTargetShaderFormat = SDL_GetGPUShaderFormats(device);

		var sdlWindow = window.GetWindowHandle();
		if (!SDL_ClaimWindowForGPUDevice(device, sdlWindow))
		{
			Console.WriteLine($"Failed to bind window to GPU Device: {scope String(SDL_GetError())}");
			return false;
		}
		return true;
	}

	/// @brief Destroys the GPU device and releases all associated resources.
	public ~this()
	{
		if (device != null)
		{
			SDL_DestroyGPUDevice(device);
		}
	}

	/// @brief Gets the underlying SDL_GPUDevice handle for advanced or direct interop.
	public SDL_GPUDevice* GetDeviceHandle() => device;

	// Factory Methods

	/// @brief Creates a new GpuBuffer from a descriptor.
	public GpuBuffer CreateBuffer(ref BufferDescriptor descriptor)
	{
		var createInfo = descriptor.ToSDL();
		return new GpuBuffer(this, ref createInfo);
	}

	/// @brief Creates a new GpuTransferBuffer from a descriptor.
	public GpuTransferBuffer CreateTransferBuffer(ref BufferDescriptor descriptor)
	{
		var createInfo = SDL_GPUTransferBufferCreateInfo()
			{
				usage = (descriptor.Usage == .SDL_GPU_BUFFERUSAGE_INDIRECT) ? .SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD : .SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
				size = descriptor.Size
			};
		return new GpuTransferBuffer(this, ref createInfo);
	}

	/// @brief Creates a new GpuTexture from a descriptor.
	public GpuTexture CreateTexture(ref TextureDescriptor descriptor)
	{
		var createInfo = descriptor.ToSDL();
		return new GpuTexture(this, ref createInfo);
	}

	/// @brief Creates a new GpuShader from a high-level descriptor containing pre-compiled bytecode.
	/// @param descriptor A struct describing the shader bytecode and stage.
	/// @return The newly created GpuShader.
	public GpuShader CreateShader(ref ShaderDescriptor descriptor)
	{
		var createInfo = descriptor.ToSDL();
		return new GpuShader(this, ref createInfo);
	}

	private static SDL_GPUShaderStage ToGpuShaderStage(SDL_ShaderCross_ShaderStage crossStage)
	{
		switch (crossStage)
		{
		case .SDL_SHADERCROSS_SHADERSTAGE_VERTEX:
			return .SDL_GPU_SHADERSTAGE_VERTEX;
		case .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT:
			return .SDL_GPU_SHADERSTAGE_FRAGMENT;
		default: // Invalid for this path
			return .SDL_GPU_SHADERSTAGE_VERTEX;
		}
	}

	/// @brief Compiles HLSL source code at runtime and creates a GpuShader.
	/// @details This is the recommended way to create shaders. It handles compilation,
	/// reflection, and resource creation automatically.
	/// @param hlslSource The HLSL source code as a string.
	/// @param stage The shader stage (Vertex or Fragment).
	/// @param entryPoint The name of the main function in the shader.
	/// @return The newly created GpuShader, or null on failure.
	public GpuShader CreateShaderFromHLSL(String hlslSource, SDL_ShaderCross_ShaderStage stage, String entryPoint = "main")
	{
		var hlslInfo = SDL_ShaderCross_HLSL_Info() { source = hlslSource.CStr(), entrypoint = entryPoint.CStr(), shader_stage = stage };

		uint spirvSize = 0;
		void* spirvBytecodeRaw = SDL_ShaderCross_CompileSPIRVFromHLSL(&hlslInfo, &spirvSize);
		if (spirvBytecodeRaw == null)
		{
			Console.WriteLine($"[SDL_shadercross Error]: {scope String(SDL_GetError())}");
			Console.WriteLine($"Failed to compile HLSL to SPIR-V for reflection. Entry: {entryPoint}");
			return null;
		}
		defer SDL_free(spirvBytecodeRaw);

		var metadata = SDL_ShaderCross_ReflectGraphicsSPIRV((uint8*)spirvBytecodeRaw, spirvSize, 0);
		if (metadata == null)
		{
			Console.WriteLine($"Failed to reflect SPIR-V. Entry: {entryPoint}");
			return null;
		}
		defer SDL_free(metadata);

		void* finalBytecode = null;
		uint finalBytecodeSize = 0;
		SDL_GPUShaderFormat finalFormat = .SDL_GPU_SHADERFORMAT_INVALID;
		defer SDL_free(finalBytecode);

		if ((mTargetShaderFormat & .SDL_GPU_SHADERFORMAT_DXIL) != 0)
		{
			finalBytecode = SDL_ShaderCross_CompileDXILFromHLSL(&hlslInfo, &finalBytecodeSize);
			finalFormat = .SDL_GPU_SHADERFORMAT_DXIL;
		}
		else if ((mTargetShaderFormat & .SDL_GPU_SHADERFORMAT_SPIRV) != 0)
		{
			finalBytecode = spirvBytecodeRaw;
			finalBytecodeSize = spirvSize;
			finalFormat = .SDL_GPU_SHADERFORMAT_SPIRV;

			spirvBytecodeRaw = null;
		}
		else
		{
			Console.WriteLine("Unsupported shader format required by the active GPU backend. Could not find a path for DXIL or SPIRV.");
			return null;
		}

		if (finalBytecode == null)
		{
			Console.WriteLine($"[SDL_shadercross Error]: {scope String(SDL_GetError())}");
			Console.WriteLine($"Failed to produce final shader bytecode for format {finalFormat}.");
			return null;
		}

		var createInfo = SDL_GPUShaderCreateInfo()
			{
				code = (uint8*)finalBytecode,
				code_size = finalBytecodeSize,
				format = finalFormat,
				stage = ToGpuShaderStage(stage),
				entrypoint = entryPoint.CStr(),
				num_samplers = metadata.resource_info.num_samplers,
				num_storage_textures = metadata.resource_info.num_storage_textures,
				num_storage_buffers = metadata.resource_info.num_storage_buffers,
				num_uniform_buffers = metadata.resource_info.num_uniform_buffers
			};
		return new GpuShader(this, ref createInfo);
	}

	/// @brief Compiles HLSL source code at runtime and creates a complete ComputePipeline.
	/// @details This follows a different path than graphics shaders. It compiles, reflects,
	/// and creates the final pipeline object in one step.
	/// @param hlslSource The HLSL compute shader source code as a string.
	/// @param entryPoint The name of the main function (kernel) in the shader.
	/// @return The newly created ComputePipeline, or null on failure.
	public ComputePipeline CreateComputePipelineFromHLSL(String hlslSource, String entryPoint = "main")
	{
		// TODO - NOT TESTED

		// Compile HLSL to SPIR-V for Reflection
		var hlslInfo = SDL_ShaderCross_HLSL_Info() { source = hlslSource.CStr(), entrypoint = entryPoint.CStr(), shader_stage = .SDL_SHADERCROSS_SHADERSTAGE_COMPUTE };
		uint spirvSize = 0;
		void* spirvBytecodeRaw = SDL_ShaderCross_CompileSPIRVFromHLSL(&hlslInfo, &spirvSize);

		if (spirvBytecodeRaw == null)
		{
			Console.WriteLine($"[SDL_shadercross Error]: {scope String(SDL_GetError())}");
			Console.WriteLine($"Failed to compile HLSL compute shader to SPIR-V. Entry: {entryPoint}");
			return null;
		}
		defer SDL_free(spirvBytecodeRaw);

		// Reflect on the SPIR-V to get Compute Metadata
		var metadata = SDL_ShaderCross_ReflectComputeSPIRV((uint8*)spirvBytecodeRaw, spirvSize, 0);
		if (metadata == null)
		{
			Console.WriteLine($"Failed to reflect compute SPIR-V. Entry: {entryPoint}");
			return null;
		}
		defer SDL_free(metadata);

		// Use the high-level SDL_shadercross helper to create the final pipeline object.
		// This function internally handles the conversion from SPIR-V to the backend's native format.
		var spirvInfo = SDL_ShaderCross_SPIRV_Info()
			{
				bytecode = (uint8*)spirvBytecodeRaw,
				bytecode_size = spirvSize,
				entrypoint = entryPoint.CStr(),
				shader_stage = .SDL_SHADERCROSS_SHADERSTAGE_COMPUTE
			};

		SDL_GPUComputePipeline* pipelineHandle = SDL_ShaderCross_CompileComputePipelineFromSPIRV(
			device,
			&spirvInfo,
			metadata,
			0
			);

		if (pipelineHandle == null)
		{
			Console.WriteLine("SDL_ShaderCross_CompileComputePipelineFromSPIRV failed.");
			return null;
		}

		return new ComputePipeline(this, pipelineHandle);
	}

	/// @brief Acquires a new command buffer from the device for command recording.
	public CommandBuffer AcquireCommandBuffer()
	{
		return new CommandBuffer(this);
	}

	/// @brief Blocks until a swapchain texture is available, then acquires it for rendering.
	public GpuTexture AcquireSwapchainTexture(CommandBuffer commandBuffer, Window window)
	{
		if (commandBuffer == null)
		{
			Console.WriteLine("ERROR: Attempted to acquire swapchain texture with an invalid (null) command buffer.");
			return null;
		}
		// This check prevents a crash if a null command buffer is used.
		var cmdHandle = commandBuffer.GetHandle();
		if (cmdHandle == null)
		{
			Console.WriteLine("ERROR: Attempted to acquire swapchain texture with an invalid (null) command buffer.");
			return null;
		}

		SDL_GPUTexture* swapchainTexture = null;
		SDL_WaitAndAcquireGPUSwapchainTexture(
			cmdHandle, // Use the validated handle
			window.GetWindowHandle(),
			&swapchainTexture, null, null
			);

		if (swapchainTexture == null)
		{
			return null;
		}
		return new GpuTexture(this, swapchainTexture, false);
	}
}