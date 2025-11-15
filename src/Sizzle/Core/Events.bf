using System;
using SDL3;

namespace Sizzle.Core;

/// @brief Event polling system for handling SDL input and window events.
public class Events
{
	/// @brief Internal SDL event structure for polling.
	private SDL_Event event = default;

	/// @brief Constructs a new event polling system.
	public this()
	{
	}

	/// @brief Processes all pending SDL events in the queue.
	/// @returns False if a quit event was received, true otherwise.
	/// @remarks Call this once per frame to handle input and window events.
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