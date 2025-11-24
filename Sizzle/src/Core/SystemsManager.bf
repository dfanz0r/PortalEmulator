using System.Collections;
using System;

namespace Sizzle.Core;

/// @brief Defines the lifecycle stages for system execution.
public enum SystemStage
{
	/// @brief Initialization stage, run once at startup.
	Setup,
	/// @brief Fixed time-step update, typically for physics.
	FixedUpdate,
	/// @brief Per-frame update logic.
	Update,
	/// @brief Post-update logic, often for rendering or camera adjustments.
	LateUpdate,
	/// @brief Cleanup stage, run once at shutdown.
	Shutdown,
	/// @brief Internal value for array sizing.
	MAX_VALUE
}

/// @brief Interface for systems that require explicit setup and shutdown phases.
public interface ISystemInit
{
	/// @brief Called during the Setup stage to initialize the system.
	static void Setup();
	/// @brief Called during the Shutdown stage to clean up resources.
	static void Shutdown();
}

typealias SystemFuncPtr = function void();

/// @brief Manages the registration and execution of system lifecycle stages.
[StaticInitPriority(99)]
static class SystemsManager
{
	private static List<SystemFuncPtr>[(int)SystemStage.MAX_VALUE] systemUpdateFunc = .();

	static this()
	{
		for (int i = 0; i < (int)SystemStage.MAX_VALUE; ++i)
		{
			systemUpdateFunc[i] = new .();
		}
	}


	static ~this()
	{
		for (int i = 0; i < (int)SystemStage.MAX_VALUE; ++i)
		{
			delete systemUpdateFunc[i];
			systemUpdateFunc[i] = null;
		}
	}

	/// @brief Registers a function to be executed during a specific stage.
	/// @param stage The lifecycle stage to attach to.
	/// @param func The function pointer to execute.
	public static void RegisterStage(SystemStage stage, SystemFuncPtr func)
	{
		systemUpdateFunc[(int)stage].Add(func);
	}

	/// @brief Registers a system type that implements ISystemInit.
	/// @details Automatically hooks up Setup and Shutdown methods to their respective stages.
	public static void RegisterSetup<T>() where T : ISystemInit
	{
		RegisterStage(SystemStage.Setup, => T.Setup);
		RegisterStage(SystemStage.Shutdown, => T.Shutdown);
	}

	/// @brief Executes all registered functions for a given stage.
	/// @param stage The stage to execute.
	/// @remarks Shutdown stage is executed in reverse registration order.
	public static void ExecuteStage(SystemStage stage)
	{
		bool reverse = stage == SystemStage.Shutdown;

		if (reverse)
		{
			// run all registered shutdown functions in reverse order
			for (int i = systemUpdateFunc[(int)stage].Count - 1; i >= 0; --i)
			{
				systemUpdateFunc[(int)stage][i]();
			}
			return;
		}
		else
		{
			// run all registered setup functions for the requested stage
			for (let func in systemUpdateFunc[(int)stage])
			{
				func();
			}
		}
	}
}