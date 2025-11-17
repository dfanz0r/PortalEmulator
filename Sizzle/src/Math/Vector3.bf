using System;
using Sizzle.Core;

namespace Sizzle.Math;

/// @brief Default float 2d vector type
typealias Vector3 = Vector3<float>;

/// @brief Default int 3d vector type
typealias Vector3Int = Vector3<int>;

/// @brief Represents a three-dimensional vector with generic components.
[Union, CRepr]
struct Vector3<T> : IEquatable<Self>, IHashable
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
	public const int ElementCount = 3;

	/// @brief Raw component storage shared by all accessor views.
	public T[ElementCount] elements;
	/// @brief Provides spatial component accessors (x, y, z).
	public struct
	{
		/// @brief X component.
		public T x;
		/// @brief Y component.
		public T y;
		/// @brief Z component.
		public T z;
	};

	/// @brief Provides texture coordinate accessors (u, v, w).
	public struct
	{
		/// @brief U texture coordinate.
		public T u;
		/// @brief V texture coordinate.
		public T v;
		/// @brief W texture coordinate.
		public T w;
	};

	/// @brief Provides color channel accessors (r, g, b).
	public struct
	{
		/// @brief Red channel.
		public T r;
		/// @brief Green channel.
		public T g;
		/// @brief Blue channel.
		public T b;
	};

	/// @brief Creates a copy of another 3D vector.
	/// @param vec3 Source vector.
	public this(in Self vec3)
	{
		this.x = vec3.x;
		this.y = vec3.y;
		this.z = vec3.z;
	}

	/// @brief Creates a 3D vector from the XYZ components of a 4D vector.
	/// @param vec4 Source 4D vector.
	public this(in Vector4<T> vec4)
	{
		this.x = vec4.x;
		this.y = vec4.y;
		this.z = vec4.z;
	}

	/// @brief Creates a 3D vector from a 2D vector, padding Z with the default value.
	/// @param vec2 Source 2D vector.
	public this(in Vector2<T> vec2)
	{
		this.x = vec2.x;
		this.y = vec2.y;
		this.z = default;
	}

	/// @brief Creates a 3D vector from a 2D vector and explicit Z component.
	/// @param vec2 Source 2D vector supplying X and Y components.
	/// @param z Z component.
	public this(in Vector2<T> vec2, T z)
	{
		this.x = vec2.x;
		this.y = vec2.y;
		this.z = z;
	}

	/// @brief Creates a 3D vector from explicit component values.
	/// @param x X component.
	/// @param y Y component.
	/// @param z Z component.
	public this(T x, T y, T z)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/// @brief Creates a 3D vector from an array of three values.
	/// @param values Source array whose first three elements populate the vector.
	public this(T[3] values)
	{
		this.x = values[0];
		this.y = values[1];
		this.z = values[2];
	}

	// Component-wise overloads
	/// @brief Multiplies two vectors component-wise.
	[Inline]
	public static Self operator *(in Self lhs, in Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z);
	/// @brief Divides two vectors component-wise.
	[Inline]
	public static Self operator /(in Self lhs, in Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z);
	/// @brief Applies component-wise modulo between two vectors.
	[Inline]
	public static Self operator %(in Self lhs, in Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z);
	/// @brief Adds two vectors component-wise.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);
	/// @brief Subtracts two vectors component-wise.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);

	/// @brief Multiplies each component by a scalar.
	[Inline]
	public static Self operator *(in Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs);
	/// @brief Divides each component by a scalar.
	[Inline]
	public static Self operator /(in Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs);
	/// @brief Applies scalar modulo to each component.
	[Inline]
	public static Self operator %(in Self lhs, T rhs) => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs);
	/// @brief Adds a scalar to each component.
	[Inline]
	public static Self operator +(in Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs);
	/// @brief Subtracts a scalar from each component.
	[Inline]
	public static Self operator -(in Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs);
	/// @brief Negates all components.
	[Inline]
	public static Self operator -(in Self val) => .(-val.x, -val.y, -val.z);

	// instance operators
	/// @brief Multiplies this vector by another component-wise in-place.
	[Inline]
	public void operator *=(in Self rhs) mut
	{
		x = x * rhs.x; y = y * rhs.y; z = z * rhs.z;
	}

	/// @brief Divides this vector by another component-wise in-place.
	[Inline]
	public void operator /=(in Self rhs) mut
	{
		x = x / rhs.x; y = y / rhs.y; z = z / rhs.z;
	}

	/// @brief Applies component-wise modulo in-place.
	[Inline]
	public void operator %=(in Self rhs) mut
	{
		x = x % rhs.x; y = y % rhs.y; z = z % rhs.z;
	}

	/// @brief Adds another vector component-wise in-place.
	[Inline]
	public void operator +=(in Self rhs) mut
	{
		x = x + rhs.x; y = y + rhs.y; z = z + rhs.z;
	}

	/// @brief Subtracts another vector component-wise in-place.
	[Inline]
	public void operator -=(in Self rhs) mut
	{
		x = x - rhs.x; y = y - rhs.y; z = z - rhs.z;
	}

	/// @brief Multiplies each component by a scalar in-place.
	[Inline]
	public void operator *=(T rhs) mut
	{
		x = x * rhs; y = y * rhs; z = z * rhs;
	}

	/// @brief Divides each component by a scalar in-place.
	[Inline]
	public void operator /=(T rhs) mut
	{
		x = x / rhs; y = y / rhs; z = z / rhs;
	}

	/// @brief Applies scalar modulo to each component in-place.
	[Inline]
	public void operator %=(T rhs) mut
	{
		x = x % rhs; y = y % rhs; z = z % rhs;
	}

	/// @brief Adds a scalar to each component in-place.
	[Inline]
	public void operator +=(T rhs) mut
	{
		x = x + rhs; y = y + rhs; z = z + rhs;
	}

	/// @brief Subtracts a scalar from each component in-place.
	[Inline]
	public void operator -=(T rhs) mut
	{
		x = x - rhs; y = y - rhs; z = z - rhs;
	}

	/// @brief Increments all components.
	[Inline]
	public void operator ++() mut
	{
		x++; y++; z++;
	}

	/// @brief Decrements all components.
	[Inline]
	public void operator --() mut
	{
		x--; y--; z--;
	}

	/// @brief Provides indexed access to the vector components.
	/// @param i Component index in [0, 2].
	public T this[int i]
	{
		get => elements[i];
		set mut => elements[i] = value;
	}

	/// @brief Computes the dot product with another vector.
	/// @param rhs Second operand.
	/// @returns Dot product of the two vectors.
	[Inline]
	public T DotProduct(in Self rhs) => x * rhs.x + y * rhs.y + z * rhs.z;

	/// @brief Computes the cross product with another vector.
	/// @param b Second operand.
	/// @returns Vector perpendicular to both inputs.
	[Inline]
	public Self CrossProduct(in Self b)
	{
		return .(
			y * b.z - z * b.y,
			z * b.x - x * b.z,
			x * b.y - y * b.x
			);
	}


	/// @brief Computes the angle between two vectors.
	/// @param lhs Left-hand operand.
	/// @param rhs Right-hand operand.
	/// @returns Angle in radians between the vectors.
	[Inline]
	public static T Angle(in Self lhs, in Self rhs)
	{
		double dot = (double)lhs.DotProduct(rhs);
		double mags = Math.Sqrt((double)lhs.SquaredMagnitude() * (double)rhs.SquaredMagnitude());
		return mags != 0.0 ? (T)Math.Acos(dot / mags) : (T)0;
	}

	/// @brief Reflects this vector about a provided normal.
	/// @param normal Unit-length normal describing the reflection plane.
	/// @returns Reflected vector.
	[Inline]
	public Self Reflect(in Self normal)
	{
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
		return this - Project(onto);
	}

	/// @brief Rotates this vector about an axis by the provided angle in radians.
	/// @param axis Rotation axis.
	/// @param radians Counter-clockwise rotation angle in radians.
	/// @returns Rotated vector.
	[Inline]
	public Self RotateAroundAxis(in Self axis, T radians)
	{
		Self k = axis.Normalized();
		double s = Math.Sin((double)radians);
		double c = Math.Cos((double)radians);
		return this * (T)c + k.CrossProduct(this) * (T)s + k * (k.DotProduct(this) * (T)(1 - c));
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
			return .(default, default, default); // return zero vector

		double invLen = 1.0 / Math.Sqrt((double)sqrMag);
		T scale = (T)invLen;

		return .(x * scale, y * scale, z * scale);
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
		return .(x > other.x ? x : other.x, y > other.y ? y : other.y, z > other.z ? z : other.z
			);
	}

	/// @brief Chooses the component-wise minimum between this vector and another.
	/// @param other Vector to compare.
	/// @returns Component-wise minimum.
	[Inline]
	public Self Min(in Self other)
	{
		return .(x < other.x ? x : other.x, y < other.y ? y : other.y, z < other.z ? z : other.z
			);
	}

	/// @brief Returns the component-wise absolute value.
	/// @returns Vector whose components are absolute values of this vector.
	[Inline]
	public Self Abs()
	{
		T zero = (T)0;
		return .(x < zero ? -x : x, y < zero ? -y : y, z < zero ? -z : z
			);
	}

	/// @brief Clamps each component between the corresponding components of two bounds.
	/// @param min Lower bound vector.
	/// @param max Upper bound vector.
	/// @returns Clamped vector.
	[Inline]
	public Self Clamp(in Self min, in Self max)
	{
		return .(x < min.x ? min.x : (x > max.x ? max.x : x), y < min.y ? min.y : (y > max.y ? max.y : y), z < min.z ? min.z : (z > max.z ? max.z : z)
			);
	}

	/// @brief Clamps each component to the [0, 1] range.
	/// @returns Saturated vector.
	[Inline]
	public Self Saturate()
	{
		T zero = (T)0;
		T one = (T)1;
		return .(x < zero ? zero : (x > one ? one : x), y < zero ? zero : (y > one ? one : y), z < zero ? zero : (z > one ? one : z)
			);
	}

	/// @brief Compares two vectors for component-wise equality.
	/// @param rhs Vector to compare against.
	/// @returns True when all components are equal.
	public bool Equals(Self rhs)
	{
		return x == rhs.x && y == rhs.y && z == rhs.z;
	}

	/// @brief Generates a hash code for the vector.
	/// @returns Hash code combining all components.
	public int GetHashCode()
	{
		int seed = 0;
		seed = HashCode.Mix(seed, x.GetHashCode());
		seed = HashCode.Mix(seed, y.GetHashCode());
		seed = HashCode.Mix(seed, z.GetHashCode());
		return seed;
	}


	/// @brief Unit vector pointing to the left along the X-axis.
	[Inline]
	public static Self Left => .((T)1, (T)0, (T)0);

	/// @brief Unit vector pointing to the right along the X-axis.
	[Inline]
	public static Self Right => .((T) - 1, (T)0, (T)0);

	/// @brief Unit vector pointing upward along the Y-axis.
	[Inline]
	public static Self Up => .((T)0, (T)1, (T)0);

	/// @brief Unit vector pointing downward along the Y-axis.
	[Inline]
	public static Self Down => .((T)0, (T) - 1, (T)0);

	/// @brief Unit vector pointing forward along the positive Z-axis.
	[Inline]
	public static Self Forward => .((T)0, (T)0, (T)1);

	/// @brief Unit vector pointing backward along the negative Z-axis.
	[Inline]
	public static Self Back => .((T)0, (T)0, (T) - 1);

	/// @brief Vector with all components set to one.
	[Inline]
	public static Self One => .((T)1, (T)1, (T)1);

	/// @brief Vector with all components set to zero.
	[Inline]
	public static Self Zero => .((T)0, (T)0, (T)0);

	/// @brief Casts this vector to a different component type.
	/// @returns Vector with components converted to the requested type.
	public Vector3<U> Cast<U>()
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
		return .((U)(double)x, (U)(double)y, (U)(double)z);
	}
}

extension Vector3<T>
	where T :
	operator T & T,
	operator T | T,
	operator T ^ T,
	operator ~ T
{
	/// @brief Performs a component-wise bitwise AND between two vectors.
	[Inline]
	public static Vector3<T> operator &(in Vector3<T> lhs, in Vector3<T> rhs) => .(lhs.x & rhs.x, lhs.y & rhs.y, lhs.z & rhs.z);

	/// @brief Performs a component-wise bitwise OR between two vectors.
	[Inline]
	public static Vector3<T> operator |(in Vector3<T> lhs, in Vector3<T> rhs) => .(lhs.x | rhs.x, lhs.y | rhs.y, lhs.z | rhs.z);

	/// @brief Performs a component-wise bitwise XOR between two vectors.
	[Inline]
	public static Vector3<T> operator ^(in Vector3<T> lhs, in Vector3<T> rhs) => .(lhs.x ^ rhs.x, lhs.y ^ rhs.y, lhs.z ^ rhs.z);

	/// @brief Applies a scalar bitwise AND to every component.
	[Inline]
	public static Vector3<T> operator &(in Vector3<T> lhs, T rhs) => .(lhs.x & rhs, lhs.y & rhs, lhs.z & rhs);

	/// @brief Applies a scalar bitwise OR to every component.
	[Inline]
	public static Vector3<T> operator |(in Vector3<T> lhs, T rhs) => .(lhs.x | rhs, lhs.y | rhs, lhs.z | rhs);

	/// @brief Applies a scalar bitwise XOR to every component.
	[Inline]
	public static Vector3<T> operator ^(in Vector3<T> lhs, T rhs) => .(lhs.x ^ rhs, lhs.y ^ rhs, lhs.z ^ rhs);

	/// @brief Returns the component-wise bitwise negation of this vector.
	[Inline]
	public static Vector3<T> operator ~(Vector3<T> value) => .(~value.x, ~value.y, ~value.z);

	/// @brief Applies a component-wise bitwise AND in-place.
	[Inline]
	public void operator &=(in Vector3<T> rhs) mut
	{
		x &= rhs.x; y &= rhs.y; z &= rhs.z;
	}

	/// @brief Applies a component-wise bitwise OR in-place.
	[Inline]
	public void operator |=(in Vector3<T> rhs) mut
	{
		x |= rhs.x; y |= rhs.y; z |= rhs.z;
	}

	/// @brief Applies a component-wise bitwise XOR in-place.
	[Inline]
	public void operator ^=(in Vector3<T> rhs) mut
	{
		x ^= rhs.x; y ^= rhs.y; z ^= rhs.z;
	}

	/// @brief Applies a scalar bitwise AND in-place.
	[Inline]
	public void operator &=(T rhs) mut
	{
		x &= rhs; y &= rhs; z &= rhs;
	}

	/// @brief Applies a scalar bitwise OR in-place.
	[Inline]
	public void operator |=(T rhs) mut
	{
		x |= rhs; y |= rhs; z |= rhs;
	}

	/// @brief Applies a scalar bitwise XOR in-place.
	[Inline]
	public void operator ^=(T rhs) mut
	{
		x ^= rhs; y ^= rhs; z ^= rhs;
	}
}