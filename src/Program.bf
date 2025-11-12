using System;
using System.IO;
using System.Interop;
using System.Collections;
using Sizzle.Math;
using Sizzle.Core;
using Sizzle.Rendering.GPU;
using SDL3;
using SDL3_shadercross;

namespace PortalEmulator;

class Program
{
	public static void Main()
	{
		SDL_Init(.SDL_INIT_VIDEO);
		defer SDL_Quit();

		if (!SDL_ShaderCross_Init())
		{
			Console.WriteLine("Failed to initialize SDL_shadercross.");
			return;
		}
		defer SDL_ShaderCross_Quit();

		var win = new Window("Sizzle Engine", 1280, 720);
		defer delete win;

		var events = new Events();
		defer delete events;

		var device = new RenderDevice();
		if (!device.Create(win))
		{
			Console.WriteLine("Could not create RenderDevice.");
			return;
		}
		defer delete device;

		// Create and Upload Vertex Buffer
		float[] vertexData = new .(
			0.0f, -0.5f,    1.0f, 0.0f, 0.0f, 1.0f,
			0.5f,  0.5f,    0.0f, 1.0f, 0.0f, 1.0f,
			-0.5f,  0.5f,    0.0f, 0.0f, 1.0f, 1.0f
			);
		defer delete vertexData;
		uint32 dataSize = (uint32)(vertexData.Count * sizeof(float));

		var vertexBuffer = device.CreateBuffer(ref BufferDescriptor(.SDL_GPU_BUFFERUSAGE_VERTEX, dataSize));
		defer delete vertexBuffer;

		var uploadBuffer = device.CreateTransferBuffer(ref BufferDescriptor(.SDL_GPU_BUFFERUSAGE_INDIRECT, dataSize));
		defer delete uploadBuffer;

		if (uploadBuffer.TryMap(false, var mappedPtr))
		{
			Internal.MemCpy(mappedPtr, &vertexData[0], dataSize);
			uploadBuffer.Unmap();
		}

		var setupCmd = device.AcquireCommandBuffer();
		defer delete setupCmd;
		setupCmd.UploadToBuffer(uploadBuffer, 0, vertexBuffer, 0, dataSize);
		setupCmd.Submit();


		// Create Shaders
		var vertSource = new String();
		defer delete vertSource;
		switch (File.ReadAllText("assets/shaders/simple.vert.hlsl", vertSource))
		{
		case .Ok: break; // Success, vertSource is now populated
		case .Err(let err):
			Console.WriteLine($"Failed to read vertex shader: {err}");
			return;
		}

		var fragSource = new String();
		defer delete fragSource;
		switch (File.ReadAllText("assets/shaders/simple.frag.hlsl", fragSource))
		{
		case .Ok: break; // Success, fragSource is now populated
		case .Err(let err):
			Console.WriteLine($"Failed to read fragment shader: {err}");
			return;
		}

		var vertShader = device.CreateShaderFromHLSL(vertSource, .SDL_SHADERCROSS_SHADERSTAGE_VERTEX);
		defer delete vertShader;

		var fragShader = device.CreateShaderFromHLSL(fragSource, .SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT);
		defer delete fragShader;

		if (vertShader == null || fragShader == null)
		{
			Console.WriteLine("Failed to create shaders from HLSL.");
			return;
		}

		// Create Graphics Pipeline
		let builder = scope GraphicsPipelineBuilder();

		var pipeline = builder
			.SetShaders(vertShader, fragShader)
			.AddVertexBuffer(0, (uint32)(6 * sizeof(float)))
			.AddVertexAttribute(0, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0)
			.AddVertexAttribute(1, 0, .SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4, (uint32)(2 * sizeof(float)))
			.AddColorTarget(SDL_GetGPUSwapchainTextureFormat(device.GetDeviceHandle(), win.GetWindowHandle()))
			.SetPrimitiveType(.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST)
			.Build(device);
		defer delete pipeline;

		if (pipeline == null)
		{
			Console.WriteLine("Failed to build graphics pipeline.");
			return;
		}

		// Main Render Loop
		while (events.Run())
		{
			{
				var cmd = device.AcquireCommandBuffer();
				defer delete cmd;

				var swapchainTexture = device.AcquireSwapchainTexture(cmd, win);
				defer delete swapchainTexture;


				if (swapchainTexture == null)
				{
					cmd.Submit();
					continue;
				}

				var colorAttachment = ColorAttachmentInfo()
					{
						Texture = swapchainTexture,
						LoadOp = .SDL_GPU_LOADOP_CLEAR,
						ClearColor = SDL_FColor() { r = 0.1f, g = 0.1f, b = 0.15f, a = 1.0f }
					};
				{
					var renderPass = cmd.BeginRenderPass(ref colorAttachment);
					defer delete renderPass;

					renderPass.BindPipeline(pipeline);
					renderPass.BindVertexBuffer(0, vertexBuffer);
					renderPass.Draw(3);
				}

				cmd.Submit();
			}
		}
	}
}