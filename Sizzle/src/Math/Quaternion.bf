using System;
using Sizzle.Core;

namespace Sizzle.Math;


/// @brief Default float quaternion type
typealias Quaternion = Quaternion<float>;

/// @brief Represents a quaternion used for 3D rotations.
[Union, CRepr]
struct Quaternion<T> : IEquatable<Self>, IHashable
	where T :
	operator T + T,
	operator T - T,
	operator T * T,
	operator T / T,
	operator T % T,
	operator - T,
	operator ++ T,
	operator -- T,
	operator explicit double,
	IHashable
	where double : operator explicit T
	where double : operator implicit T
	where int : operator T <=> T
{
	/// @brief Returns a pointer to the first component.
	public void* AsPtr() mut => &elements[0];
	/// @brief Number of scalar components contained in the quaternion.
	public const int ElementCount = 4;

	/// @brief Raw component storage shared by all accessor views.
	public T[ElementCount] elements;
	/// @brief Provides individual component accessors (x, y, z, w).
	public struct
	{
		/// @brief X component of the imaginary axis.
		public T x;
		/// @brief Y component of the imaginary axis.
		public T y;
		/// @brief Z component of the imaginary axis.
		public T z;
		/// @brief W component representing the scalar part.
		public T w;
	};
	/// @brief Provides combined vector/scalar accessors.
	public struct
	{
		/// @brief Vector (imaginary) portion of the rotation.
		public Vector3<T> vector;
		/// @brief Scalar portion of the rotation.
		public T scalar;
	};

	/// @brief Creates a copy of another quaternion.
	/// @param other Source quaternion.
	public this(in Self other)
	{
		this.x = other.x;
		this.y = other.y;
		this.z = other.z;
		this.w = other.w;
	}

	/// @brief Creates a quaternion from explicit components.
	/// @param x X component of the imaginary axis.
	/// @param y Y component of the imaginary axis.
	/// @param z Z component of the imaginary axis.
	/// @param w W component (scalar part).
	public this(T x, T y, T z, T w)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	/// @brief Creates a quaternion from an array of four values.
	/// @param values Source array whose first four elements populate the quaternion.
	public this(T[4] values)
	{
		this.x = values[0];
		this.y = values[1];
		this.z = values[2];
		this.w = values[3];
	}

	/// @brief Creates a quaternion from an imaginary vector and scalar.
	/// @param vector Imaginary components (X,Y,Z).
	/// @param scalar Scalar component (W).
	public this(in Vector3<T> vector, T scalar)
	{
		this.vector = vector;
		this.scalar = scalar;
	}

	/// @brief Creates a quaternion representing a rotation around an axis.
	/// @param axis Rotation axis (assumed non-zero).
	/// @param angle Angle in radians.
	public static Self FromAxisAngle(in Vector3<T> axis, T angle)
	{
		var axisNorm = axis.Normalized();
		double halfAngle = (double)angle * 0.5;
		double sinHalf = Math.Sin(halfAngle);
		double cosHalf = Math.Cos(halfAngle);
		return .(
			(T)((double)axisNorm.x * sinHalf),
			(T)((double)axisNorm.y * sinHalf),
			(T)((double)axisNorm.z * sinHalf),
			(T)cosHalf
			);
	}

	/// @brief Creates a quaternion from Euler angles (intrinsic XYZ order).
	/// @param radians Euler angles in radians applied as roll (X), pitch (Y), then yaw (Z).
	public static Self FromEulerRadians(in Vector3<T> radians)
	{
		double hx = (double)radians.x * 0.5;
		double hy = (double)radians.y * 0.5;
		double hz = (double)radians.z * 0.5;

		double sx = Math.Sin(hx);
		double cx = Math.Cos(hx);
		double sy = Math.Sin(hy);
		double cy = Math.Cos(hy);
		double sz = Math.Sin(hz);
		double cz = Math.Cos(hz);

		return .(
			(T)(sx * cy * cz - cx * sy * sz),
			(T)(cx * sy * cz + sx * cy * sz),
			(T)(cx * cy * sz - sx * sy * cz),
			(T)(cx * cy * cz + sx * sy * sz)
			);
	}

	/// @brief Creates a quaternion from yaw (Y), pitch (X), and roll (Z) angles.
	/// @param yaw Rotation about the Y axis in radians.
	/// @param pitch Rotation about the X axis in radians.
	/// @param roll Rotation about the Z axis in radians.
	public static Self FromYawPitchRoll(T yaw, T pitch, T roll)
	{
		// FromEulerRadians expects components in roll(X), pitch(Y), yaw(Z) order.
		return FromEulerRadians(Vector3<T>(pitch, yaw, roll));
	}

	/// @brief Converts this quaternion into intrinsic XYZ Euler angles in radians.
	/// @returns Vector of roll (X), pitch (Y), and yaw (Z) angles in radians in ranges [-π, π], [-π/2, π/2], [-π, π].
	public Vector3<T> ToEulerRadians()
	{
		double qx = (double)x;
		double qy = (double)y;
		double qz = (double)z;
		double qw = (double)w;

		double two = 2.0;

		double sinp = two * (qw * qy - qz * qx);
		const double limit = 1.0 - 1e-10;
		double pitch;
		double roll;
		double yaw;

		if (Math.Abs(sinp) >= limit)
		{
			double halfPi = Math.PI_d * 0.5;
			pitch = Math.Sign(sinp) * halfPi;

			double delta = 2.0 * Math.Atan2(qx, qw);
			if (delta > Math.PI_d)
				delta -= Math.PI_d * 2.0;
			else if (delta < -Math.PI_d)
				delta += Math.PI_d * 2.0;

			// Preserve the original orientation by folding the unconstrained axis into a single angle.
			if (sinp > 0.0)
			{
				roll = delta;
				yaw = 0.0;
			}
			else
			{
				roll = 0.0;
				yaw = delta;
			}
		}
		else
		{
			pitch = Math.Asin(sinp);
			double sinr_cosp = two * (qw * qx + qy * qz);
			double cosr_cosp = 1.0 - two * (qx * qx + qy * qy);
			roll = Math.Atan2(sinr_cosp, cosr_cosp);

			double siny_cosp = two * (qw * qz + qx * qy);
			double cosy_cosp = 1.0 - two * (qy * qy + qz * qz);

			yaw = Math.Atan2(siny_cosp, cosy_cosp);
		}

		return Vector3<T>((T)roll, (T)pitch, (T)yaw);
	}

	/// @brief Creates a quaternion from a 3x3 rotation matrix.
	/// @param m Source 3x3 rotation matrix.
	public static Self FromMatrix(in Matrix3x3<T> m)
	{
		double m00 = (double)m.x.x;
		double m11 = (double)m.y.y;
		double m22 = (double)m.z.z;
		double trace = m00 + m11 + m22;

		if (trace > 0.0)
		{
			double s = Math.Sqrt(trace + 1.0) * 2.0;
			double inv = 1.0 / s;
			return .(
				(T)(((double)m.y.z - (double)m.z.y) * inv),
				(T)(((double)m.z.x - (double)m.x.z) * inv),
				(T)(((double)m.x.y - (double)m.y.x) * inv),
				(T)(0.25 * s)
				);
		}

		if (m00 > m11 && m00 > m22)
		{
			double s = Math.Sqrt(1.0 + m00 - m11 - m22) * 2.0;
			double inv = 1.0 / s;
			return .(
				(T)(0.25 * s),
				(T)(((double)m.x.y + (double)m.y.x) * inv),
				(T)(((double)m.x.z + (double)m.z.x) * inv),
				(T)(((double)m.y.z - (double)m.z.y) * inv)
				);
		}
		else if (m11 > m22)
		{
			double s = Math.Sqrt(1.0 + m11 - m00 - m22) * 2.0;
			double inv = 1.0 / s;
			return .(
				(T)(((double)m.x.y + (double)m.y.x) * inv),
				(T)(0.25 * s),
				(T)(((double)m.y.z + (double)m.z.y) * inv),
				(T)(((double)m.z.x - (double)m.x.z) * inv)
				);
		}
		else
		{
			double s = Math.Sqrt(1.0 + m22 - m00 - m11) * 2.0;
			double inv = 1.0 / s;
			return .(
				(T)(((double)m.x.z + (double)m.z.x) * inv),
				(T)(((double)m.y.z + (double)m.z.y) * inv),
				(T)(0.25 * s),
				(T)(((double)m.x.y - (double)m.y.x) * inv)
				);
		}
	}

	/// @brief Creates a quaternion from a 3x4 affine matrix (ignoring translation).
	/// @param m Source 3x4 affine matrix.
	public static Self FromMatrix(in Matrix3x4<T> m)
	{
		return FromMatrix(Matrix3x3<T>(m));
	}

	/// @brief Creates a quaternion from a 4x4 matrix (ignoring translation).
	/// @param m Source 4x4 matrix.
	public static Self FromMatrix(in Matrix4x4<T> m)
	{
		return FromMatrix(Matrix3x3<T>(m));
	}

	/// @brief Converts this quaternion to a rotation-only 3x3 matrix.
	/// @returns A 3x3 matrix whose rotation matches this quaternion.
	public Matrix3x3<T> ToMatrix3x3()
	{
		double xx = (double)x * (double)x;
		double yy = (double)y * (double)y;
		double zz = (double)z * (double)z;
		double xy = (double)x * (double)y;
		double xz = (double)x * (double)z;
		double yz = (double)y * (double)z;
		double wx = (double)w * (double)x;
		double wy = (double)w * (double)y;
		double wz = (double)w * (double)z;

		double two = 2.0;

		return Matrix3x3<T>(
			Vector3<T>((T)(1.0 - two * (yy + zz)), (T)(two * (xy + wz)), (T)(two * (xz - wy))),
			Vector3<T>((T)(two * (xy - wz)), (T)(1.0 - two * (xx + zz)), (T)(two * (yz + wx))),
			Vector3<T>((T)(two * (xz + wy)), (T)(two * (yz - wx)), (T)(1.0 - two * (xx + yy)))
			);
	}

	/// @brief Converts this quaternion to a rotation-only 3x4 matrix.
	/// @returns A 3x4 matrix whose rotation matches this quaternion. Translation is zero.
	public Matrix3x4<T> ToMatrix3x4()
	{
		var m3 = ToMatrix3x3();
		return Matrix3x4<T>(m3.x, m3.y, m3.z, Vector3<T>((T)0, (T)0, (T)0));
	}

	/// @brief Converts this quaternion to a rotation-only 4x4 matrix.
	/// @returns A 4x4 matrix whose rotation matches this quaternion. Translation is zero.
	public Matrix4x4<T> ToMatrix4x4()
	{
		var m3 = ToMatrix3x4();
		return Matrix4x4<T>(m3);
	}

	/// @brief Computes the dot product between two quaternions.
	/// @param rhs Second operand.
	/// @returns Scalar dot product value.
	[Inline]
	public T DotProduct(in Self rhs) => x * rhs.x + y * rhs.y + z * rhs.z + w * rhs.w;

	/// @brief Computes the squared length (norm) of the quaternion.
	/// @returns Squared magnitude.
	[Inline]
	public T SquaredMagnitude() => DotProduct(this);

	/// @brief Computes the magnitude (norm) of the quaternion.
	/// @returns Euclidean length.
	[Inline]
	public T Magnitude()
	{
		double val = (double)SquaredMagnitude();
		return (T)Math.Sqrt(val);
	}

	/// @brief Returns a normalized copy of this quaternion.
	/// @returns Unit quaternion or Zero if the magnitude is zero.
	public Self Normalized()
	{
		T sqrMag = SquaredMagnitude();

		if (sqrMag == default)
			return Zero;

		double invLen = 1.0 / Math.Sqrt((double)sqrMag);
		T scale = (T)invLen;

		return .(x * scale, y * scale, z * scale, w * scale);
	}

	/// @brief Returns the conjugate of this quaternion.
	/// @returns Conjugated quaternion (negated imaginary part).
	[Inline]
	public Self Conjugated() => .(-x, -y, -z, w);

	/// @brief Returns the inverse of this quaternion.
	/// @returns Quaternion inverse, or Zero if the magnitude is zero.
	public Self Inverted()
	{
		T sqrMag = SquaredMagnitude();
		if (sqrMag == default)
			return Zero;
		Self conj = Conjugated();
		T inv = (T)(1.0 / (double)sqrMag);
		return conj * inv;
	}

	/// @brief Rotates a vector by this quaternion.
	/// @param v Vector to rotate.
	/// @returns Rotated vector.
	[Inline]
	public Vector3<T> Rotate(in Vector3<T> v)
	{
		Vector3<T> qVec = Vector3<T>(x, y, z);
		Vector3<T> uv = qVec.CrossProduct(v);
		Vector3<T> uuv = qVec.CrossProduct(uv);
		T two = (T)2;
		return v + (uv * w + uuv) * two;
	}

	/// @brief Linearly interpolates between two quaternions.
	/// @param target Target quaternion.
	/// @param t Blend factor where 0 returns this quaternion and 1 returns the target.
	/// @returns Normalized linear interpolation.
	[Inline]
	public Self Lerp(in Self target, T t)
	{
		return (this + (target - this) * t).Normalized();
	}

	/// @brief Performs spherical-linear interpolation between two quaternions.
	/// @param target Target quaternion.
	/// @param t Blend factor where 0 returns this quaternion and 1 returns the target.
	/// @returns Normalized spherical interpolation.
	public Self Slerp(in Self target, T t)
	{
		double dot = (double)DotProduct(target);
		Self targetCopy = target;

		if (dot < 0.0)
		{
			dot = -dot;
			targetCopy = -targetCopy;
		}

		const double epsilon = 1e-6;
		double tDouble = (double)t;

		if (dot > 1.0 - epsilon)
		{
			return Lerp(targetCopy, t);
		}

		double theta = Math.Acos(dot);
		double sinTheta = Math.Sin(theta);
		double w1 = Math.Sin((1.0 - tDouble) * theta) / sinTheta;
		double w2 = Math.Sin(tDouble * theta) / sinTheta;

		return (this * (T)w1 + targetCopy * (T)w2).Normalized();
	}

	/// @brief Computes the angle between two quaternions.
	/// @param rhs Second operand.
	/// @returns Angle in radians between orientations.
	[Inline]
	public T Angle(in Self rhs)
	{
		double dot = (double)DotProduct(rhs);
		double mags = Math.Sqrt((double)SquaredMagnitude() * (double)rhs.SquaredMagnitude());
		if (mags == 0.0)
			return (T)0;
		double normalizedDot = Math.Min(Math.Abs(dot / mags), 1.0);
		return (T)(2.0 * Math.Acos(normalizedDot));
	}

	/// @brief Component-wise addition of two quaternions.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);

	/// @brief Component-wise subtraction of two quaternions.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);

	/// @brief Component-wise multiplication by a scalar.
	[Inline]
	public static Self operator *(in Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);

	/// @brief Component-wise division by a scalar.
	[Inline]
	public static Self operator /(in Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);

	/// @brief Negates all components of a quaternion.
	[Inline]
	public static Self operator -(in Self value) => .(-value.x, -value.y, -value.z, -value.w);

	/// @brief Quaternion multiplication combining rotations.
	[Inline]
	public static Self operator *(in Self lhs, in Self rhs)
	{
		return .(
			lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
			lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
			lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
			lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
			);
	}

	/// @brief Rotates a vector by applying the quaternion.
	[Inline]
	public static Vector3<T> operator *(in Self lhs, in Vector3<T> rhs) => lhs.Rotate(rhs);

	/// @brief Compound assignment scaling by a scalar.
	[Inline]
	public void operator *=(T rhs) mut
	{
		x *= rhs; y *= rhs; z *= rhs; w *= rhs;
	}

	/// @brief Compound assignment dividing by a scalar.
	[Inline]
	public void operator /=(T rhs) mut
	{
		x /= rhs; y /= rhs; z /= rhs; w /= rhs;
	}

	/// @brief Compound assignment adding another quaternion component-wise.
	[Inline]
	public void operator +=(in Self rhs) mut
	{
		x += rhs.x; y += rhs.y; z += rhs.z; w += rhs.w;
	}

	/// @brief Compound assignment subtracting another quaternion component-wise.
	[Inline]
	public void operator -=(in Self rhs) mut
	{
		x -= rhs.x; y -= rhs.y; z -= rhs.z; w -= rhs.w;
	}

	/// @brief Compound assignment applying quaternion multiplication.
	[Inline]
	public void operator *=(in Self rhs) mut
	{
		this = this * rhs;
	}

	/// @brief Provides indexed access to quaternion components.
	/// @param i Component index in [0, 3].
	public T this[int i]
	{
		get => elements[i];
		set mut => elements[i] = value;
	}

	/// @brief Tests equality by comparing each component.
	public bool Equals(Self rhs)
	{
		return x == rhs.x && y == rhs.y && z == rhs.z && w == rhs.w;
	}

	/// @brief Generates a hash code for the quaternion.
	public int GetHashCode()
	{
		int seed = 0;
		seed = HashCode.Mix(seed, x.GetHashCode());
		seed = HashCode.Mix(seed, y.GetHashCode());
		seed = HashCode.Mix(seed, z.GetHashCode());
		seed = HashCode.Mix(seed, w.GetHashCode());
		return seed;
	}

	/// @brief Quaternion representing no rotation.
	[Inline]
	public static Self Identity => .((T)0, (T)0, (T)0, (T)1);

	/// @brief Quaternion with all components set to zero.
	[Inline]
	public static Self Zero => .((T)0, (T)0, (T)0, (T)0);

	/// @brief Casts this quaternion to an equivalent quaternion with a different component type.
	/// @returns Quaternion with each component converted to the requested type.
	public Quaternion<U> Cast<U>()
		where U :
		operator U + U,
		operator U - U,
		operator U * U,
		operator U / U,
		operator U % U,
		operator - U,
		operator ++ U,
		operator -- U,
		operator explicit double,
		IHashable
		where double : operator explicit U
		where double : operator implicit U
		where int : operator U <=> U
	{
		return .((U)(double)x, (U)(double)y, (U)(double)z, (U)(double)w);
	}
}
