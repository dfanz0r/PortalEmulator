using SDL3;

namespace Sizzle.Core;

static
{
	// Initialize Core
	public static bool Init()
	{
		SDL_SetAppMetadata("Portal Emulator", "0.1", "pw.zpm.sizzle.pemu");
		return SDL_Init(.SDL_INIT_EVENTS | .SDL_INIT_VIDEO | .SDL_INIT_GAMEPAD);
	}

	// Clean up Core
	public static void Cleanup()
	{
		SDL_Quit();
	}
}