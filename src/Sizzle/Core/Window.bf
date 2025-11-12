using SDL3;
using System.Threading;
using System;
using Sizzle.Math;

namespace Sizzle.Core;

/// @brief testing
public class Window
{
	private static int MainThreadId = Thread.CurrentThreadId;

	private SDL_Window* windowHandle;

	/// @brief testing
	public this(String title, int32 width, int32 height)
	{
		windowHandle = SDL_CreateWindow(title.CStr(), width, height, .SDL_WINDOW_RESIZABLE);
	}

	public String Title
	{
		get => new String(SDL_GetWindowTitle(windowHandle) ?? "");
		set => SDL_SetWindowTitle(windowHandle, value.CStr());
	}

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

	public SDL_Window* GetWindowHandle()
	{
		return windowHandle;
	}

	public ~this()
	{
		SDL_DestroyWindow(windowHandle);
	}

}