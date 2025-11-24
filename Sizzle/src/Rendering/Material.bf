using Sizzle.Rendering.GPU;

namespace Sizzle.Rendering;

public class Material
{
	public GraphicsPipeline Pipeline;

	public this(GraphicsPipeline pipeline)
	{
		Pipeline = pipeline;
	}

	public ~this()
	{
		// Material doesn't own the pipeline usually (AssetManager does), 
		// but for this simple example we assume shared ownership or external management.
	}
}
