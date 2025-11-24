using Sizzle.Core;
using SDL3;
using System;

namespace PortalEmulator.Systems;

static class InputSystem
{
	private static bool vsync = true;
	private static bool vKeyWasDown = false;

	public static void Update()
	{
		int32 numKeys = 0;
		bool* state = SDL_GetKeyboardState(&numKeys);
		
		if (state[(int)SDL_Scancode.SDL_SCANCODE_ESCAPE])
		{
			Engine.Running = false;
		}

		bool vKeyDown = state[(int)SDL_Scancode.SDL_SCANCODE_V];

		if (vKeyDown && !vKeyWasDown)
		{
			vsync = !vsync;
			Engine.Device.SetVSync(Engine.Window, vsync);
			Console.WriteLine($"VSync: {vsync}");
		}
		vKeyWasDown = vKeyDown;
	}
}
