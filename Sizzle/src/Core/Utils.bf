using System;
using System.IO;

namespace Sizzle.Core;

public static class Utils
{
	// TODO - Need to build out the AssetManager that will manage asset lifetimes
	// Asset manager will support "plugins" that will take in an asset type
	// then accept the disk data and transform it to a runtime useful format
	public static void GetAssetPath(String outString)
	{
		String executableDirectory = scope String(256);
		Environment.GetExecutableFilePath(executableDirectory);
		Path.GetDirectoryPath(executableDirectory, outString);
	}

	public static void GetAssetPath(String outString, String assetPath)
	{
		String tmpStr = scope String(256);

		GetAssetPath(tmpStr);
		Path.Combine(outString, tmpStr, "assets", assetPath);

		outString.Replace('/', Path.DirectorySeparatorChar);
		outString.Replace('\\', Path.DirectorySeparatorChar);
	}
}