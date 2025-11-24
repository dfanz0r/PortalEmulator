using System;
using System.Diagnostics;

namespace PortalEmulator;

class FramerateCounter
{
	private Stopwatch mStopwatch = new .() ~ delete _;
	private int mFrameCount = 0;
	private double mTimeAccumulator = 0;

	public this()
	{
		mStopwatch.Start();
	}

	public void Update()
	{
		double dt = mStopwatch.Elapsed.TotalSeconds;
		mStopwatch.Restart();

		mTimeAccumulator += dt;
		mFrameCount++;

		if (mTimeAccumulator >= 1.0)
		{
			Console.WriteLine($"FPS: {mFrameCount}");
			mFrameCount = 0;
			mTimeAccumulator = 0;
		}
	}
}
