using Sizzle.Entities;
using Sizzle.Math;
using Sizzle.Core;
using SDL3;
using System;
using Sizzle.Components;

namespace PortalEmulator.Components;

[RegisterComponent]
public class CameraControllerComponent : IUpdatableComponent
{
	public float MoveSpeed = 10.0f;
	public float MouseSensitivity = 0.003f;

	private float mYaw = 0.0f;
	private float mPitch = 0.0f;

	public void OnStart() { }
	public void OnEnable() { }
	public void OnDisable() { }

	public void OnFixedUpdate() { }

	public void OnUpdate()
	{
		// Mouse Look
		float mouseX = 0, mouseY = 0;
		SDL_GetRelativeMouseState(&mouseX, &mouseY);

		if (mouseX != 0 || mouseY != 0)
		{
			mYaw -= mouseX * MouseSensitivity;
			mPitch += mouseY * MouseSensitivity;

			// Clamp pitch
			mPitch = Math.Clamp(mPitch, -Math.PI_f / 2.0f + 0.1f, Math.PI_f / 2.0f - 0.1f);
		}

		Quaternion rotation = Quaternion.FromYawPitchRoll(mYaw, mPitch, 0.0f);

		// Keyboard Move
		Vector3 moveDir = .Zero;
		int32 numKeys = 0;
		bool* state = SDL_GetKeyboardState(&numKeys);

		if (state[(int)SDL_Scancode.SDL_SCANCODE_W]) moveDir.z += 1.0f;
		if (state[(int)SDL_Scancode.SDL_SCANCODE_S]) moveDir.z -= 1.0f;
		if (state[(int)SDL_Scancode.SDL_SCANCODE_A]) moveDir.x -= 1.0f;
		if (state[(int)SDL_Scancode.SDL_SCANCODE_D]) moveDir.x += 1.0f;
		if (state[(int)SDL_Scancode.SDL_SCANCODE_SPACE]) moveDir.y += 1.0f;
		if (state[(int)SDL_Scancode.SDL_SCANCODE_LSHIFT]) moveDir.y -= 1.0f;

		// Get Transform
		var graph = EntityGraph.GetOrCreate(0);
		Transform3D transform;
		if (graph.TryGetComponent<Transform3D>(GetEntityId(), out transform))
		{
			transform.Rotation = rotation;

			if (moveDir != .Zero)
			{
				// Normalize if moving diagonally
				if (moveDir.SquaredMagnitude() > 1.0f)
					moveDir = moveDir.Normalized();

				// Fly mode: Move relative to camera orientation
				Vector3 forward = rotation.Rotate(Vector3.Forward);
				Vector3 right = rotation.Rotate(Vector3.Right);
				Vector3 up = Vector3.Up; // Global Up for vertical movement

				// W/S moves along forward vector
				// A/D moves along right vector
				// Space/Shift moves along global Up

				Vector3 velocity = (forward * moveDir.z + right * moveDir.x + up * moveDir.y) * MoveSpeed * (float)Time.DeltaTime;
				transform.Position += velocity;
			}

			transform.MarkDirty();
		}
	}
}
