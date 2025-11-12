using System;
using SDL3;

namespace Sizzle.Core;

public class Events
{
	private SDL_Event event = default;

	public this()
	{
	}

	public bool Run()
	{
		SDL_PumpEvents();

		while (SDL_PollEvent(&event))
		{
			if (event.type == (uint32)SDL_EventType.SDL_EVENT_QUIT)
			{
				Console.WriteLine("Quitting!");
				return false;
			}
		}
		return true;
	}
}