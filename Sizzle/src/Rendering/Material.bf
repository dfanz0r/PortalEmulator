using Sizzle.Rendering.GPU;

namespace Sizzle.Rendering;

public class Material
{
	public GraphicsPipeline Pipeline;
	public bool IsTransparent = false;
	public int32 SortOrder = 0;

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
