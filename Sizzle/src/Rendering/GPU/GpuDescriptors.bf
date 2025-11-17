using System;
using System.Collections;
using SDL3;

namespace Sizzle.Rendering.GPU;

/// @brief A descriptor for creating a GpuBuffer.
public struct BufferDescriptor
{
	public SDL_GPUBufferUsageFlags Usage;
	public uint32 Size;

	/// @brief Creates a new buffer descriptor.
	/// @param usage How the buffer will be used (e.g., as a vertex or index buffer).
	/// @param size The total size of the buffer in bytes.
	public this(SDL_GPUBufferUsageFlags usage, uint32 size)
	{
		Usage = usage;
		Size = size;
	}

	/// @brief Converts this high-level struct to the low-level SDL struct.
	public SDL_GPUBufferCreateInfo ToSDL()
	{
		return SDL_GPUBufferCreateInfo() { usage = Usage, size = Size };
	}
}

/// @brief A descriptor for creating a GpuTexture.
public struct TextureDescriptor
{
	public uint32 Width;
	public uint32 Height;
	public SDL_GPUTextureFormat Format;
	public SDL_GPUTextureUsageFlags Usage = .SDL_GPU_TEXTUREUSAGE_SAMPLER | .SDL_GPU_TEXTUREUSAGE_COLOR_TARGET;

	/// @brief Creates a new 2D texture descriptor.
	/// @param width The width of the texture in pixels.
	/// @param height The height of the texture in pixels.
	/// @param format The pixel format of the texture.
	public this(uint32 width, uint32 height, SDL_GPUTextureFormat format)
	{
		Width = width;
		Height = height;
		Format = format;
	}

	/// @brief Converts this high-level struct to the low-level SDL struct.
	public SDL_GPUTextureCreateInfo ToSDL()
	{
		return SDL_GPUTextureCreateInfo()
			{
				width = Width, height = Height, format = Format, usage = Usage,
				type = .SDL_GPU_TEXTURETYPE_2D, layer_count_or_depth = 1,
				num_levels = 1, sample_count = .SDL_GPU_SAMPLECOUNT_1
			};
	}
}

/// @brief A descriptor for creating a GpuShader.
public struct ShaderDescriptor
{
	public List<uint8> Code;
	public SDL_GPUShaderStage Stage;
	public SDL_GPUShaderFormat Format;
	public char8* EntryPoint;

	/// @brief Creates a new shader descriptor.
	/// @param code The shader bytecode, typically loaded from a file into a List.
	/// @param stage The shader stage (e.g., Vertex or Fragment).
	/// @param format The format of the shader code (e.g., SPIR-V).
	/// @param entryPoint The name of the main function in the shader.
	public this(List<uint8> code, SDL_GPUShaderStage stage, SDL_GPUShaderFormat format = .SDL_GPU_SHADERFORMAT_SPIRV, char8* entryPoint = "main")
	{
		Code = code;
		Stage = stage;
		Format = format;
		EntryPoint = entryPoint;
	}

	/// @brief Converts this high-level struct to the low-level SDL struct.
	public SDL_GPUShaderCreateInfo ToSDL()
	{
		// Note: This syntax works for List<T> as it provides a pointer to its contiguous backing buffer.
		return SDL_GPUShaderCreateInfo()
			{
				code = &Code[0],
				code_size = (uint)Code.Count,
				format = Format,
				stage = Stage,
				entrypoint = EntryPoint
			};
	}
}