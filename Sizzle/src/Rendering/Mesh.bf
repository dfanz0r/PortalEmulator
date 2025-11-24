using System;
using System.Collections;
using Sizzle.Rendering.GPU;
using SDL3;

namespace Sizzle.Rendering;

public class Mesh
{
	public GpuBuffer VertexBuffer;
	public GpuBuffer IndexBuffer;
	public uint32 VertexCount;
	public uint32 IndexCount;

	private List<uint8> mVertexData = new .() ~ delete _;
	private List<uint8> mIndexData = new .() ~ delete _;

	public this()
	{
	}

	public ~this()
	{
		if (VertexBuffer != null) delete VertexBuffer;
		if (IndexBuffer != null) delete IndexBuffer;
	}

	public void SetVertices<T>(T[] vertices) where T : struct
	{
		mVertexData.Clear();
		mVertexData.AddRange(Span<uint8>((uint8*)vertices.Ptr, vertices.Count * sizeof(T)));
		VertexCount = (uint32)vertices.Count;
	}

	public void SetIndices(uint16[] indices)
	{
		mIndexData.Clear();
		mIndexData.AddRange(Span<uint8>((uint8*)indices.Ptr, indices.Count * sizeof(uint16)));
		IndexCount = (uint32)indices.Count;
	}

	public void Upload(RenderDevice device)
	{
		if (mVertexData.Count == 0 || mIndexData.Count == 0) return;

		uint32 vertexDataSize = (uint32)mVertexData.Count;
		uint32 indexDataSize = (uint32)mIndexData.Count;

		// Create Buffers
		VertexBuffer = device.CreateBuffer(ref BufferDescriptor(.SDL_GPU_BUFFERUSAGE_VERTEX, vertexDataSize));
		IndexBuffer = device.CreateBuffer(ref BufferDescriptor(.SDL_GPU_BUFFERUSAGE_INDEX, indexDataSize));

		// Upload Data
		var transferBuffer = device.CreateTransferBuffer(ref BufferDescriptor(.SDL_GPU_BUFFERUSAGE_INDIRECT, vertexDataSize + indexDataSize));
		defer delete transferBuffer;

		if (transferBuffer.TryMap(false, var mappedPtr))
		{
			Internal.MemCpy(mappedPtr, mVertexData.Ptr, vertexDataSize);
			Internal.MemCpy((uint8*)mappedPtr + vertexDataSize, mIndexData.Ptr, indexDataSize);
			transferBuffer.Unmap();
		}

		var setupCmd = device.AcquireCommandBuffer();
		setupCmd.UploadToBuffer(transferBuffer, 0, VertexBuffer, 0, vertexDataSize);
		setupCmd.UploadToBuffer(transferBuffer, vertexDataSize, IndexBuffer, 0, indexDataSize);
		setupCmd.Submit();
		delete setupCmd;
	}
}
