using SDL3;

namespace Sizzle.Core;

/// @brief Core initialization and cleanup functions for the Sizzle engine.
static
{
	/// @brief Initializes SDL subsystems required by the engine.
	/// @returns True if initialization succeeded, false otherwise.
	/// @remarks Must be called before creating windows or rendering.
	public static bool Init()
	{
		SDL_SetAppMetadata("Portal Emulator", "0.1", "pw.zpm.sizzle.pemu");
		return SDL_Init(.SDL_INIT_EVENTS | .SDL_INIT_VIDEO | .SDL_INIT_GAMEPAD);
	}

	/// @brief Shuts down all SDL subsystems and releases resources.
	/// @remarks Should be called before application exit.
	public static void Cleanup()
	{
		SDL_Quit();
	}
}