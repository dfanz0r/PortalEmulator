using Sizzle.Core;
using Sizzle.Entities;

using System;

namespace Sizzle.Entities;

static class ComponentUpdateSystem : ISystemInit
{
	public static void Setup()
	{
		SystemsManager.RegisterStage(.Update, => Update);
		SystemsManager.RegisterStage(.FixedUpdate, => FixedUpdate);
	}

	public static void Shutdown()
	{
	}

	public static void Update()
	{
		for (var reg in ComponentSystem.Registries)
		{
			reg.UpdateAll();
		}
	}

	public static void FixedUpdate()
	{
		for (var reg in ComponentSystem.Registries)
		{
			reg.FixedUpdateAll();
		}
	}
}
