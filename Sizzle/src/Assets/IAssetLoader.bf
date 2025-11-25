using System;
using Sizzle.Rendering.GPU;

namespace Sizzle.Assets;

public interface IAssetLoader
{
	Result<Object> Load(String path, RenderDevice device);
	void Free(Object asset);
}
