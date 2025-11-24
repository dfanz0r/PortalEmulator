using Sizzle.Core;
using SDL3_shadercross;
using PortalEmulator.Systems;

namespace PortalEmulator;

class Program
{
	public static void Main()
	{
		Engine.Init("Sizzle Engine", 1280, 720);

		SystemsManager.RegisterSetup<GameSystem>();

		Engine.Run();
	}
}
