using SDL3;
using System.Threading;
using System;
using Sizzle.Math;

namespace Sizzle.Core;

/// @brief Manages an SDL window for rendering and user interaction.
/// @remarks Automatically creates and destroys the underlying SDL window resource.
public class Window
{
	/// @brief Thread ID where the window was created (for thread-safety validation).
	private static int MainThreadId = Thread.CurrentThreadId;

	/// @brief The underlying SDL window handle.
	private SDL_Window* windowHandle;

	/// @brief Creates a new resizable window with the specified dimensions.
	/// @param title The window title displayed in the title bar.
	/// @param width Initial width in pixels.
	/// @param height Initial height in pixels.
	public this(String title, int32 width, int32 height)
	{
		windowHandle = SDL_CreateWindow(title.CStr(), width, height, .SDL_WINDOW_RESIZABLE);
	}

	/// @brief Gets or sets the window title.
	/// @remarks Allocates a new string when getting the title.
	public String Title
	{
		get => new String(SDL_GetWindowTitle(windowHandle) ?? "");
		set => SDL_SetWindowTitle(windowHandle, value.CStr());
	}

	/// @brief Gets or sets the window dimensions in pixels.
	public Vector2Int Size
	{
		get
		{
			var size = Vector2Int(0, 0);
			SDL_GetWindowSize(windowHandle, &size.x, &size.y);
			return size;
		}

#unwarn
		set mut // this does mutate SDL's state
		{
			SDL_SetWindowSize(windowHandle, value.x, value.y);
		}
	}

	/// @brief Returns the underlying SDL window handle for advanced operations.
	public SDL_Window* GetWindowHandle()
	{
		return windowHandle;
	}

	/// @brief Destroys the SDL window and releases associated resources.
	public ~this()
	{
		SDL_DestroyWindow(windowHandle);
	}

}