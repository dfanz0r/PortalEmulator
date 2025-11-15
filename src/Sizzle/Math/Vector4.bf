using System;
using Sizzle.Core;
using System.Numerics;

using internal Sizzle.Math;

namespace Sizzle.Math;

/// @brief Default float 4d vector type
typealias Vector4 = Vector4<float>;

/// @brief Default int 3d vector type
typealias Vector4Int = Vector4<int>;

/// @brief Represents a four-dimensional vector with generic components.
[Union, CRepr]
struct Vector4<T> : IEquatable<Self>, IHashable
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
	public const int ElementCount = 4;

	/// @brief Raw component storage shared by all accessor views.
	public T[ElementCount] elements;
	/// @brief Provides spatial accessors (x, y, z, w).
	public struct
	{
		/// @brief X component.
		public T x;
		/// @brief Y component.
		public T y;
		/// @brief Z component.
		public T z;
		/// @brief W component.
		public T w;
	};
	/// @brief Provides color channel accessors (r, g, b, a).
	public struct
	{
		/// @brief Red channel.
		public T r;
		/// @brief Green channel.
		public T g;
		/// @brief Blue channel.
		public T b;
		/// @brief Alpha channel.
		public T a;
	};
	private Num4<T> mVectorized;

	/// @brief Creates a copy of another 4D vector.
	/// @param vec4 Source vector.
	public this(in Self vec4)
	{
		this.x = vec4.x;
		this.y = vec4.y;
		this.z = vec4.z;
		this.w = vec4.w;
	}

	private this(in Num4<T> num4)
	{
		this.mVectorized = num4;
	}

	/// @brief Creates a 4D vector from a 3D vector, padding W with the default value.
	/// @param vec3 Source 3D vector.
	public this(in Vector3<T> vec3)
	{
		this.x = vec3.x;
		this.y = vec3.y;
		this.z = vec3.z;
		this.w = default;
	}

	/// @brief Creates a 4D vector from a 3D vector and explicit W component.
	/// @param vec3 Source 3D vector supplying XYZ components.
	/// @param w W component.
	public this(in Vector3<T> vec3, T w)
	{
		this.x = vec3.x;
		this.y = vec3.y;
		this.z = vec3.z;
		this.w = w;
	}

	/// @brief Creates a 4D vector from a 2D vector, padding Z and W with the default value.
	/// @param vec2 Source 2D vector.
	public this(in Vector2<T> vec2)
	{
		this.x = vec2.x;
		this.y = vec2.y;
		this.z = default;
		this.w = default;
	}

	/// @brief Creates a 4D vector from a 2D vector and explicit Z and W components.
	/// @param vec2 Source 2D vector supplying X and Y components.
	/// @param z Z component.
	/// @param w W component.
	public this(in Vector2<T> vec2, T z, T w)
	{
		this.x = vec2.x;
		this.y = vec2.y;
		this.z = z;
		this.w = w;
	}

	/// @brief Creates a 4D vector from explicit component values.
	/// @param x X component.
	/// @param y Y component.
	/// @param z Z component.
	/// @param w W component.
	public this(T x, T y, T z, T w)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	/// @brief Creates a 4D vector from an array of four values.
	/// @param values Source array whose first four elements populate the vector.
	public this(T[4] values)
	{
		this.x = values[0];
		this.y = values[1];
		this.z = values[2];
		this.w = values[3];
	}

#if DEBUG
	// This is currently here to deal with a compiler bug with release mode where UnderlyingArray/intrinsics does not emit correct instructions for doubles
	// Component-wise overloads
	/// @brief Multiplies two vectors component-wise.
	[Inline]
	public static Self operator *(in Self lhs, in Self rhs) => .(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w);
	/// @brief Divides two vectors component-wise.
	[Inline]
	public static Self operator /(in Self lhs, in Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z, lhs.w / rhs.w);
	/// @brief Applies component-wise modulo between two vectors.
	[Inline]
	public static Self operator %(in Self lhs, in Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z, lhs.w % rhs.w);
	/// @brief Adds two vectors component-wise.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
	/// @brief Subtracts two vectors component-wise.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
#else
	// Component-wise overloads
	/// @brief Multiplies two vectors component-wise.
	[Inline]
	public static Self operator *(in Self lhs, in Self rhs) => .(lhs.mVectorized * rhs.mVectorized);
	/// @brief Divides two vectors component-wise.
	[Inline]
	public static Self operator /(in Self lhs, in Self rhs) => .(lhs.mVectorized / rhs.mVectorized);
	/// @brief Applies component-wise modulo between two vectors.
	[Inline]
	public static Self operator %(in Self lhs, in Self rhs) => .(lhs.mVectorized % rhs.mVectorized);
	/// @brief Adds two vectors component-wise.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.mVectorized + rhs.mVectorized);
	/// @brief Subtracts two vectors component-wise.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.mVectorized - rhs.mVectorized);
#endif


#if DEBUG
	/// @brief Multiplies each component by a scalar.
	[Inline]
	public static Self operator *(in Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);
	/// @brief Divides each component by a scalar.
	[Inline]
	public static Self operator /(in Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
	/// @brief Applies scalar modulo to each component.
	[Inline]
	public static Self operator %(in Self lhs, T rhs) => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs, lhs.w % rhs);
	/// @brief Adds a scalar to each component.
	[Inline]
	public static Self operator +(in Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs, lhs.w + rhs);
	/// @brief Subtracts a scalar from each component.
	[Inline]
	public static Self operator -(in Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs, lhs.w - rhs);
	/// @brief Negates all components.
	[Inline]
	public static Self operator -(Self val) => .(-val.x, -val.y, -val.z, -val.w);
#else

	/// @brief Multiplies each component by a scalar.
	[Inline]
	public static Self operator *(in Self lhs, T rhs) => .(lhs.mVectorized * rhs);
	/// @brief Divides each component by a scalar.
	[Inline]
	public static Self operator /(in Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
	/// @brief Applies scalar modulo to each component.
	[Inline]
	public static Self operator %(in Self lhs, T rhs) => .(lhs.mVectorized % rhs);
	/// @brief Adds a scalar to each component.
	[Inline]
	public static Self operator +(in Self lhs, T rhs) => .(lhs.mVectorized + rhs);
	/// @brief Subtracts a scalar from each component.
	[Inline]
	public static Self operator -(in Self lhs, T rhs) => .(lhs.mVectorized - rhs);
	/// @brief Negates all components.

	private static Num4<T> negate = .((T) - 1, (T) - 1, (T) - 1, (T) - 1);

	[Inline]
	public static Self operator -(Self val) => .(val.mVectorized * negate);
#endif



#if DEBUG
	// instance operators
	/// @brief Multiplies this vector by another component-wise in-place.
	[Inline]
	public void operator *=(in Self rhs) mut
	{
		x = x * rhs.x; y = y * rhs.y; z = z * rhs.z; w = w * rhs.w;
	}

	/// @brief Divides this vector by another component-wise in-place.
	[Inline]
	public void operator /=(in Self rhs) mut
	{
		x = x / rhs.x; y = y / rhs.y; z = z / rhs.z; w = w / rhs.w;
	}

	/// @brief Applies component-wise modulo in-place.
	[Inline]
	public void operator %=(in Self rhs) mut
	{
		x = x % rhs.x; y = y % rhs.y; z = z % rhs.z; w = w % rhs.w;
	}

	/// @brief Adds another vector component-wise in-place.
	[Inline]
	public void operator +=(in Self rhs) mut
	{
		x = x + rhs.x; y = y + rhs.y; z = z + rhs.z; w = w + rhs.w;
	}

	/// @brief Subtracts another vector component-wise in-place.
	[Inline]
	public void operator -=(in Self rhs) mut
	{
		x = x - rhs.x; y = y - rhs.y; z = z - rhs.z; w = w - rhs.w;
	}

	/// @brief Multiplies each component by a scalar in-place.
	[Inline]
	public void operator *=(T rhs) mut
	{
		x = x * rhs; y = y * rhs; z = z * rhs; w = w * rhs;
	}

	/// @brief Divides each component by a scalar in-place.
	[Inline]
	public void operator /=(T rhs) mut
	{
		x = x / rhs; y = y / rhs; z = z / rhs; w = w / rhs;
	}

	/// @brief Applies scalar modulo to each component in-place.
	[Inline]
	public void operator %=(T rhs) mut
	{
		x = x % rhs; y = y % rhs; z = z % rhs; w = w % rhs;
	}

	/// @brief Adds a scalar to each component in-place.
	[Inline]
	public void operator +=(T rhs) mut
	{
		x = x + rhs; y = y + rhs; z = z + rhs; w = w + rhs;
	}

	/// @brief Subtracts a scalar from each component in-place.
	[Inline]
	public void operator -=(T rhs) mut
	{
		x = x - rhs; y = y - rhs; z = z - rhs; w = w - rhs;
	}

	/// @brief Increments all components.
	[Inline]
	public void operator ++() mut
	{
		x++; y++; z++; w++;
	}

	/// @brief Decrements all components.
	[Inline]
	public void operator --() mut
	{
		x--; y--; z--; w--;
	}
	#else

	// instance operators
	/// @brief Multiplies this vector by another component-wise in-place.
	[Inline]
	public void operator *=(in Self rhs) mut
	{
		mVectorized = mVectorized * rhs.mVectorized;
	}

	/// @brief Divides this vector by another component-wise in-place.
	[Inline]
	public void operator /=(in Self rhs) mut
	{
		mVectorized = mVectorized / rhs.mVectorized;
	}

	/// @brief Applies component-wise modulo in-place.
	[Inline]
	public void operator %=(in Self rhs) mut
	{
		mVectorized = mVectorized % rhs.mVectorized;
	}

	/// @brief Adds another vector component-wise in-place.
	[Inline]
	public void operator +=(in Self rhs) mut
	{
		mVectorized = mVectorized + rhs.mVectorized;
	}

	/// @brief Subtracts another vector component-wise in-place.
	[Inline]
	public void operator -=(in Self rhs) mut
	{
		mVectorized = mVectorized - rhs.mVectorized;
	}

	/// @brief Multiplies each component by a scalar in-place.
	[Inline]
	public void operator *=(T rhs) mut
	{
		mVectorized = mVectorized * rhs;
	}

	/// @brief Divides each component by a scalar in-place.
	[Inline]
	public void operator /=(T rhs) mut
	{
		mVectorized = mVectorized / rhs;
	}

	/// @brief Applies scalar modulo to each component in-place.
	[Inline]
	public void operator %=(T rhs) mut
	{
		mVectorized = mVectorized % rhs;
	}

	/// @brief Adds a scalar to each component in-place.
	[Inline]
	public void operator +=(T rhs) mut
	{
		mVectorized = mVectorized + rhs;
	}

	/// @brief Subtracts a scalar from each component in-place.
	[Inline]
	public void operator -=(T rhs) mut
	{
		mVectorized = mVectorized - rhs;
	}

	/// @brief Increments all components.
	[Inline]
	public void operator ++() mut
	{
		mVectorized = mVectorized++;
	}

	/// @brief Decrements all components.
	[Inline]
	public void operator --() mut
	{
		mVectorized = mVectorized--;
	}
	#endif

	/// @brief Provides indexed access to the vector components.
	/// @param i Component index in [0, 3].
	public T this[int i]
	{
		get => elements[i];
		set mut => elements[i] = value;
	}

	/// @brief Computes the dot product with another vector.
	/// @param rhs Second operand.
	/// @returns Dot product of the two vectors.
	[Inline]
	public T DotProduct(in Self rhs) => x * rhs.x + y * rhs.y + z * rhs.z + w * rhs.w;

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
	public T Distance(Self rhs)
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
			return Zero; // return zero vector

		double invLen = 1.0 / Math.Sqrt((double)sqrMag);
		T scale = (T)invLen;

		return .(x * scale, y * scale, z * scale, w * scale);
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
		return .(x > other.x ? x : other.x, y > other.y ? y : other.y, z > other.z ? z : other.z, w > other.w ? w : other.w
			);
	}

	/// @brief Chooses the component-wise minimum between this vector and another.
	/// @param other Vector to compare.
	/// @returns Component-wise minimum.
	[Inline]
	public Self Min(in Self other)
	{
		return .(x < other.x ? x : other.x, y < other.y ? y : other.y, z < other.z ? z : other.z, w < other.w ? w : other.w
			);
	}

	/// @brief Returns the component-wise absolute value.
	/// @returns Vector whose components are absolute values of this vector.
	[Inline]
	public Self Abs()
	{
		T zero = (T)0;
		return .(x < zero ? -x : x, y < zero ? -y : y, z < zero ? -z : z, w < zero ? -w : w
			);
	}

	/// @brief Clamps each component between the corresponding components of two bounds.
	/// @param min Lower bound vector.
	/// @param max Upper bound vector.
	/// @returns Clamped vector.
	[Inline]
	public Self Clamp(in Self min, in Self max)
	{
		return .(x < min.x ? min.x : (x > max.x ? max.x : x), y < min.y ? min.y : (y > max.y ? max.y : y), z < min.z ? min.z : (z > max.z ? max.z : z), w < min.w ? min.w : (w > max.w ? max.w : w)
			);
	}

	/// @brief Clamps each component to the [0, 1] range.
	/// @returns Saturated vector.
	[Inline]
	public Self Saturate()
	{
		T zero = (T)0;
		T one = (T)1;
		return .(x < zero ? zero : (x > one ? one : x), y < zero ? zero : (y > one ? one : y), z < zero ? zero : (z > one ? one : z), w < zero ? zero : (w > one ? one : w)
			);
	}

	/// @brief Compares two vectors for component-wise equality.
	/// @param rhs Vector to compare against.
	/// @returns True when all components are equal.
	public bool Equals(Self rhs)
	{
		return x == rhs.x && y == rhs.y && z == rhs.z && w == rhs.w;
	}

	/// @brief Generates a hash code for the vector.
	/// @returns Hash code combining all components.
	public int GetHashCode()
	{
		int seed = 0;
		seed = HashCode.Mix(seed, x.GetHashCode());
		seed = HashCode.Mix(seed, y.GetHashCode());
		seed = HashCode.Mix(seed, z.GetHashCode());
		seed = HashCode.Mix(seed, w.GetHashCode());
		return seed;
	}

	/// @brief Vector with all components set to one.
	[Inline]
	public static Self One => .((T)1, (T)1, (T)1, (T)1);

	/// @brief Vector with all components set to zero.
	[Inline]
	public static Self Zero => .((T)0, (T)0, (T)0, (T)0);

	/// @brief Casts this vector to a different component type.
	/// @returns Vector with components converted to the requested type.
	public Vector4<U> Cast<U>()
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