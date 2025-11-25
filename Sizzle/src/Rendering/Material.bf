using Sizzle.Rendering.GPU;
using Sizzle.Math;

namespace Sizzle.Rendering;

public class Material
{
	public GraphicsPipeline Pipeline;
	public bool IsTransparent = false;
	public int32 SortOrder = 0;

	public Vector3 Albedo = .(1, 1, 1);
	public float Metallic = 0.0f;
	public float Roughness = 0.5f;
	public Vector3 Emissive = .(0, 0, 0);

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
