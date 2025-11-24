using Sizzle.Math;
using System;

namespace Sizzle.Components;

public enum ProjectionType
{
	Perspective,
	Orthographic
}

[RegisterComponent]
public class CameraComponent : IGameComponent
{
	public ProjectionType Projection = .Perspective;

	// Perspective settings
	public float Fov = Math.PI_f / 4.0f; // 45 degrees

	// Orthographic settings
	public float OrthographicSize = 10.0f;

	// Shared settings
	public float NearPlane = 0.1f;
	public float FarPlane = 1000.0f;
	
	// This will be updated by the RenderSystem based on the window size
	public float AspectRatio = 1.777f; 

	public void OnStart() {}
	public void OnEnable() {}
	public void OnDisable() {}

	public Matrix4x4 GetProjectionMatrix()
	{
		if (Projection == .Perspective)
		{
			return Matrix4x4.PerspectiveFov(Fov, AspectRatio, NearPlane, FarPlane);
		}
		else
		{
			float height = OrthographicSize;
			float width = height * AspectRatio;
			// Assuming OrthographicSize is the full vertical size
			return Matrix4x4.Ortho(-width * 0.5f, width * 0.5f, -height * 0.5f, height * 0.5f, NearPlane, FarPlane);
		}
	}
}
