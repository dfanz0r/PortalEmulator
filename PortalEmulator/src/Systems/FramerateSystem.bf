using System;
using System.Diagnostics;
using Sizzle.Core;

namespace PortalEmulator.Systems;

static class FramerateSystem
{
	private static int mFrameCount = 0;
	private static double mTimeAccumulator = 0;

	public static void Update()
	{
		mTimeAccumulator += Time.DeltaTime;
		mFrameCount++;

		if (mTimeAccumulator >= 1.0)
		{
			Console.WriteLine($"FPS: {mFrameCount}");
			mFrameCount = 0;
			mTimeAccumulator = 0;
		}
	}
}
