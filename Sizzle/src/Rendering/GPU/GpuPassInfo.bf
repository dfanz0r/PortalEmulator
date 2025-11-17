using SDL3;

namespace Sizzle.Rendering.GPU;

/// @brief Describes a color render target for a render pass.
public struct ColorAttachmentInfo
{
	/// @brief The texture that will be rendered to.
	public GpuTexture Texture;

	/// @brief The mip level of the texture to render to. Defaults to 0.
	public uint32 MipLevel = 0;

	/// @brief The texture layer to render to (for array/3D/cube textures). Defaults to 0.
	public uint32 Layer = 0;

	/// @brief What to do with the texture's existing contents at the start of the pass.
	/// @details Defaults to SDL_GPU_LOADOP_CLEAR.
	public SDL_GPULoadOp LoadOp = .SDL_GPU_LOADOP_CLEAR;

	/// @brief What to do with the texture's new contents at the end of the pass.
	/// @details Defaults to SDL_GPU_STOREOP_STORE.
	public SDL_GPUStoreOp StoreOp = .SDL_GPU_STOREOP_STORE;

	/// @brief The color to clear the texture to if LoadOp is CLEAR.
	public SDL_FColor ClearColor = SDL_FColor() { r = 0.0f, g = 0.0f, b = 0.0f, a = 1.0f };

	/// @brief If true, cycles the texture if it's already in use by the GPU.
	public bool Cycle = false;

	/// @brief The destination texture for a multisample resolve operation.
	/// @details Set this if the main 'Texture' is multisampled and you want to
	/// resolve its contents to a non-multisampled texture.
	/// The StoreOp must be RESOLVE or RESOLVE_AND_STORE.
	public GpuTexture ResolveTexture = null;

	/// @brief The mip level of the ResolveTexture to write to. Defaults to 0.
	public uint32 ResolveMipLevel = 0;

	/// @brief The layer of the ResolveTexture to write to. Defaults to 0.
	public uint32 ResolveLayer = 0;

	/// @brief If true, cycles the resolve texture if it's already in use by the GPU.
	public bool CycleResolveTexture = false;

	/// @brief Converts this high-level struct to the low-level SDL struct.
	public SDL_GPUColorTargetInfo ToSDL()
	{
		return SDL_GPUColorTargetInfo()
			{
				texture = Texture.GetHandle(),
				mip_level = MipLevel,
				layer_or_depth_plane = Layer,
				load_op = LoadOp,
				store_op = StoreOp,
				clear_color = ClearColor,
				cycle = Cycle,
				resolve_texture = (ResolveTexture != null) ? ResolveTexture.GetHandle() : null,
				resolve_mip_level = ResolveMipLevel,
				resolve_layer = ResolveLayer,
				cycle_resolve_texture = CycleResolveTexture
			};
	}
}

/// @brief Describes a depth and/or stencil render target for a render pass.
public struct DepthStencilAttachmentInfo
{
	/// @brief The depth/stencil texture that will be rendered to.
	public GpuTexture Texture;

	/// @brief What to do with the depth buffer's existing contents at the start of the pass.
	/// @details Defaults to SDL_GPU_LOADOP_CLEAR.
	public SDL_GPULoadOp DepthLoadOp = .SDL_GPU_LOADOP_CLEAR;

	/// @brief What to do with the depth buffer's new contents at the end of the pass.
	/// @details Defaults to STORE. Use DONT_CARE if you don't need to read the depth buffer later.
	public SDL_GPUStoreOp DepthStoreOp = .SDL_GPU_STOREOP_STORE;

	/// @brief The value to clear the depth buffer to if DepthLoadOp is CLEAR. Defaults to 1.0.
	public float ClearDepth = 1.0f;

	/// @brief What to do with the stencil buffer's existing contents at the start of the pass.
	/// @details Defaults to DONT_CARE.
	public SDL_GPULoadOp StencilLoadOp = .SDL_GPU_LOADOP_DONT_CARE;

	/// @brief What to do with the stencil buffer's new contents at the end of the pass.
	/// @details Defaults to DONT_CARE.
	public SDL_GPUStoreOp StencilStoreOp = .SDL_GPU_STOREOP_DONT_CARE;

	/// @brief The value to clear the stencil buffer to if StencilLoadOp is CLEAR. Defaults to 0.
	public uint8 ClearStencil = 0;

	/// @brief If true, cycles the texture if it's already in use by the GPU.
	public bool Cycle = false;

	/// @brief Converts this high-level struct to the low-level SDL struct.
	public SDL_GPUDepthStencilTargetInfo ToSDL()
	{
		return SDL_GPUDepthStencilTargetInfo()
			{
				texture = Texture.GetHandle(),
				load_op = DepthLoadOp,
				store_op = DepthStoreOp,
				clear_depth = ClearDepth,
				stencil_load_op = StencilLoadOp,
				stencil_store_op = StencilStoreOp,
				clear_stencil = ClearStencil,
				cycle = Cycle
			};
	}
}