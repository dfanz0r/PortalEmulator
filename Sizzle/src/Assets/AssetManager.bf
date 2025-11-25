using System;
using System.Collections;
using Sizzle.Core;
using Sizzle.Rendering.GPU;
using Sizzle.Assets.Loaders;
using Sizzle.Rendering;

namespace Sizzle.Assets;

static class AssetManager : ISystemInit
{
	private static Dictionary<Type, IAssetLoader> mLoaders = new .() ~ delete _;
	private static Dictionary<String, Object> mCache = new .() ~ delete _;

	public static void Setup()
	{
		RegisterLoader<GpuShader>(new ShaderLoader());
		RegisterLoader<Mesh>(new MeshLoader());
	}

	public static void Shutdown()
	{
		for (var kv in mCache)
		{
			let type = kv.value.GetType();
			IAssetLoader loader = null;
			if (mLoaders.TryGetValue(type, out loader))
			{
				loader.Free(kv.value);
			}
		}
		mCache.Clear();

		for (var kv in mLoaders)
			delete kv.value;
		mLoaders.Clear();
	}

	public static void RegisterLoader<T>(IAssetLoader loader)
	{
		mLoaders[typeof(T)] = loader;
	}

	public static T Load<T>(String path) where T : class
	{
		Object cachedAsset = null;
		if (mCache.TryGetValue(path, out cachedAsset))
		{
			return (T)cachedAsset;
		}

		IAssetLoader loader = null;
		if (!mLoaders.TryGetValue(typeof(T), out loader))
		{
			Runtime.FatalError(scope $"No loader registered for type {typeof(T)}");
		}

		switch (loader.Load(path, Engine.Device))
		{
		case .Ok(var asset):
			mCache[path] = asset;
			return (T)asset;
		case .Err:
			return null;
		}
	}
}
