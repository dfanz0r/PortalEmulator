using System;

namespace Sizzle.Math;

/// @brief Default float Matrix3x3 type
typealias Matrix3x3 = Matrix3x3<float>;

/// @brief Represents a 3x3 matrix stored as three column vectors.
[Union, CRepr]
struct Matrix3x3<T> : IEquatable<Self>, IHashable
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
	/// @brief Returns a pointer to the first matrix element.
	public void* AsPtr() mut => &elements[0];
	/// @brief Number of column vectors in the matrix.
	public const int VectorCount = 3;
	/// @brief Total scalar element count across all columns.
	public const int ElementCount = VectorCount * Vector3<T>.ElementCount; // 9 elements

	/// @brief Raw scalar storage laid out column-major.
	public T[ElementCount] elements;
	/// @brief Column vector storage for indexed access by column.
	public Vector3<T>[VectorCount] vectors;

	/// @brief Provides semantic column aliases (right, up, forward).
	public struct
	{
		/// @brief Right (X) axis column.
		public Vector3<T> right;
		/// @brief Up (Y) axis column.
		public Vector3<T> up;
		/// @brief Forward (Z) axis column.
		public Vector3<T> forward;
	};

	/// @brief Provides short-hand column aliases (r, u, f).
	public struct
	{
		/// @brief Right column shorthand.
		public Vector3<T> r;
		/// @brief Up column shorthand.
		public Vector3<T> u;
		/// @brief Forward column shorthand.
		public Vector3<T> f;
	};

	/// @brief Provides xyz column aliases matching vector notation.
	public struct
	{
		/// @brief X column.
		public Vector3<T> x;
		/// @brief Y column.
		public Vector3<T> y;
		/// @brief Z column.
		public Vector3<T> z;
	};

	/// @brief Creates a 3x3 matrix from individual column vectors.
	/// @param x X axis column.
	/// @param y Y axis column.
	/// @param z Z axis column.
	public this(Vector3<T> x, Vector3<T> y, Vector3<T> z)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/// @brief Creates a 3x3 matrix from a 4x4 matrix, dropping translation row/column.
	/// @param other Source 4x4 matrix.
	public this(in Matrix4x4<T> other)
	{
		this.x = .(other.x.x, other.x.y, other.x.z);
		this.y = .(other.y.x, other.y.y, other.y.z);
		this.z = .(other.z.x, other.z.y, other.z.z);
	}

	/// @brief Creates a 3x3 matrix from the rotation portion of a 3x4 matrix.
	/// @param other Source 3x4 matrix.
	public this(in Matrix3x4<T> other)
	{
		this.x = other.x;
		this.y = other.y;
		this.z = other.z;
	}

	/// @brief Creates a copy of another 3x3 matrix.
	/// @param other Source matrix.
	public this(in Self other)
	{
		this.x = other.x;
		this.y = other.y;
		this.z = other.z;
	}

	/// @brief Provides raw indexed access to the matrix elements.
	/// @param i Element index.
	public T this[int i]
	{
		get => elements[i];
		set mut => elements[i] = value;
	}

	/// @brief Provides access to a specific column/row element.
	/// @param i Column index.
	/// @param j Row index.
	public T this[int i, int j]
	{
		get => vectors[i][j];
		set mut => vectors[i][j] = value;
	}

	/// @brief Component-wise addition of two matrices.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);

	/// @brief Component-wise subtraction of two matrices.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);

	/// @brief Component-wise division of two matrices.
	[Inline]
	public static Self operator /(in Self lhs, in Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z);

	/// @brief Component-wise modulo of two matrices.
	[Inline]
	public static Self operator %(in Self lhs, in Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z);

	/// @brief Multiplies each component by a scalar.
	[Inline]
	public static Self operator *(in Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs);

	/// @brief Divides each component by a scalar.
	[Inline]
	public static Self operator /(in Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs);

	/// @brief Adds a scalar to each component.
	[Inline]
	public static Self operator +(in Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs);

	/// @brief Subtracts a scalar from each component.
	[Inline]
	public static Self operator -(in Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs);

	/// @brief Negates every component of the matrix.
	[Inline]
	public static Self operator -(in Self value) => .(-value.x, -value.y, -value.z);

	/// @brief Multiplies two 3x3 matrices.
	/// @param lhs Left-hand matrix.
	/// @param rhs Right-hand matrix.
	[Inline]
	public static Self Multiply(in Self lhs, in Self rhs)
	{
		return .(
			Vector3<T>(
			lhs.r.x * rhs.r.x + lhs.u.x * rhs.r.y + lhs.f.x * rhs.r.z,
			lhs.r.y * rhs.r.x + lhs.u.y * rhs.r.y + lhs.f.y * rhs.r.z,
			lhs.r.z * rhs.r.x + lhs.u.z * rhs.r.y + lhs.f.z * rhs.r.z
			),
			Vector3<T>(
			lhs.r.x * rhs.u.x + lhs.u.x * rhs.u.y + lhs.f.x * rhs.u.z,
			lhs.r.y * rhs.u.x + lhs.u.y * rhs.u.y + lhs.f.y * rhs.u.z,
			lhs.r.z * rhs.u.x + lhs.u.z * rhs.u.y + lhs.f.z * rhs.u.z
			),
			Vector3<T>(
			lhs.r.x * rhs.f.x + lhs.u.x * rhs.f.y + lhs.f.x * rhs.f.z,
			lhs.r.y * rhs.f.x + lhs.u.y * rhs.f.y + lhs.f.y * rhs.f.z,
			lhs.r.z * rhs.f.x + lhs.u.z * rhs.f.y + lhs.f.z * rhs.f.z
			)
			);
	}

	/// @brief Multiplies two 3x3 matrices.
	[Inline]
	public static Self operator *(in Self lhs, in Self rhs) => Multiply(lhs, rhs);

	/// @brief Transforms a vector by this matrix treating it as a basis change.
	/// @param lhs Matrix operand.
	/// @param v Vector operand.
	[Inline]
	public static Vector3<T> operator *(in Self lhs, in Vector3<T> v)
	{
		return .(
			lhs.r.x * v.x + lhs.u.x * v.y + lhs.f.x * v.z,
			lhs.r.y * v.x + lhs.u.y * v.y + lhs.f.y * v.z,
			lhs.r.z * v.x + lhs.u.z * v.y + lhs.f.z * v.z
			);
	}

	/// @brief Compound assignment applying matrix multiplication.
	[Inline]
	public void operator *=(in Self rhs) mut
	{
		this = Multiply(this, rhs);
	}

	/// @brief Adds another matrix component-wise.
	[Inline]
	public void operator +=(in Self rhs) mut
	{
		x += rhs.x; y += rhs.y; z += rhs.z;
	}

	/// @brief Subtracts another matrix component-wise.
	[Inline]
	public void operator -=(in Self rhs) mut
	{
		x -= rhs.x; y -= rhs.y; z -= rhs.z;
	}

	/// @brief Multiplies each component by a scalar in-place.
	[Inline]
	public void operator *=(T rhs) mut
	{
		x *= rhs; y *= rhs; z *= rhs;
	}

	/// @brief Divides each component by a scalar in-place.
	[Inline]
	public void operator /=(T rhs) mut
	{
		x /= rhs; y /= rhs; z /= rhs;
	}

	/// @brief Adds a scalar to each component in-place.
	[Inline]
	public void operator +=(T rhs) mut
	{
		x += rhs; y += rhs; z += rhs;
	}

	/// @brief Subtracts a scalar from each component in-place.
	[Inline]
	public void operator -=(T rhs) mut
	{
		x -= rhs; y -= rhs; z -= rhs;
	}

	/// @brief Computes the determinant of the matrix.
	/// @returns Scalar determinant value.
	[Inline]
	public T Determinant()
	{
		return x.x * (y.y * z.z - y.z * z.y)
			- x.y * (y.x * z.z - y.z * z.x)
			+ x.z * (y.x * z.y - y.y * z.x);
	}

	/// @brief Computes the transpose of this matrix.
	/// @returns Matrix with rows and columns swapped.
	[Inline]
	public Self Transposed()
	{
		return .(
			Vector3<T>(r.x, u.x, f.x),
			Vector3<T>(r.y, u.y, f.y),
			Vector3<T>(r.z, u.z, f.z)
			);
	}

	/// @brief Computes the inverse of this matrix.
	/// @returns Inverse matrix when determinant is non-zero, otherwise zero matrix.
	public Self Inverted()
	{
		T det = Determinant();
		if (det == default)
			return Zero;

		double invDet = 1.0 / (double)det;

		return .(
			Vector3<T>(
			(T)((y.y * z.z - y.z * z.y) * invDet),
			(T)((x.z * z.y - x.y * z.z) * invDet),
			(T)((x.y * y.z - x.z * y.y) * invDet)
			),
			Vector3<T>(
			(T)((y.z * z.x - y.x * z.z) * invDet),
			(T)((x.x * z.z - x.z * z.x) * invDet),
			(T)((x.z * y.x - x.x * y.z) * invDet)
			),
			Vector3<T>(
			(T)((y.x * z.y - y.y * z.x) * invDet),
			(T)((x.y * z.x - x.x * z.y) * invDet),
			(T)((x.x * y.y - x.y * y.x) * invDet)
			)
			);
	}

	/// @brief Creates a uniform or non-uniform scale matrix.
	/// @param s Scale factors per axis.
	[Inline]
	public static Self Scale(in Vector3<T> s)
	{
		return .(
			Vector3<T>(s.x, (T)0, (T)0),
			Vector3<T>((T)0, s.y, (T)0),
			Vector3<T>((T)0, (T)0, s.z)
			);
	}

	/// @brief Builds a rotation matrix about the X axis.
	/// @param radians Angle in radians.
	[Inline]
	public static Self RotationX(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			Vector3<T>((T)1, (T)0, (T)0),
			Vector3<T>((T)0, (T)c, (T)s),
			Vector3<T>((T)0, (T) - s, (T)c)
			);
	}

	/// @brief Builds a rotation matrix about the Y axis.
	/// @param radians Angle in radians.
	[Inline]
	public static Self RotationY(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			Vector3<T>((T)c, (T)0, (T) - s),
			Vector3<T>((T)0, (T)1, (T)0),
			Vector3<T>((T)s, (T)0, (T)c)
			);
	}

	/// @brief Builds a rotation matrix about the Z axis.
	/// @param radians Angle in radians.
	[Inline]
	public static Self RotationZ(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			Vector3<T>((T)c, (T)s, (T)0),
			Vector3<T>((T) - s, (T)c, (T)0),
			Vector3<T>((T)0, (T)0, (T)1)
			);
	}

	/// @brief Creates a rotation matrix for an arbitrary axis.
	/// @param axis Axis of rotation.
	/// @param angle Angle in radians.
	[Inline]
	public static Self RotateAxis(in Vector3<T> axis, T angle)
	{
		var axisNorm = axis.Normalized();
		double c = Math.Cos((double)angle);
		double s = Math.Sin((double)angle);
		double oneMinusC = 1.0 - c;

		double x = (double)axisNorm.x;
		double y = (double)axisNorm.y;
		double z = (double)axisNorm.z;

		return .(
			Vector3<T>((T)(x * x * oneMinusC + c),     (T)(y * x * oneMinusC + z * s), (T)(z * x * oneMinusC - y * s)),
			Vector3<T>((T)(x * y * oneMinusC - z * s), (T)(y * y * oneMinusC + c),     (T)(z * y * oneMinusC + x * s)),
			Vector3<T>((T)(x * z * oneMinusC + y * s), (T)(y * z * oneMinusC - x * s), (T)(z * z * oneMinusC + c))
			);
	}

	/// @brief Replaces this matrix with a rotation/scale transform (translation is ignored for 3x3 matrices).
	/// @param position Translation component (discarded).
	/// @param rotation Rotation applied prior to scaling.
	/// @param scale Non-uniform scale applied along the rotated basis axes.
	[Inline]
	public void SetTRS(in Vector3<T> position, in Quaternion<T> rotation, in Vector3<T> scale) mut
	{
		var rot = rotation.ToMatrix3x3();
		x = rot.x * scale.x;
		y = rot.y * scale.y;
		z = rot.z * scale.z;
	}

	/// @brief Constructs a new matrix from translation, rotation, and scale (translation ignored).
	/// @param position Translation component (discarded).
	/// @param rotation Rotation component.
	/// @param scale Scale component.
	/// @returns Matrix representing the composed rotation and scale.
	[Inline]
	public static Self TRS(in Vector3<T> position, in Quaternion<T> rotation, in Vector3<T> scale)
	{
		var result = Identity;
		result.SetTRS(position, rotation, scale);
		return result;
	}

	/// @brief Tests whether this matrix encodes a valid, non-degenerate rotation/scale transform.
	/// @returns True when rotation and scale can be decomposed safely.
	public bool ValidTRS()
	{
		Matrix3x3<T> rotation;
		Vector3<T> scale;
		DecomposeRotationScale(out rotation, out scale);

		if (!IsFiniteVector(scale) || !HasValidScale(scale))
			return false;

		return IsOrthonormal(rotation);
	}

	/// @brief Extracts the translation component (always zero for 3x3 matrices).
	/// @returns Zero vector since 3x3 matrices do not encode translation.
	[Inline]
	public Vector3<T> ExtractPosition()
	{
		return Vector3<T>.Zero;
	}

	/// @brief Extracts the scale component from this transform.
	/// @returns Non-uniform scale along each basis axis.
	public Vector3<T> ExtractScale()
	{
		Matrix3x3<T> rotation;
		Vector3<T> scale;
		DecomposeRotationScale(out rotation, out scale);
		return scale;
	}

	/// @brief Extracts the rotation component from this transform.
	/// @returns Quaternion representing the rotational part of the transform.
	public Quaternion<T> ExtractRotation()
	{
		Matrix3x3<T> rotation;
		Vector3<T> scale;
		DecomposeRotationScale(out rotation, out scale);
		if (!HasValidScale(scale))
			return Quaternion<T>.Identity;
		return Quaternion<T>.FromMatrix(rotation);
	}

	/// @brief Tests equality by comparing each column vector.
	public bool Equals(Self rhs)
	{
		return x.Equals(rhs.x) && y.Equals(rhs.y) && z.Equals(rhs.z);
	}

	/// @brief Generates a hash code for the matrix.
	public int GetHashCode()
	{
		int hash = 0;
		hash = HashCode.Mix(hash, x.GetHashCode());
		hash = HashCode.Mix(hash, y.GetHashCode());
		hash = HashCode.Mix(hash, z.GetHashCode());
		return hash;
	}

	/// @brief Identity matrix.
	[Inline]
	public static Self Identity => .(
		Vector3<T>((T)1, (T)0, (T)0),
		Vector3<T>((T)0, (T)1, (T)0),
		Vector3<T>((T)0, (T)0, (T)1)
		);

	/// @brief Zero matrix (all components set to zero).
	[Inline]
	public static Self Zero => .(
		Vector3<T>((T)0, (T)0, (T)0),
		Vector3<T>((T)0, (T)0, (T)0),
		Vector3<T>((T)0, (T)0, (T)0)
		);

	/// @brief Casts this matrix to an equivalent matrix with a different component type.
	/// @returns Matrix with each column converted to the requested type.
	public Matrix3x3<U> Cast<U>()
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
		return .(x.Cast<U>(), y.Cast<U>(), z.Cast<U>());
	}

	private const double kTrsEpsilon = 1e-6;

	private void DecomposeRotationScale(out Matrix3x3<T> rotation, out Vector3<T> scale)
	{
		Vector3<T> rightVec = x;
		Vector3<T> upVec = y;
		Vector3<T> forwardVec = z;

		double sx = (double)rightVec.Magnitude();
		double sy = (double)upVec.Magnitude();
		double sz = (double)forwardVec.Magnitude();

		Vector3<T> rotRight = sx > kTrsEpsilon ? rightVec / (T)sx : Vector3<T>.Zero;
		Vector3<T> rotUp = sy > kTrsEpsilon ? upVec / (T)sy : Vector3<T>.Zero;
		Vector3<T> rotForward = sz > kTrsEpsilon ? forwardVec / (T)sz : Vector3<T>.Zero;

		double det = (double)rotRight.x * ((double)rotUp.y * (double)rotForward.z - (double)rotUp.z * (double)rotForward.y)
			- (double)rotRight.y * ((double)rotUp.x * (double)rotForward.z - (double)rotUp.z * (double)rotForward.x)
			+ (double)rotRight.z * ((double)rotUp.x * (double)rotForward.y - (double)rotUp.y * (double)rotForward.x);

		if (det < 0.0)
		{
			sx = -sx;
			rotRight *= (T)(-1);
		}

		rotation = Matrix3x3<T>(rotRight, rotUp, rotForward);
		scale = Vector3<T>((T)sx, (T)sy, (T)sz);
	}

	private static bool IsFiniteValue(T value)
	{
		double d = (double)value;
		return !d.IsNaN && !d.IsInfinity;
	}

	private static bool IsFiniteVector(in Vector3<T> vec)
	{
		return IsFiniteValue(vec.x) && IsFiniteValue(vec.y) && IsFiniteValue(vec.z);
	}

	private static bool NearlyEqual(double a, double b, double epsilon)
	{
		return Math.Abs(a - b) <= epsilon;
	}

	private static bool HasValidScale(in Vector3<T> scale)
	{
		return Math.Abs((double)scale.x) > kTrsEpsilon
			&& Math.Abs((double)scale.y) > kTrsEpsilon
			&& Math.Abs((double)scale.z) > kTrsEpsilon;
	}

	private static bool IsOrthonormal(in Matrix3x3<T> rotation)
	{
		double tolerance = kTrsEpsilon * 10.0;
		double dotXY = (double)rotation.r.DotProduct(rotation.u);
		double dotXZ = (double)rotation.r.DotProduct(rotation.f);
		double dotYZ = (double)rotation.u.DotProduct(rotation.f);

		if (Math.Abs(dotXY) > tolerance || Math.Abs(dotXZ) > tolerance || Math.Abs(dotYZ) > tolerance)
			return false;

		double lenX = (double)rotation.r.SquaredMagnitude();
		double lenY = (double)rotation.u.SquaredMagnitude();
		double lenZ = (double)rotation.f.SquaredMagnitude();

		if (!NearlyEqual(lenX, 1.0, tolerance) || !NearlyEqual(lenY, 1.0, tolerance) || !NearlyEqual(lenZ, 1.0, tolerance))
			return false;

		double det = (double)rotation.r.x * ((double)rotation.u.y * (double)rotation.f.z - (double)rotation.u.z * (double)rotation.f.y)
			- (double)rotation.r.y * ((double)rotation.u.x * (double)rotation.f.z - (double)rotation.u.z * (double)rotation.f.x)
			+ (double)rotation.r.z * ((double)rotation.u.x * (double)rotation.f.y - (double)rotation.u.y * (double)rotation.f.x);

		return det > 0.0;
	}
}
