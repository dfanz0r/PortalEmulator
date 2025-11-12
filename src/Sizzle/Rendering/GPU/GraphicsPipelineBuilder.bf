using System;
using System.Collections;
using SDL3;

namespace Sizzle.Rendering.GPU;

/// @brief A helper class to construct a GpuGraphicsPipeline in a readable, fluent way.
/// @details This builder simplifies the creation of complex pipeline state objects by
/// providing a step-by-step interface with sensible defaults.
public class GraphicsPipelineBuilder
{
	private GpuShader mVertexShader;
	private GpuShader mFragmentShader;
	private List<SDL_GPUVertexBufferDescription> mVertexBindings = new .() ~ delete _;
	private List<SDL_GPUVertexAttribute> mVertexAttributes = new .() ~ delete _;
	private List<SDL_GPUColorTargetDescription> mColorTargetDescriptions = new .() ~ delete _;
	private SDL_GPUPrimitiveType mPrimitiveType = .SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
	private SDL_GPURasterizerState mRasterizerState = SDL_GPURasterizerState() { fill_mode = .SDL_GPU_FILLMODE_FILL, cull_mode = .SDL_GPU_CULLMODE_BACK, front_face = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE };
	private SDL_GPUMultisampleState mMultisampleState = SDL_GPUMultisampleState() { sample_count = .SDL_GPU_SAMPLECOUNT_1 };
	private SDL_GPUDepthStencilState mDepthStencilState = SDL_GPUDepthStencilState() { enable_depth_test = false, enable_depth_write = false, compare_op = .SDL_GPU_COMPAREOP_LESS_OR_EQUAL };
	private SDL_GPUTextureFormat mDepthStencilFormat = .SDL_GPU_TEXTUREFORMAT_INVALID;

	/// @brief Creates a new GraphicsPipelineBuilder with default settings.
	public this() { }

	/// @brief Sets the vertex and fragment shaders for the pipeline.
	/// @param vertexShader The vertex shader to use.
	/// @param fragmentShader The fragment shader to use.
	/// @return The builder instance for chaining.
	public Self SetShaders(GpuShader vertexShader, GpuShader fragmentShader)
	{
		mVertexShader = vertexShader;
		mFragmentShader = fragmentShader;
		return this;
	}

	/// @brief Adds a description of a vertex buffer binding.
	/// @param slot The binding slot for this buffer (corresponds to buffer_slot in AddVertexAttribute).
	/// @param pitch The byte stride between consecutive vertices in the buffer.
	/// @param inputRate Whether the buffer is per-vertex or per-instance data.
	/// @return The builder instance for chaining.
	public Self AddVertexBuffer(uint32 slot, uint32 pitch, SDL_GPUVertexInputRate inputRate = .SDL_GPU_VERTEXINPUTRATE_VERTEX)
	{
		mVertexBindings.Add(SDL_GPUVertexBufferDescription() { slot = slot, pitch = pitch, input_rate = inputRate });
		return this;
	}

	/// @brief Adds a description of a single vertex attribute.
	/// @param location The shader input location for this attribute (e.g., layout(location=X)).
	/// @param bufferSlot The slot of the vertex buffer this attribute resides in.
	/// @param format The data format of the attribute (e.g., FLOAT2 for a vec2).
	/// @param offset The byte offset of this attribute from the start of the vertex.
	/// @return The builder instance for chaining.
	public Self AddVertexAttribute(uint32 location, uint32 bufferSlot, SDL_GPUVertexElementFormat format, uint32 offset)
	{
		mVertexAttributes.Add(SDL_GPUVertexAttribute() { location = location, buffer_slot = bufferSlot, format = format, offset = offset });
		return this;
	}

	/// @brief Adds a description for a color render target that this pipeline is compatible with.
	/// @param format The pixel format of the color target.
	public Self AddColorTarget(SDL_GPUTextureFormat format)
	{
		var defaultBlendState = SDL_GPUColorTargetBlendState() { enable_blend = false };
		mColorTargetDescriptions.Add(SDL_GPUColorTargetDescription() { format = format, blend_state = defaultBlendState });
		return this;
	}

	/// @brief Adds a description for a color render target with a custom blend state.
	/// @param format The pixel format of the color target.
	/// @param blendState The blend state for this target.
	public Self AddColorTarget(SDL_GPUTextureFormat format, in SDL_GPUColorTargetBlendState blendState)
	{
		mColorTargetDescriptions.Add(SDL_GPUColorTargetDescription() { format = format, blend_state = blendState });
		return this;
	}

	/// @brief Sets the primitive topology for the pipeline's input assembler.
	/// @param type The type of primitive to draw (e.g., triangle lists, line strips).
	/// @return The builder instance for chaining.
	public Self SetPrimitiveType(SDL_GPUPrimitiveType type)
	{
		mPrimitiveType = type;
		return this;
	}

	/// @brief Configures the rasterizer state.
	/// @param cullMode The face culling mode.
	/// @param fillMode The polygon fill mode (e.g., solid or wireframe).
	/// @param frontFace The vertex winding order that determines the front face.
	/// @return The builder instance for chaining.
	public Self SetRasterizerState(SDL_GPUCullMode cullMode, SDL_GPUFillMode fillMode = .SDL_GPU_FILLMODE_FILL, SDL_GPUFrontFace frontFace = .SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE)
	{
		mRasterizerState.cull_mode = cullMode;
		mRasterizerState.fill_mode = fillMode;
		mRasterizerState.front_face = frontFace;
		return this;
	}

	/// @brief Configures the depth testing state and the format of the depth buffer.
	/// @param format The pixel format of the depth/stencil texture this pipeline will render to.
	/// @param writeEnabled If true, the pipeline will write new depth values to the buffer.
	/// @param compareOp The comparison function to use for the depth test.
	/// @return The builder instance for chaining.
	public Self SetDepthState(SDL_GPUTextureFormat format, bool writeEnabled = true, SDL_GPUCompareOp compareOp = .SDL_GPU_COMPAREOP_LESS_OR_EQUAL)
	{
		mDepthStencilState.enable_depth_test = true;
		mDepthStencilState.enable_depth_write = writeEnabled;
		mDepthStencilState.compare_op = compareOp;
		mDepthStencilFormat = format;
		return this;
	}

	/// @brief Assembles the final GpuGraphicsPipeline object from the configured state.
	/// @param device The RenderDevice used to create the pipeline resource.
	/// @return The newly created GpuGraphicsPipeline.
	public GraphicsPipeline Build(RenderDevice device)
	{
		if (mVertexShader == null || mFragmentShader == null)
		{
			Console.WriteLine("GraphicsPipelineBuilder Error: Shaders must be set.");
			return null;
		}

		var createInfo = SDL_GPUGraphicsPipelineCreateInfo()
			{
				vertex_shader = mVertexShader.GetHandle(),
				fragment_shader = mFragmentShader.GetHandle(),
				vertex_input_state = SDL_GPUVertexInputState()
					{
						vertex_buffer_descriptions = &mVertexBindings[0],
						num_vertex_buffers = (uint32)mVertexBindings.Count,
						vertex_attributes = &mVertexAttributes[0],
						num_vertex_attributes = (uint32)mVertexAttributes.Count
					},
				primitive_type = mPrimitiveType,
				rasterizer_state = mRasterizerState,
				multisample_state = mMultisampleState,
				depth_stencil_state = mDepthStencilState,
				target_info = SDL_GPUGraphicsPipelineTargetInfo()
					{
						color_target_descriptions = &mColorTargetDescriptions[0],
						num_color_targets = (uint32)mColorTargetDescriptions.Count,
						depth_stencil_format = mDepthStencilFormat,
						has_depth_stencil_target = (mDepthStencilFormat != .SDL_GPU_TEXTUREFORMAT_INVALID)
					}
			};
		return new GraphicsPipeline(device, ref createInfo);
	}
}