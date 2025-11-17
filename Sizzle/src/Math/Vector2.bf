using System;
using Sizzle.Core;

namespace Sizzle.Math;

/// @brief Default float 2d vector type
typealias Vector2 = Vector2<float>;

/// @brief Default int 2d vector type
typealias Vector2Int = Vector2<int32>;

[Union, CRepr]
struct Vector2<T> : IEquatable<Self>, IHashable
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
	/// @brief Number of scalar components in the vector.
	public const int ElementCount = 2;

	/// @brief Raw component storage shared by all accessor views.
	public T[ElementCount] elements;
	/// @brief Provides spatial accessors (x, y).
	public struct
	{
		/// @brief X component.
		public T x;
		/// @brief Y component.
		public T y;
	};

	/// @brief Provides texture-coordinate accessors (u, v).
	public struct
	{
		/// @brief U texture coordinate.
		public T u;
		/// @brief V texture coordinate.
		public T v;
	};

	/// @brief Provides size accessors (width, height).
	public struct
	{
		/// @brief Width component.
		public T width;
		/// @brief Height component.
		public T height;
	};

	/// @brief Creates a 2D vector from the XY components of a 4D vector.
	/// @param vec4 Source 4D vector.
	public this(in Vector4<T> vec4)
	{
		this.x = vec4.x;
		this.y = vec4.y;
	}

	/// @brief Creates a 2D vector from the XY components of a 3D vector.
	/// @param vec3 Source 3D vector.
	public this(in Vector3<T> vec3)
	{
		this.x = vec3.x;
		this.y = vec3.y;
	}

	/// @brief Creates a copy of another 2D vector.
	/// @param vec2 Source vector.
	public this(in Vector2<T> vec2)
	{
		this.x = vec2.x;
		this.y = vec2.y;
	}

	/// @brief Creates a 2D vector from explicit component values.
	/// @param x X component.
	/// @param y Y component.
	public this(T x, T y)
	{
		this.x = x;
		this.y = y;
	}

	/// @brief Creates a 2D vector from an array of two values.
	/// @param values Source array whose first two elements become the components.
	public this(T[2] values)
	{
		this.x = values[0];
		this.y = values[1];
	}

	// Component-wise overloads
	/// @brief Multiplies two vectors component-wise.
	[Inline]
	public static Self operator *(in Self lhs, in Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y);
	/// @brief Divides two vectors component-wise.
	[Inline]
	public static Self operator /(in Self lhs, in Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y);
	/// @brief Applies component-wise modulo between two vectors.
	[Inline]
	public static Self operator %(in Self lhs, in Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y);
	/// @brief Adds two vectors component-wise.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y);
	/// @brief Subtracts two vectors component-wise.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y);

	/// @brief Multiplies each component by a scalar.
	[Inline]
	public static Self operator *(in Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs);
	/// @brief Divides each component by a scalar.
	[Inline]
	public static Self operator /(in Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs);
	/// @brief Applies scalar modulo to each component.
	[Inline]
	public static Self operator %(in Self lhs, T rhs) => .(lhs.x % rhs, lhs.y % rhs);
	/// @brief Adds a scalar to each component.
	[Inline]
	public static Self operator +(in Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs);
	/// @brief Subtracts a scalar from each component.
	[Inline]
	public static Self operator -(in Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs);
	/// @brief Negates both components.
	[Inline]
	public static Self operator -(Self val) => .(-val.x, -val.y);

	// instance operators
	/// @brief Multiplies this vector by another component-wise in-place.
	[Inline]
	public void operator *=(in Self rhs) mut
	{
		x = x * rhs.x; y = y * rhs.y;
	}

	/// @brief Divides this vector by another component-wise in-place.
	[Inline]
	public void operator /=(in Self rhs) mut
	{
		x = x / rhs.x; y = y / rhs.y;
	}

	/// @brief Applies component-wise modulo in-place.
	[Inline]
	public void operator %=(in Self rhs) mut
	{
		x = x % rhs.x; y = y % rhs.y;
	}

	/// @brief Adds another vector component-wise in-place.
	[Inline]
	public void operator +=(in Self rhs) mut
	{
		x = x + rhs.x; y = y + rhs.y;
	}

	/// @brief Subtracts another vector component-wise in-place.
	[Inline]
	public void operator -=(in Self rhs) mut
	{
		x = x - rhs.x; y = y - rhs.y;
	}

	/// @brief Multiplies each component by a scalar in-place.
	[Inline]
	public void operator *=(T rhs) mut
	{
		x = x * rhs; y = y * rhs;
	}

	/// @brief Divides each component by a scalar in-place.
	[Inline]
	public void operator /=(T rhs) mut
	{
		x = x / rhs; y = y / rhs;
	}

	/// @brief Applies scalar modulo to each component in-place.
	[Inline]
	public void operator %=(T rhs) mut
	{
		x = x % rhs; y = y % rhs;
	}

	/// @brief Adds a scalar to each component in-place.
	[Inline]
	public void operator +=(T rhs) mut
	{
		x = x + rhs; y = y + rhs;
	}

	/// @brief Subtracts a scalar from each component in-place.
	[Inline]
	public void operator -=(T rhs) mut
	{
		x = x - rhs; y = y - rhs;
	}

	/// @brief Increments both components.
	[Inline]
	public void operator ++() mut
	{
		x++; y++;
	}

	/// @brief Decrements both components.
	[Inline]
	public void operator --() mut
	{
		x--; y--;
	}

	/// @brief Provides indexed access to the vector components.
	/// @param i Component index.
	public T this[int i]
	{
		get => elements[i];
		set mut => elements[i] = value;
	}

	/// @brief Computes the dot product with another vector.
	/// @param rhs Second operand.
	/// @returns Dot product of the two vectors.
	[Inline]
	public T DotProduct(in Self rhs) => x * rhs.x + y * rhs.y;

	/// @brief Computes the Z component of the 3D cross product of two 2D vectors.
	/// @param lhs Left-hand operand.
	/// @param rhs Right-hand operand.
	/// @returns Scalar cross product value.
	[Inline]
	public static T CrossProduct(in Self lhs, in Self rhs) => lhs.x * rhs.y - lhs.y * rhs.x;

	/// @brief Computes the angle between two vectors.
	/// @param lhs Left-hand operand.
	/// @param rhs Right-hand operand.
	/// @returns Angle in radians between the vectors.
	[Inline]
	public static T Angle(Self lhs, Self rhs)
	{
		double dot = (double)lhs.DotProduct(rhs);
		double mags = Math.Sqrt((double)lhs.SquaredMagnitude() * (double)rhs.SquaredMagnitude());
		return mags != 0.0 ? (T)Math.Acos(dot / mags) : (T)0;
	}


	/// @brief Returns a vector rotated 90 degrees counter-clockwise.
	/// @returns The perpendicular vector.
	[Inline]
	public Self Perpendicular()
	{
		return .(-y, x); // Rotate 90 degrees CCW
	}

	/// @brief Reflects this vector about a provided normal.
	/// @param normal Unit-length normal describing the reflection plane.
	/// @returns Reflected vector.
	[Inline]
	public Self Reflect(in Self normal)
	{
		// Reflection formula: v - 2 * dot(v, n) * n
		T d = DotProduct(normal);
		return this - normal * (d + d);
	}

	/// @brief Projects this vector onto another.
	/// @param onto Vector to project onto.
	/// @returns Projection of this vector along the target vector, or Zero if the target has no length.
	[Inline]
	public Self Project(in Self onto)
	{
		T denom = onto.SquaredMagnitude();
		return denom != default ? onto * (DotProduct(onto) / denom) : Self.Zero;
	}

	/// @brief Rejects this vector from another.
	/// @param onto Vector to reject from.
	/// @returns Component of this vector perpendicular to the target vector.
	[Inline]
	public Self Reject(in Self onto)
	{
		// Component perpendicular to b
		return this - Project(onto);
	}

	/// @brief Rotates this vector by the provided angle in radians.
	/// @param radians Counter-clockwise angle in radians.
	/// @returns Rotated vector.
	[Inline]
	public Self Rotate(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			(T)((double)x * c - (double)y * s),
			(T)((double)x * s + (double)y * c)
			);
	}

	/// @brief Computes the squared distance to another vector.
	/// @param rhs Target vector.
	/// @returns Squared distance between this vector and the target.
	[Inline]
	public T SquaredDistance(in Self rhs)
	{
		let diff = this - rhs;
		return diff.DotProduct(diff);
	}

	/// @brief Computes the distance to another vector.
	/// @param rhs Target vector.
	/// @returns Euclidean distance between this vector and the target.
	[Inline]
	public T Distance(in Self rhs)
	{
		return (T)Math.Sqrt((double)SquaredDistance(rhs));
	}

	/// @brief Computes the vector magnitude.
	/// @returns Euclidean length of the vector.
	[Inline]
	public T Magnitude()
	{
		double val = (double)(SquaredMagnitude());
		return (T)Math.Sqrt(val);
	}

	/// @brief Computes the squared vector magnitude.
	/// @returns Squared length of the vector.
	[Inline]
	public T SquaredMagnitude() => DotProduct(this);

	/// @brief Returns a normalized copy of this vector.
	/// @returns Unit-length vector pointing in the same direction, or Zero when magnitude is zero.
	public Self Normalized()
	{
		T sqrMag = SquaredMagnitude();

		if (sqrMag == default)
			return .(default, default); // return zero vector

		double invLen = 1.0 / Math.Sqrt((double)sqrMag);
		T scale = (T)invLen;

		return .(x * scale, y * scale);
	}
	/// @brief Linearly interpolates toward another vector.
	/// @param target Target vector.
	/// @param t Blend factor where 0 returns this vector and 1 returns the target.
	/// @returns Interpolated vector.
	[Inline]
	public Self Lerp(in Self target, T t)
	{
		return this + (target - this) * t;
	}

	/// @brief Chooses the component-wise maximum between this vector and another.
	/// @param other Vector to compare.
	/// @returns Component-wise maximum.
	[Inline]
	public Self Max(in Self other)
	{
		return .(x > other.x ? x : other.x, y > other.y ? y : other.y
			);
	}

	/// @brief Chooses the component-wise minimum between this vector and another.
	/// @param other Vector to compare.
	/// @returns Component-wise minimum.
	[Inline]
	public Self Min(in Self other)
	{
		return .(x < other.x ? x : other.x, y < other.y ? y : other.y
			);
	}

	/// @brief Returns the component-wise absolute value.
	/// @returns Vector whose components are absolute values of this vector.
	[Inline]
	public Self Abs()
	{
		T zero = (T)0;
		return .(x < zero ? -x : x, y < zero ? -y : y
			);
	}

	/// @brief Clamps each component between the corresponding components of two bounds.
	/// @param min Lower bound vector.
	/// @param max Upper bound vector.
	/// @returns Clamped vector.
	[Inline]
	public Self Clamp(in Self min, in Self max)
	{
		return .(x < min.x ? min.x : (x > max.x ? max.x : x), y < min.y ? min.y : (y > max.y ? max.y : y)
			);
	}

	/// @brief Clamps each component to the [0, 1] range.
	/// @returns Saturated vector.
	[Inline]
	public Self Saturate()
	{
		T zero = (T)0;
		T one = (T)1;
		return .(x < zero ? zero : (x > one ? one : x), y < zero ? zero : (y > one ? one : y)
			);
	}

	/// @brief Compares two vectors for component-wise equality.
	/// @param rhs Vector to compare against.
	/// @returns True when all components are equal.
	public bool Equals(Self rhs)
	{
		return x == rhs.x && y == rhs.y;
	}

	/// @brief Generates a hash code for the vector.
	/// @returns Hash code combining both components.
	public int GetHashCode()
	{
		int seed = 0;
		seed = HashCode.Mix(seed, x.GetHashCode());
		seed = HashCode.Mix(seed, y.GetHashCode());
		return seed;
	}

	/// @brief Unit vector pointing to the left in screen space.
	[Inline]
	public static Self Left => .((T)1, (T)0);

	/// @brief Unit vector pointing to the right in screen space.
	[Inline]
	public static Self Right => .((T) - 1, (T)0);

	/// @brief Unit vector pointing upward.
	[Inline]
	public static Self Up => .((T)0, (T)1);

	/// @brief Unit vector pointing downward.
	[Inline]
	public static Self Down => .((T)0, (T) - 1);

	/// @brief Vector with all components set to one.
	[Inline]
	public static Self One => .((T)1, (T)1);

	/// @brief Vector with all components set to zero.
	[Inline]
	public static Self Zero => .((T)0, (T)0);

	/// @brief Casts this vector to a different component type.
	/// @returns Vector with components converted to the requested type.
	public Vector2<U> Cast<U>()
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
		return .((U)(double)x, (U)(double)y);
	}
}

extension Vector2<T>
	where T :
	operator T & T,
	operator T | T,
	operator T ^ T,
	operator ~ T
{
	/// @brief Performs a component-wise bitwise AND between two vectors.
	[Inline]
	public static Vector2<T> operator &(in Vector2<T> lhs, in Vector2<T> rhs) => .(lhs.x & rhs.x, lhs.y & rhs.y);

	/// @brief Performs a component-wise bitwise OR between two vectors.
	[Inline]
	public static Vector2<T> operator |(in Vector2<T> lhs, in Vector2<T> rhs) => .(lhs.x | rhs.x, lhs.y | rhs.y);

	/// @brief Performs a component-wise bitwise XOR between two vectors.
	[Inline]
	public static Vector2<T> operator ^(in Vector2<T> lhs, in Vector2<T> rhs) => .(lhs.x ^ rhs.x, lhs.y ^ rhs.y);

	/// @brief Applies a scalar bitwise AND to every component.
	[Inline]
	public static Vector2<T> operator &(in Vector2<T> lhs, T rhs) => .(lhs.x & rhs, lhs.y & rhs);

	/// @brief Applies a scalar bitwise OR to every component.
	[Inline]
	public static Vector2<T> operator |(in Vector2<T> lhs, T rhs) => .(lhs.x | rhs, lhs.y | rhs);

	/// @brief Applies a scalar bitwise XOR to every component.
	[Inline]
	public static Vector2<T> operator ^(in Vector2<T> lhs, T rhs) => .(lhs.x ^ rhs, lhs.y ^ rhs);

	/// @brief Returns the component-wise bitwise negation of this vector.
	[Inline]
	public static Vector2<T> operator ~(Vector2<T> value) => .(~value.x, ~value.y);

	/// @brief Applies a component-wise bitwise AND in-place.
	[Inline]
	public void operator &=(in Vector2<T> rhs) mut
	{
		x &= rhs.x; y &= rhs.y;
	}

	/// @brief Applies a component-wise bitwise OR in-place.
	[Inline]
	public void operator |=(in Vector2<T> rhs) mut
	{
		x |= rhs.x; y |= rhs.y;
	}

	/// @brief Applies a component-wise bitwise XOR in-place.
	[Inline]
	public void operator ^=(in Vector2<T> rhs) mut
	{
		x ^= rhs.x; y ^= rhs.y;
	}

	/// @brief Applies a scalar bitwise AND in-place.
	[Inline]
	public void operator &=(T rhs) mut
	{
		x &= rhs; y &= rhs;
	}

	/// @brief Applies a scalar bitwise OR in-place.
	[Inline]
	public void operator |=(T rhs) mut
	{
		x |= rhs; y |= rhs;
	}

	/// @brief Applies a scalar bitwise XOR in-place.
	[Inline]
	public void operator ^=(T rhs) mut
	{
		x ^= rhs; y ^= rhs;
	}
}