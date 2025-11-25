using System;
using System.IO;
using Sizzle.Core;
using Sizzle.Rendering.GPU;
using SDL3_shadercross;

namespace Sizzle.Assets.Loaders;

class ShaderLoader : IAssetLoader
{
	public Result<Object> Load(String path, RenderDevice device)
	{
		String fullPath = scope .();
		Utils.GetAssetPath(fullPath, path);

		String source = scope .();
		if (File.ReadAllText(fullPath, source) case .Err)
		{
			Console.WriteLine($"Failed to read shader file: {fullPath}");
			return .Err;
		}

		SDL_ShaderCross_ShaderStage stage = .SDL_SHADERCROSS_SHADERSTAGE_VERTEX;
		if (path.EndsWith(".vert.hlsl", .OrdinalIgnoreCase))
			stage = .SDL_SHADERCROSS_SHADERSTAGE_VERTEX;
		else if (path.EndsWith(".frag.hlsl", .OrdinalIgnoreCase))
			stage = .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT;
		else if (path.EndsWith(".comp.hlsl", .OrdinalIgnoreCase))
			stage = .SDL_SHADERCROSS_SHADERSTAGE_COMPUTE;
		else
		{
			Console.WriteLine($"Could not determine shader stage from extension: {path}");
			return .Err;
		}

		// Note: We assume entry point is "main" for now.
		var shader = device.CreateShaderFromHLSL(source, stage, "main");
		if (shader == null)
			return .Err;

		return .Ok(shader);
	}

	public void Free(Object asset)
	{
		let shader = (GpuShader)asset;
		delete shader;
	}
}
