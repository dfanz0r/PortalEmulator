using Sizzle.Rendering.GPU;
using Sizzle.Rendering;
using Sizzle.Entities;
using Sizzle.Assets;
using System;
using System.Diagnostics;
using SDL3_shadercross;

namespace Sizzle.Core;

static class Engine
{
	public static Window Window;
	public static RenderDevice Device;
	public static Events Events;
	public static bool Running = true;

	public static void Init(String title, int32 width, int32 height)
	{
		if (!SDL_ShaderCross_Init())
		{
			Runtime.FatalError("Could not initialize SDL_ShaderCross.");
		}

		Window = new Window(title, width, height);
		Events = new Events();
		Device = new RenderDevice();
		if (!Device.Create(Window))
		{
			Runtime.FatalError("Could not create RenderDevice.");
		}

		SystemsManager.RegisterSetup<AssetManager>();
		SystemsManager.RegisterSetup<ComponentSystem>();
		SystemsManager.RegisterSetup<EntityGraph>();
		SystemsManager.RegisterSetup<ComponentUpdateSystem>();
	}

	public static void Run()
	{
		SystemsManager.ExecuteStage(.Setup);

		let stopwatch = scope Stopwatch();
		stopwatch.Start();

		double accumulator = 0;

		while (Running && Events.Run())
		{
			double frameTime = stopwatch.Elapsed.TotalSeconds;
			stopwatch.Restart();

			// Cap frame time to avoid spiral of death
			if (frameTime > 0.25) frameTime = 0.25;

			Time.DeltaTime = frameTime;
			Time.TotalTime += frameTime;
			accumulator += frameTime;

			while (accumulator >= Time.FixedDeltaTime)
			{
				SystemsManager.ExecuteStage(.FixedUpdate);
				accumulator -= Time.FixedDeltaTime;
			}

			SystemsManager.ExecuteStage(.Update);
			SystemsManager.ExecuteStage(.LateUpdate);
		}

		SystemsManager.ExecuteStage(.Shutdown);
		
		delete Device;
		delete Events;
		delete Window;

		SDL_ShaderCross_Quit();
	}
}
