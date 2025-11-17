using System;

namespace Sizzle.Math;

/// @brief Default float Matrix3x4 type
typealias Matrix3x4 = Matrix3x4<float>;

[Union, CRepr]
/// @brief Represents a 3x4 affine transform matrix stored as four column vectors.
struct Matrix3x4<T> : IEquatable<Self>, IHashable
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

	/// @brief Creates a matrix from individual column vectors.
	/// @param right Right (X) axis column.
	/// @param up Up (Y) axis column.
	/// @param forward Forward (Z) axis column.
	/// @param translation Translation column.
	public this(in Vector3<T> right, in Vector3<T> up, in Vector3<T> forward, in Vector3<T> translation)
	{
		this.right = right;
		this.up = up;
		this.forward = forward;
		this.translation = translation;
	}

	/// @brief Creates a 3x4 matrix from a 3x3 rotation and separate translation.
	/// @param rotation Rotation columns.
	/// @param translation Translation column.
	public this(in Matrix3x3<T> rotation, in Vector3<T> translation)
	{
		this.right = rotation.right;
		this.up = rotation.up;
		this.forward = rotation.forward;
		this.translation = translation;
	}

	/// @brief Creates a 3x4 matrix from a 3x3 rotation with zero translation.
	/// @param rotation Rotation columns.
	public this(in Matrix3x3<T> rotation)
	{
		this = Self(rotation, Vector3<T>((T)0, (T)0, (T)0));
	}

	/// @brief Creates a 3x4 matrix by truncating a 4x4 matrix.
	/// @param other Source 4x4 matrix.
	public this(in Matrix4x4<T> other)
	{
		this.right = Vector3<T>(other.right.x, other.right.y, other.right.z);
		this.up = Vector3<T>(other.up.x, other.up.y, other.up.z);
		this.forward = Vector3<T>(other.forward.x, other.forward.y, other.forward.z);
		this.translation = Vector3<T>(other.translation.x, other.translation.y, other.translation.z);
	}

	// Get a pointer to this matrix
	/// @brief Returns a pointer to the first matrix element.
	public void* AsPtr() mut => &elements[0];
	/// @brief Number of column vectors in the matrix.
	public const int VectorCount = 4;
	/// @brief Total scalar element count across all columns.
	public const int ElementCount = VectorCount * Vector3<T>.ElementCount; // 12 elements

	/// @brief Raw scalar storage laid out column-major.
	public T[ElementCount] elements;
	/// @brief Column vector storage for indexed access by column.
	public Vector3<T>[VectorCount] vectors;

	/// @brief Provides semantic column aliases (right, up, forward, translation).
	public struct
	{
		/// @brief Right (X) axis column.
		public Vector3<T> right;
		/// @brief Up (Y) axis column.
		public Vector3<T> up;
		/// @brief Forward (Z) axis column.
		public Vector3<T> forward;
		/// @brief Translation column.
		public Vector3<T> translation;
	};

	/// @brief Provides short-hand column aliases (r, u, f, t).
	public struct
	{
		/// @brief Right column shorthand.
		public Vector3<T> r;
		/// @brief Up column shorthand.
		public Vector3<T> u;
		/// @brief Forward column shorthand.
		public Vector3<T> f;
		/// @brief Translation column shorthand.
		public Vector3<T> t;
	};

	/// @brief Provides xyzw column aliases matching vector notation.
	public struct
	{
		/// @brief X column.
		public Vector3<T> x;
		/// @brief Y column.
		public Vector3<T> y;
		/// @brief Z column.
		public Vector3<T> z;
		/// @brief W column.
		public Vector3<T> w;
	};

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

	// Component-wise overloads
	/// @brief Performs component-wise division of two matrices.
	[Inline]
	public static Self operator /(in Self lhs, in Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z, lhs.w / rhs.w);

	/// @brief Performs component-wise modulo of two matrices.
	[Inline]
	public static Self operator %(in Self lhs, in Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z, lhs.w % rhs.w);

	/// @brief Performs component-wise addition of two matrices.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);

	/// @brief Performs component-wise subtraction of two matrices.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);

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

	/// @brief Negates every component of the matrix.
	[Inline]
	public static Self operator -(in Self value) => .(-value.x, -value.y, -value.z, -value.w);

	// Matrix multiplication helpers
	/// @brief Multiplies this 3x4 matrix by a 4x4 matrix.
	/// @param lhs Left-hand 3x4 matrix.
	/// @param rhs Right-hand 4x4 matrix.
	[Inline]
	public static Self operator *(in Self lhs, in Matrix4x4<T> rhs)
	{
		var lhsCopy = lhs;
		var lhs4 = Matrix4x4<T>(lhsCopy);
		var result4 = lhs4 * rhs;
		return Self(result4);
	}

	/// @brief Multiplies two 3x4 matrices by promoting them to 4x4.
	[Inline]
	public static Self operator *(in Self lhs, in Self rhs)
	{
		var lhsCopy = lhs;
		var rhsCopy = rhs;
		var lhs4 = Matrix4x4<T>(lhsCopy);
		var rhs4 = Matrix4x4<T>(rhsCopy);
		var result4 = lhs4 * rhs4;
		return Self(result4);
	}

	/// @brief Transforms a position vector by the matrix.
	/// @param lhs Transformation matrix.
	/// @param v Input position.
	/// @returns Transformed position.
	[Inline]
	public static Vector3<T> operator *(in Self lhs, in Vector3<T> v)
	{
		return Vector3<T>(
			lhs.r.x * v.x + lhs.u.x * v.y + lhs.f.x * v.z + lhs.t.x,
			lhs.r.y * v.x + lhs.u.y * v.y + lhs.f.y * v.z + lhs.t.y,
			lhs.r.z * v.x + lhs.u.z * v.y + lhs.f.z * v.z + lhs.t.z
			);
	}

	/// @brief Transforms a homogeneous vector by the matrix.
	[Inline]
	public static Vector3<T> operator *(in Self lhs, in Vector4<T> v)
	{
		return Vector3<T>(
			lhs.r.x * v.x + lhs.u.x * v.y + lhs.f.x * v.z + lhs.t.x * v.w,
			lhs.r.y * v.x + lhs.u.y * v.y + lhs.f.y * v.z + lhs.t.y * v.w,
			lhs.r.z * v.x + lhs.u.z * v.y + lhs.f.z * v.z + lhs.t.z * v.w
			);
	}

	// Compound assignment operators
	/// @brief Multiplies this matrix by another component-wise.
	[Inline]
	public void operator *=(in Self rhs) mut
	{
		x *= rhs.x; y *= rhs.y; z *= rhs.z; w *= rhs.w;
	}

	/// @brief Divides this matrix by another component-wise.
	[Inline]
	public void operator /=(in Self rhs) mut
	{
		x /= rhs.x; y /= rhs.y; z /= rhs.z; w /= rhs.w;
	}

	/// @brief Applies component-wise modulo with another matrix.
	[Inline]
	public void operator %=(in Self rhs) mut
	{
		x %= rhs.x; y %= rhs.y; z %= rhs.z; w %= rhs.w;
	}

	/// @brief Adds another matrix component-wise.
	[Inline]
	public void operator +=(in Self rhs) mut
	{
		x += rhs.x; y += rhs.y; z += rhs.z; w += rhs.w;
	}

	/// @brief Subtracts another matrix component-wise.
	[Inline]
	public void operator -=(in Self rhs) mut
	{
		x -= rhs.x; y -= rhs.y; z -= rhs.z; w -= rhs.w;
	}

	/// @brief Multiplies all components by a scalar.
	[Inline]
	public void operator *=(T rhs) mut
	{
		x *= rhs; y *= rhs; z *= rhs; w *= rhs;
	}

	/// @brief Divides all components by a scalar.
	[Inline]
	public void operator /=(T rhs) mut
	{
		x /= rhs; y /= rhs; z /= rhs; w /= rhs;
	}

	/// @brief Applies scalar modulo to all components.
	[Inline]
	public void operator %=(T rhs) mut
	{
		x %= rhs; y %= rhs; z %= rhs; w %= rhs;
	}

	/// @brief Adds a scalar to all components.
	[Inline]
	public void operator +=(T rhs) mut
	{
		x += rhs; y += rhs; z += rhs; w += rhs;
	}

	/// @brief Subtracts a scalar from all components.
	[Inline]
	public void operator -=(T rhs) mut
	{
		x -= rhs; y -= rhs; z -= rhs; w -= rhs;
	}

	/// @brief Increments every component by one.
	[Inline]
	public void operator ++() mut
	{
		x++; y++; z++; w++;
	}

	/// @brief Decrements every component by one.
	[Inline]
	public void operator --() mut
	{
		x--; y--; z--; w--;
	}

	/// @brief Promotes this matrix to a full 4x4 matrix.
	[Inline]
	public Matrix4x4<T> ToMatrix4x4()
	{
		return Matrix4x4<T>(this);
	}

	/// @brief Returns the identity 3x4 matrix.
	[Inline]
	public static Self Identity()
	{
		return .(
			.((T)1, (T)0, (T)0),
			.((T)0, (T)1, (T)0),
			.((T)0, (T)0, (T)1),
			.((T)0, (T)0, (T)0)
			);
	}

	/// @brief Creates a uniform scaling matrix.
	/// @param s Scale factors per axis.
	[Inline]
	public static Self Scale(in Vector3<T> s)
	{
		return .(
			.(s.x, (T)0, (T)0),
			.((T)0, s.y, (T)0),
			.((T)0, (T)0, s.z),
			.((T)0, (T)0, (T)0)
			);
	}

	/// @brief Creates a translation matrix.
	/// @param pos Translation vector.
	[Inline]
	public static Self Translation(in Vector3<T> pos)
	{
		return .(
			.((T)1, (T)0, (T)0),
			.((T)0, (T)1, (T)0),
			.((T)0, (T)0, (T)1),
			.(pos.x, pos.y, pos.z)
			);
	}

	/// @brief Creates a rotation matrix around the X axis.
	[Inline]
	public static Self RotationX(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			.((T)1, (T)0, (T)0),
			.((T)0, (T)c, (T)s),
			.((T)0, (T) - s, (T)c),
			.((T)0, (T)0, (T)0)
			);
	}

	/// @brief Creates a rotation matrix around the Y axis.
	[Inline]
	public static Self RotationY(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			.((T)c, (T)0, (T) - s),
			.((T)0, (T)1, (T)0),
			.((T)s, (T)0, (T)c),
			.((T)0, (T)0, (T)0)
			);
	}

	/// @brief Creates a rotation matrix around the Z axis.
	[Inline]
	public static Self RotationZ(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			.((T)c, (T)s, (T)0),
			.((T) - s, (T)c, (T)0),
			.((T)0, (T)0, (T)1),
			.((T)0, (T)0, (T)0)
			);
	}

	/// @brief Creates a rotation matrix for an arbitrary axis.
	[Inline]
	public static Self RotateAxis(in Vector3<T> axis, T angle)
	{
		var axisNorm = axis.Normalized();
		T c = (T)Math.Cos(angle);
		T s = (T)Math.Sin(angle);
		T oneMinusC = (T)1 - c;

		T x = axisNorm.x, y = axisNorm.y, z = axisNorm.z;

		return .(
			.(x * x * oneMinusC + c,     y * x * oneMinusC + z * s, z * x * oneMinusC - y * s),
			.(x * y * oneMinusC - z * s,   y * y * oneMinusC + c,   z * y * oneMinusC + x * s),
			.(x * z * oneMinusC + y * s,   y * z * oneMinusC - x * s, z * z * oneMinusC + c),
			.((T)0, (T)0, (T)0)
			);
	}

	/// @brief Builds a look-at matrix for transforming from world to view space.
	[Inline]
	public static Self LookAt(in Vector3<T> eye, in Vector3<T> center, in Vector3<T> up)
	{
		Vector3<T> fwd = (center - eye).Normalized();
		Vector3<T> right = fwd.CrossProduct(up).Normalized();
		Vector3<T> realUp = right.CrossProduct(fwd);

		let xTran = -right.DotProduct(eye);
		let yTran = -realUp.DotProduct(eye);
		let zTran = fwd.DotProduct(eye);

		return .(
			.(right.x, realUp.x, -fwd.x),
			.(right.y, realUp.y, -fwd.y),
			.(right.z, realUp.z, -fwd.z),
			.(xTran, yTran, zTran)
			);
	}

	/// @brief Replaces the contents of this matrix with a translation/rotation/scale transform.
	/// @param position Translation component written into the last column.
	/// @param rotation Rotation applied prior to scaling.
	/// @param scale Non-uniform scale applied along the rotated basis axes.
	[Inline]
	public void SetTRS(in Vector3<T> position, in Quaternion<T> rotation, in Vector3<T> scale) mut
	{
		var rot = rotation.ToMatrix3x3();
		right = rot.right * scale.x;
		up = rot.up * scale.y;
		forward = rot.forward * scale.z;
		this.translation = position;
	}

	/// @brief Constructs a new matrix from translation, rotation, and scale components.
	/// @param position Translation component.
	/// @param rotation Rotation component.
	/// @param scale Scale component.
	/// @returns Matrix representing the composed TRS transform.
	[Inline]
	public static Self TRS(in Vector3<T> position, in Quaternion<T> rotation, in Vector3<T> scale)
	{
		var result = Self.Identity();
		result.SetTRS(position, rotation, scale);
		return result;
	}

	/// @brief Tests whether this matrix contains a valid, non-degenerate TRS transform.
	/// @returns True when translation, rotation, and scale can be extracted reliably.
	public bool ValidTRS()
	{
		if (!IsFiniteVector(ExtractPosition()))
			return false;

		Matrix3x3<T> rotation;
		Vector3<T> scale;
		DecomposeRotationScale(out rotation, out scale);

		if (!IsFiniteVector(scale) || !HasValidScale(scale))
			return false;

		return IsOrthonormal(rotation);
	}

	/// @brief Extracts the translation component from this transform.
	/// @returns Translation column as a 3D vector.
	[Inline]
	public Vector3<T> ExtractPosition() => translation;

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

	/// @brief Linearly interpolates between this matrix and a target.
	[Inline]
	public Self Lerp(in Self target, T t)
	{
		return this + (target - this) * t;
	}

	/// @brief Returns the component-wise maximum between this and another matrix.
	[Inline]
	public Self Max(in Self other)
	{
		return .(
			x.Max(other.x),
			y.Max(other.y),
			z.Max(other.z),
			w.Max(other.w)
			);
	}

	/// @brief Returns the component-wise minimum between this and another matrix.
	[Inline]
	public Self Min(in Self other)
	{
		return .(
			x.Min(other.x),
			y.Min(other.y),
			z.Min(other.z),
			w.Min(other.w)
			);
	}

	/// @brief Takes the absolute value of every component.
	[Inline]
	public Self Abs()
	{
		return .(
			x.Abs(),
			y.Abs(),
			z.Abs(),
			w.Abs()
			);
	}

	/// @brief Clamps each component between the respective min and max matrices.
	[Inline]
	public Self Clamp(in Self min, in Self max)
	{
		return .(
			x.Clamp(min.x, max.x),
			y.Clamp(min.y, max.y),
			z.Clamp(min.z, max.z),
			w.Clamp(min.w, max.w)
			);
	}

	/// @brief Clamps all components to the [0, 1] range.
	[Inline]
	public Self Saturate()
	{
		return Clamp(Self.Zero, Self.One);
	}

	/// @brief Transforms a position vector including translation.
	[Inline]
	public Vector3<T> TransformPoint(in Vector3<T> point)
	{
		return this * point;
	}

	/// @brief Transforms a direction vector without translation.
	[Inline]
	public Vector3<T> TransformVector(in Vector3<T> vector)
	{
		return Vector3<T>(
			r.x * vector.x + u.x * vector.y + f.x * vector.z,
			r.y * vector.x + u.y * vector.y + f.y * vector.z,
			r.z * vector.x + u.z * vector.y + f.z * vector.z
			);
	}

	/// @brief Gets a matrix filled with zeros.
	[Inline]
	public static Self Zero => .(Vector3<T>.Zero, Vector3<T>.Zero, Vector3<T>.Zero, Vector3<T>.Zero);

	/// @brief Gets a matrix filled with ones.
	[Inline]
	public static Self One => .(Vector3<T>.One, Vector3<T>.One, Vector3<T>.One, Vector3<T>.One);

	/// @brief Determines whether two matrices are equal.
	public bool Equals(Self rhs)
	{
		return x.Equals(rhs.x) && y.Equals(rhs.y) && z.Equals(rhs.z) && w.Equals(rhs.w);
	}

	/// @brief Generates a hash code for this matrix.
	public int GetHashCode()
	{
		int hash = 0;
		hash = HashCode.Mix(hash, x.GetHashCode());
		hash = HashCode.Mix(hash, y.GetHashCode());
		hash = HashCode.Mix(hash, z.GetHashCode());
		hash = HashCode.Mix(hash, w.GetHashCode());
		return hash;
	}

	/// @brief Casts this matrix to an equivalent matrix with a different component type.
	/// @returns Matrix with each column converted to the requested type.
	public Matrix3x4<U> Cast<U>()
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
		return .(right.Cast<U>(), up.Cast<U>(), forward.Cast<U>(), translation.Cast<U>());
	}

	private const double kTrsEpsilon = 1e-6;

	private void DecomposeRotationScale(out Matrix3x3<T> rotation, out Vector3<T> scale)
	{
		Vector3<T> rightVec = Vector3<T>(r.x, r.y, r.z);
		Vector3<T> upVec = Vector3<T>(u.x, u.y, u.z);
		Vector3<T> forwardVec = Vector3<T>(f.x, f.y, f.z);

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