using System;

namespace Sizzle.Math;

/// @brief Default float Matrix4x4 type
typealias Matrix4x4 = Matrix4x4<float>;

[Union, CRepr]
/// @brief Represents a 4x4 homogeneous transform matrix stored as four column vectors.
struct Matrix4x4<T> : IEquatable<Self>, IHashable
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

	/// @brief Creates a 4x4 matrix by promoting a 3x4 matrix.
	/// @param other Source 3x4 matrix.
	public this(in Matrix3x4<T> other)
	{
		this.x = Vector4<T>(other.x, (T)0);
		this.y = Vector4<T>(other.y, (T)0);
		this.z = Vector4<T>(other.z, (T)0);
		this.w = Vector4<T>(other.w, (T)1);
	}

	/// @brief Creates a 4x4 matrix from individual column vectors.
	/// @param x Right (X) axis column.
	/// @param y Up (Y) axis column.
	/// @param z Forward (Z) axis column.
	/// @param w Translation column.
	public this(in Vector4<T> x, in Vector4<T> y, in Vector4<T> z, in Vector4<T> w)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	/// @brief Creates a 4x4 matrix from a 3x3 rotation with explicit translation.
	/// @param rotation Rotation columns.
	/// @param translation Translation vector.
	public this(in Matrix3x3<T> rotation, in Vector3<T> translation)
	{
		this.x = Vector4<T>(rotation.x.x, rotation.x.y, rotation.x.z, (T)0);
		this.y = Vector4<T>(rotation.y.x, rotation.y.y, rotation.y.z, (T)0);
		this.z = Vector4<T>(rotation.z.x, rotation.z.y, rotation.z.z, (T)0);
		this.w = Vector4<T>(translation.x, translation.y, translation.z, (T)1);
	}

	/// @brief Creates a 4x4 matrix from a 3x3 rotation with zero translation.
	/// @param rotation Rotation columns.
	public this(in Matrix3x3<T> rotation)
	{
		this = Self(rotation, Vector3<T>((T)0, (T)0, (T)0));
	}

	// Component-wise overloads
	/// @brief Performs component-wise addition of two matrices.
	[Inline]
	public static Self operator +(in Self lhs, in Self rhs) => .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
	/// @brief Performs component-wise subtraction of two matrices.
	[Inline]
	public static Self operator -(in Self lhs, in Self rhs) => .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
	/// @brief Performs component-wise division of two matrices.
	[Inline]
	public static Self operator /(in Self lhs, in Self rhs) => .(lhs.x / rhs.x, lhs.y / rhs.y, lhs.z / rhs.z, lhs.w / rhs.w);
	/// @brief Performs component-wise modulo of two matrices.
	[Inline]
	public static Self operator %(in Self lhs, in Self rhs) => .(lhs.x % rhs.x, lhs.y % rhs.y, lhs.z % rhs.z, lhs.w % rhs.w);

	/// @brief Adds a scalar to each component.
	[Inline]
	public static Self operator +(in Self lhs, T rhs) => .(lhs.x + rhs, lhs.y + rhs, lhs.z + rhs, lhs.w + rhs);
	/// @brief Subtracts a scalar from each component.
	[Inline]
	public static Self operator -(in Self lhs, T rhs) => .(lhs.x - rhs, lhs.y - rhs, lhs.z - rhs, lhs.w - rhs);
	/// @brief Multiplies each component by a scalar.
	[Inline]
	public static Self operator *(in Self lhs, T rhs) => .(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs);
	/// @brief Divides each component by a scalar.
	[Inline]
	public static Self operator /(in Self lhs, T rhs) => .(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs, lhs.w / rhs);
	/// @brief Applies scalar modulo to each component.
	[Inline]
	public static Self operator %(in Self lhs, T rhs) => .(lhs.x % rhs, lhs.y % rhs, lhs.z % rhs, lhs.w % rhs);

	/// @brief Negates every component of the matrix.
	[Inline]
	public static Self operator -(in Self val) => .(-val.x, -val.y, -val.z, -val.w);

	// Instance component-wise operators
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

	/// @brief Divides by another matrix component-wise.
	[Inline]
	public void operator /=(in Self rhs) mut
	{
		x /= rhs.x; y /= rhs.y; z /= rhs.z; w /= rhs.w;
	}

	/// @brief Applies component-wise modulo by another matrix.
	[Inline]
	public void operator %=(in Self rhs) mut
	{
		x %= rhs.x; y %= rhs.y; z %= rhs.z; w %= rhs.w;
	}

	/// @brief Adds a scalar to each component in-place.
	[Inline]
	public void operator +=(T rhs) mut
	{
		x += rhs; y += rhs; z += rhs; w += rhs;
	}

	/// @brief Subtracts a scalar from each component in-place.
	[Inline]
	public void operator -=(T rhs) mut
	{
		x -= rhs; y -= rhs; z -= rhs; w -= rhs;
	}

	/// @brief Multiplies each component by a scalar in-place.
	[Inline]
	public void operator *=(T rhs) mut
	{
		x *= rhs; y *= rhs; z *= rhs; w *= rhs;
	}

	/// @brief Divides each component by a scalar in-place.
	[Inline]
	public void operator /=(T rhs) mut
	{
		x /= rhs; y /= rhs; z /= rhs; w /= rhs;
	}

	/// @brief Applies scalar modulo to each component in-place.
	[Inline]
	public void operator %=(T rhs) mut
	{
		x %= rhs; y %= rhs; z %= rhs; w %= rhs;
	}

	/// @brief Increments each component.
	[Inline]
	public void operator ++() mut
	{
		x++; y++; z++; w++;
	}

	/// @brief Decrements each component.
	[Inline]
	public void operator --() mut
	{
		x--; y--; z--; w--;
	}

	/// @brief Converts this matrix to a 3x4 matrix by dropping the homogeneous row.
	[Inline]
	public Matrix3x4<T> ToMatrix3x4()
	{
		return Matrix3x4<T>(
			Vector3<T>(r.x, r.y, r.z),
			Vector3<T>(u.x, u.y, u.z),
			Vector3<T>(f.x, f.y, f.z),
			Vector3<T>(t.x, t.y, t.z)
			);
	}

	// Get a pointer to this matrix
	/// @brief Returns a pointer to the first matrix element.
	public void* AsPtr() mut => &elements[0];
	/// @brief Number of column vectors in the matrix.
	public const int VectorCount = 4;
	/// @brief Total scalar element count across all columns.
	public const int ElementCount = VectorCount * Vector4<T>.ElementCount; // 16 elements

	/// @brief Raw scalar storage laid out column-major.
	public T[ElementCount] elements;
	/// @brief Column vector storage for indexed access by column.
	public Vector4<T>[VectorCount] vectors;

	/// @brief Provides semantic column aliases (right, up, forward, translation).
	public struct
	{
		/// @brief Right (X) axis column.
		public Vector4<T> right;
		/// @brief Up (Y) axis column.
		public Vector4<T> up;
		/// @brief Forward (Z) axis column.
		public Vector4<T> forward;
		/// @brief Translation column (position, homogeneous component).
		public Vector4<T> translation;
	};

	/// @brief Provides short-hand column aliases (r, u, f, t).
	public struct
	{
		/// @brief Right column shorthand.
		public Vector4<T> r;
		/// @brief Up column shorthand.
		public Vector4<T> u;
		/// @brief Forward column shorthand.
		public Vector4<T> f;
		/// @brief Translation column shorthand.
		public Vector4<T> t;
	};

	/// @brief Provides xyzw column aliases matching vector notation.
	public struct
	{
		/// @brief X column.
		public Vector4<T> x;
		/// @brief Y column.
		public Vector4<T> y;
		/// @brief Z column.
		public Vector4<T> z;
		/// @brief W column.
		public Vector4<T> w;
	};

	/// @brief Transforms a 4D vector by this matrix.
	/// @param m Matrix operand.
	/// @param v Vector operand.
	[Inline]
	public static Vector4<T> operator *(in Self m, in Vector4<T> v)
	{
		return .(
			m.r.x * v.x + m.u.x * v.y + m.f.x * v.z + m.t.x * v.w,
			m.r.y * v.x + m.u.y * v.y + m.f.y * v.z + m.t.y * v.w,
			m.r.z * v.x + m.u.z * v.y + m.f.z * v.z + m.t.z * v.w,
			m.r.w * v.x + m.u.w * v.y + m.f.w * v.z + m.t.w * v.w
			);
	}

	/// @brief Transforms a 3D point (implicitly w = 1) by this matrix.
	/// @param m Matrix operand.
	/// @param v Vector operand.
	/// @returns Transformed point after homogeneous divide when needed.
	[Inline]
	public static Vector3<T> operator *(in Self m, in Vector3<T> v)
	{
		return m.TransformPoint(v);
	}

	/// @brief Multiplies two 4x4 matrices.
	/// @param a Left-hand matrix.
	/// @param b Right-hand matrix.
	[Inline]
	public static Self operator *(in Self a, in Self b)
	{
		return .(
			.(
			a.r.x * b.r.x + a.u.x * b.r.y + a.f.x * b.r.z + a.t.x * b.r.w,
			a.r.y * b.r.x + a.u.y * b.r.y + a.f.y * b.r.z + a.t.y * b.r.w,
			a.r.z * b.r.x + a.u.z * b.r.y + a.f.z * b.r.z + a.t.z * b.r.w,
			a.r.w * b.r.x + a.u.w * b.r.y + a.f.w * b.r.z + a.t.w * b.r.w
			),
			.(
			a.r.x * b.u.x + a.u.x * b.u.y + a.f.x * b.u.z + a.t.x * b.u.w,
			a.r.y * b.u.x + a.u.y * b.u.y + a.f.y * b.u.z + a.t.y * b.u.w,
			a.r.z * b.u.x + a.u.z * b.u.y + a.f.z * b.u.z + a.t.z * b.u.w,
			a.r.w * b.u.x + a.u.w * b.u.y + a.f.w * b.u.z + a.t.w * b.u.w
			),
			.(
			a.r.x * b.f.x + a.u.x * b.f.y + a.f.x * b.f.z + a.t.x * b.f.w,
			a.r.y * b.f.x + a.u.y * b.f.y + a.f.y * b.f.z + a.t.y * b.f.w,
			a.r.z * b.f.x + a.u.z * b.f.y + a.f.z * b.f.z + a.t.z * b.f.w,
			a.r.w * b.f.x + a.u.w * b.f.y + a.f.w * b.f.z + a.t.w * b.f.w
			),
			.(
			a.r.x * b.t.x + a.u.x * b.t.y + a.f.x * b.t.z + a.t.x * b.t.w,
			a.r.y * b.t.x + a.u.y * b.t.y + a.f.y * b.t.z + a.t.y * b.t.w,
			a.r.z * b.t.x + a.u.z * b.t.y + a.f.z * b.t.z + a.t.z * b.t.w,
			a.r.w * b.t.x + a.u.w * b.t.y + a.f.w * b.t.z + a.t.w * b.t.w
			)
			);
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

	/// @brief Transposes the matrix by swapping rows and columns.
	[Inline]
	public Matrix4x4<T> Transposed()
	{
		return .(
			.(r.x, u.x, f.x, t.x),
			.(r.y, u.y, f.y, t.y),
			.(r.z, u.z, f.z, t.z),
			.(r.w, u.w, f.w, t.w)
			);
	}

	/// @brief Tests equality by comparing each column vector.
	public bool Equals(Self rhs)
	{
		return x.Equals(rhs.x) && y.Equals(rhs.y) && z.Equals(rhs.z) && w.Equals(rhs.w);
	}

	/// @brief Computes a combined hash code for all columns.
	public int GetHashCode()
	{
		int hash = 0;
		hash = HashCode.Mix(hash, x.GetHashCode());
		hash = HashCode.Mix(hash, y.GetHashCode());
		hash = HashCode.Mix(hash, z.GetHashCode());
		hash = HashCode.Mix(hash, w.GetHashCode());
		return hash;
	}

	// Static functions
	/// @brief Creates an identity matrix with ones on the diagonal.
	[Inline]
	public static Matrix4x4<T> Identity()
	{
		return .(
			.((T)1, (T)0, (T)0, (T)0),
			.((T)0, (T)1, (T)0, (T)0),
			.((T)0, (T)0, (T)1, (T)0),
			.((T)0, (T)0, (T)0, (T)1)
			);
	}

	/// @brief Creates a uniform or non-uniform scale matrix.
	/// @param s Scale factors for each axis.
	[Inline]
	public static Matrix4x4<T> Scale(in Vector3<T> s)
	{
		return .(
			.(s.x, (T)0, (T)0, (T)0),
			.((T)0, s.y, (T)0, (T)0),
			.((T)0, (T)0, s.z, (T)0),
			.((T)0, (T)0, (T)0, (T)1)
			);
	}

	/// @brief Creates a translation matrix from a position vector.
	/// @param pos Translation in world units.
	[Inline]
	public static Matrix4x4<T> Translation(in Vector3<T> pos)
	{
		return .(
			.((T)1, (T)0, (T)0, (T)0),
			.((T)0, (T)1, (T)0, (T)0),
			.((T)0, (T)0, (T)1, (T)0),
			.(pos.x, pos.y, pos.z, (T)1)
			);
	}

	/// @brief Builds a rotation matrix about the X axis.
	/// @param radians Angle in radians.
	[Inline]
	public static Matrix4x4<T> RotationX(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			.((T)1, (T)0, (T)0, (T)0),
			.((T)0, (T)c, (T)s, (T)0),
			.((T)0, (T) - s, (T)c, (T)0),
			.((T)0, (T)0, (T)0, (T)1)
			);
	}

	/// @brief Builds a rotation matrix about the Y axis.
	/// @param radians Angle in radians.
	[Inline]
	public static Matrix4x4<T> RotationY(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			.((T)c, (T)0, (T) - s, (T)0),
			.((T)0, (T)1, (T)0, (T)0),
			.((T)s, (T)0, (T)c, (T)0),
			.((T)0, (T)0, (T)0, (T)1)
			);
	}

	/// @brief Builds a rotation matrix about the Z axis.
	/// @param radians Angle in radians.
	[Inline]
	public static Matrix4x4<T> RotationZ(T radians)
	{
		double c = Math.Cos((double)radians);
		double s = Math.Sin((double)radians);
		return .(
			.((T)c, (T)s, (T)0, (T)0),
			.((T) - s, (T)c, (T)0, (T)0),
			.((T)0, (T)0, (T)1, (T)0),
			.((T)0, (T)0, (T)0, (T)1)
			);
	}

	/// @brief Creates a rotation around an arbitrary axis.
	/// @param axis Axis to rotate around.
	/// @param angle Angle in radians.
	[Inline]
	public static Matrix4x4<T> RotateAxis(in Vector3<T> axis, T angle)
	{
		var axisNorm = axis.Normalized();
		T c = (T)Math.Cos(angle);
		T s = (T)Math.Sin(angle);
		T oneMinusC = (T)1 - c;

		T x = axisNorm.x, y = axisNorm.y, z = axisNorm.z;

		return .(
			.(x * x * oneMinusC + c,     y * x * oneMinusC + z * s, z * x * oneMinusC - y * s, (T)0),
			.(x * y * oneMinusC - z * s,   y * y * oneMinusC + c,   z * y * oneMinusC + x * s, (T)0),
			.(x * z * oneMinusC + y * s,   y * z * oneMinusC - x * s, z * z * oneMinusC + c,   (T)0),
			.((T)0,                  (T)0,                (T)0,                (T)1)
			);
	}

	/// @brief Builds a right-handed look-at matrix from camera parameters.
	/// @param eye Camera position.
	/// @param center Target position.
	/// @param up World up direction.
	[Inline]
	public static Matrix4x4<T> LookAt(in Vector3<T> eye, in Vector3<T> center, in Vector3<T> up)
	{
		Vector3<T> fwd = (center - eye).Normalized();
		Vector3<T> right = fwd.CrossProduct(up).Normalized();
		Vector3<T> realUp = right.CrossProduct(fwd);

		// Camera transform columns (camera local axes and origin)
		let xTran = -right.DotProduct(eye);
		let yTran = -realUp.DotProduct(eye);
		let zTran = fwd.DotProduct(eye);

		return .(
			.(right.x, realUp.x, -fwd.x, (T)0),
			.(right.y, realUp.y, -fwd.y, (T)0),
			.(right.z, realUp.z, -fwd.z, (T)0),
			.(xTran, yTran, zTran, (T)1)
			);
	}

	/// @brief Replaces this matrix with a translation/rotation/scale transform.
	/// @param position Translation component.
	/// @param rotation Rotation component applied prior to scaling.
	/// @param scale Scale applied along the rotated basis axes.
	[Inline]
	public void SetTRS(in Vector3<T> position, in Quaternion<T> rotation, in Vector3<T> scale) mut
	{
		var rot = rotation.ToMatrix3x3();
		var scaledRight = rot.right * scale.x;
		var scaledUp = rot.up * scale.y;
		var scaledForward = rot.forward * scale.z;

		this.x = Vector4<T>(scaledRight, (T)0);
		this.y = Vector4<T>(scaledUp, (T)0);
		this.z = Vector4<T>(scaledForward, (T)0);
		this.w = Vector4<T>(position, (T)1);
	}

	/// @brief Constructs a new TRS matrix from the supplied components.
	/// @param position Translation component.
	/// @param rotation Rotation component.
	/// @param scale Scale component.
	/// @returns Matrix representing the composed TRS transform.
	[Inline]
	public static Matrix4x4<T> TRS(in Vector3<T> position, in Quaternion<T> rotation, in Vector3<T> scale)
	{
		var result = Identity();
		result.SetTRS(position, rotation, scale);
		return result;
	}

	/// @brief Tests whether this matrix encodes a valid, non-degenerate TRS transform.
	/// @returns True when translation, rotation, and scale can be decomposed safely.
	public bool ValidTRS()
	{
		if (!IsFiniteVector(ExtractPosition()))
			return false;

		Matrix3x3<T> rotation;
		Vector3<T> scale;
		DecomposeRotationScale(out rotation, out scale);

		if (!IsFiniteVector(scale) || !HasValidScale(scale))
			return false;

		if (!IsOrthonormal(rotation))
			return false;

		double tolerance = kTrsEpsilon * 10.0;
		if (!NearlyEqual((double)x.w, 0.0, tolerance) || !NearlyEqual((double)y.w, 0.0, tolerance) || !NearlyEqual((double)z.w, 0.0, tolerance))
			return false;
		if (!NearlyEqual((double)w.w, 1.0, tolerance))
			return false;

		return true;
	}

	/// @brief Extracts the translation component from this transform.
	/// @returns Translation column as a 3D vector.
	[Inline]
	public Vector3<T> ExtractPosition()
	{
		return Vector3<T>(t.x, t.y, t.z);
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

	/// @brief Creates an asymmetric perspective projection matrix.
	/// @param left Coordinate of the left clipping plane.
	/// @param right Coordinate of the right clipping plane.
	/// @param bottom Coordinate of the bottom clipping plane.
	/// @param top Coordinate of the top clipping plane.
	/// @param nearPlane Distance to the near clipping plane (positive).
	/// @param farPlane Distance to the far clipping plane (positive).
	[Inline]
	public static Matrix4x4<T> Frustum(T left, T right, T bottom, T top, T nearPlane, T farPlane)
	{
		double l = (double)left;
		double r = (double)right;
		double b = (double)bottom;
		double t = (double)top;
		double n = (double)nearPlane;
		double f = (double)farPlane;

		double invWidth = 1.0 / (r - l);
		double invHeight = 1.0 / (t - b);
		double invDepth = 1.0 / (n - f);

		double scaleX = 2.0 * n * invWidth;
		double scaleY = 2.0 * n * invHeight;
		double offsetX = (r + l) * invWidth;
		double offsetY = (t + b) * invHeight;
		double depthA = (f + n) * invDepth;
		double depthB = (2.0 * f * n) * invDepth;

		return .(
			.((T)scaleX, (T)0, (T)0, (T)0),
			.((T)0, (T)scaleY, (T)0, (T)0),
			.((T)offsetX, (T)offsetY, (T)depthA, (T) - 1),
			.((T)0, (T)0, (T)depthB, (T)0)
			);
	}

	/// @brief Creates an orthographic projection matrix.
	/// @param left Coordinate of the left clipping plane.
	/// @param right Coordinate of the right clipping plane.
	/// @param bottom Coordinate of the bottom clipping plane.
	/// @param top Coordinate of the top clipping plane.
	/// @param nearPlane Distance to the near clipping plane.
	/// @param farPlane Distance to the far clipping plane.
	[Inline]
	public static Matrix4x4<T> Ortho(T left, T right, T bottom, T top, T nearPlane, T farPlane)
	{
		double l = (double)left;
		double r = (double)right;
		double b = (double)bottom;
		double t = (double)top;
		double n = (double)nearPlane;
		double f = (double)farPlane;

		double invWidth = 1.0 / (r - l);
		double invHeight = 1.0 / (t - b);
		double invDepth = 1.0 / (f - n);

		double scaleX = 2.0 * invWidth;
		double scaleY = 2.0 * invHeight;
		double scaleZ = -2.0 * invDepth;
		double offsetX = -(r + l) * invWidth;
		double offsetY = -(t + b) * invHeight;
		double offsetZ = -(f + n) * invDepth;

		return .(
			.((T)scaleX, (T)0, (T)0, (T)0),
			.((T)0, (T)scaleY, (T)0, (T)0),
			.((T)0, (T)0, (T)scaleZ, (T)0),
			.((T)offsetX, (T)offsetY, (T)offsetZ, (T)1)
			);
	}

	/// @brief Creates a perspective projection matrix.
	/// @param fovRadians Vertical field of view in radians.
	/// @param aspectRatio Viewport aspect ratio.
	/// @param nearPlane Near clipping plane.
	/// @param farPlane Far clipping plane.
	[Inline]
	public static Matrix4x4<T> PerspectiveFov(T fovRadians, T aspectRatio, T nearPlane, T farPlane)
	{
		// Core projection parameters
		T halfTan = (T)Math.Tan(fovRadians * 0.5);
		T focalY = (T)1.0 / halfTan; // Vertical focal length
		T focalX = focalY / aspectRatio; // Horizontal focal length

		T invDepth = (T)1.0 / (nearPlane - farPlane);
		T depthA = (farPlane + nearPlane) * invDepth;
		T depthB = (T)(2.0 * farPlane * nearPlane) * invDepth;

		// Build final projection matrix (column-major)
		return .(
			.((T)focalX, (T)0,       (T)0,      (T)0),
			.((T)0,      (T)focalY,  (T)0,      (T)0),
			.((T)0,      (T)0,       (T)depthA, (T) - 1),
			.((T)0,      (T)0,       (T)depthB, (T)0)
			);
	}

	/// @brief Computes the determinant of a 4x4 matrix.
	/// @param m Matrix to evaluate.
	[Inline]
	public static T Determinant(in Matrix4x4<T> m)
	{
		return
			m.r.x * (m.u.y * (m.f.z * m.t.w - m.f.w * m.t.z) -
			m.u.z * (m.f.y * m.t.w - m.f.w * m.t.y) +
			m.u.w * (m.f.y * m.t.z - m.f.z * m.t.y))
			- m.r.y * (m.u.x * (m.f.z * m.t.w - m.f.w * m.t.z) -
			m.u.z * (m.f.x * m.t.w - m.f.w * m.t.x) +
			m.u.w * (m.f.x * m.t.z - m.f.z * m.t.x))
			+ m.r.z * (m.u.x * (m.f.y * m.t.w - m.f.w * m.t.y) -
			m.u.y * (m.f.x * m.t.w - m.f.w * m.t.x) +
			m.u.w * (m.f.x * m.t.y - m.f.y * m.t.x))
			- m.r.w * (m.u.x * (m.f.y * m.t.z - m.f.z * m.t.y) -
			m.u.y * (m.f.x * m.t.z - m.f.z * m.t.x) +
			m.u.z * (m.f.x * m.t.y - m.f.y * m.t.x));
	}

	/// @brief Linearly interpolates between this matrix and a target matrix.
	/// @param target Matrix to interpolate toward.
	/// @param t Interpolation factor, typically between 0 and 1.
	[Inline]
	public Matrix4x4<T> Lerp(in Matrix4x4<T> target, T t)
	{
		return this + (target - this) * t;
	}

	/// @brief Returns the component-wise maximum of this matrix and another.
	[Inline]
	public Matrix4x4<T> Max(in Matrix4x4<T> other)
	{
		return .(
			x.Max(other.x),
			y.Max(other.y),
			z.Max(other.z),
			w.Max(other.w)
			);
	}

	/// @brief Returns the component-wise minimum of this matrix and another.
	[Inline]
	public Matrix4x4<T> Min(in Matrix4x4<T> other)
	{
		return .(
			x.Min(other.x),
			y.Min(other.y),
			z.Min(other.z),
			w.Min(other.w)
			);
	}

	/// @brief Returns the component-wise absolute value of the matrix.
	[Inline]
	public Matrix4x4<T> Abs()
	{
		return .(
			x.Abs(),
			y.Abs(),
			z.Abs(),
			w.Abs()
			);
	}

	/// @brief Clamps each component between the values in the corresponding matrices.
	/// @param min Lower bound per component.
	/// @param max Upper bound per component.
	[Inline]
	public Matrix4x4<T> Clamp(in Matrix4x4<T> min, in Matrix4x4<T> max)
	{
		return .(
			x.Clamp(min.x, max.x),
			y.Clamp(min.y, max.y),
			z.Clamp(min.z, max.z),
			w.Clamp(min.w, max.w)
			);
	}

	/// @brief Clamps components to the [0, 1] range.
	[Inline]
	public Matrix4x4<T> Saturate()
	{
		return Clamp(Matrix4x4<T>.Zero, Matrix4x4<T>.One);
	}

	/// @brief Transforms a point using homogeneous coordinates.
	/// @param point Point to transform.
	[Inline]
	public Vector3<T> TransformPoint(in Vector3<T> point)
	{
		var point4 = Vector4<T>(point.x, point.y, point.z, (T)1);
		var result4 = this * point4;
		T w = result4.w;
		if (w != (T)0 && w != (T)1)
		{
			double invW = 1.0 / (double)w;
			T scale = (T)invW;
			return Vector3<T>(result4.x * scale, result4.y * scale, result4.z * scale);
		}
		return Vector3<T>(result4.x, result4.y, result4.z);
	}

	/// @brief Transforms a direction vector, ignoring translation.
	/// @param vector Vector to transform.
	[Inline]
	public Vector3<T> TransformVector(in Vector3<T> vector)
	{
		var vec4 = Vector4<T>(vector.x, vector.y, vector.z, (T)0);
		var result4 = this * vec4;
		return Vector3<T>(result4.x, result4.y, result4.z);
	}

	/// @brief Returns a matrix with all elements set to zero.
	[Inline]
	public static Matrix4x4<T> Zero => .(Vector4<T>.Zero, Vector4<T>.Zero, Vector4<T>.Zero, Vector4<T>.Zero);

	/// @brief Returns a matrix with all elements set to one.
	[Inline]
	public static Matrix4x4<T> One => .(Vector4<T>.One, Vector4<T>.One, Vector4<T>.One, Vector4<T>.One);

	/// @brief Casts this matrix to an equivalent matrix with a different component type.
	/// @returns Matrix with each column converted to the requested type.
	public Matrix4x4<U> Cast<U>()
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
		return .(x.Cast<U>(), y.Cast<U>(), z.Cast<U>(), w.Cast<U>());
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