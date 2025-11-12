using System;
using Sizzle.Math;

namespace Sizzle.Tests;

static class MathTests
{
    private const double DefaultEpsilon = 1e-8;

    [Test]
    public static void Matrix4x4_TRS_RoundTrip()
    {
        let position = Vector3<double>(1.5, -2.0, 3.25);
        let euler = Vector3<double>(0.3, -1.1, 2.4);
        let rotation = Quaternion<double>.FromEulerRadians(euler).Normalized();
        let scale = Vector3<double>(2.0, 3.5, 0.75);

        var matrix = Matrix4x4<double>.TRS(position, rotation, scale);

        Test.Assert(matrix.ValidTRS());
        AssertVectorApprox(position, matrix.ExtractPosition());
        AssertVectorApprox(scale, matrix.ExtractScale());

        var extractedRotation = matrix.ExtractRotation();
        Test.Assert(QuaternionApproxEquals(rotation, extractedRotation));
    }

    [Test]
    public static void Matrix3x4_TRS_RoundTrip()
    {
        let position = Vector3<double>(-4.0, 5.5, -6.25);
        let euler = Vector3<double>(-0.45, 0.75, -1.3);
        let rotation = Quaternion<double>.FromEulerRadians(euler).Normalized();
        let scale = Vector3<double>(1.5, 2.25, 3.0);

        var matrix = Matrix3x4<double>.TRS(position, rotation, scale);

        Test.Assert(matrix.ValidTRS());
        AssertVectorApprox(position, matrix.ExtractPosition());
        AssertVectorApprox(scale, matrix.ExtractScale());

        var extractedRotation = matrix.ExtractRotation();
        Test.Assert(QuaternionApproxEquals(rotation, extractedRotation));
    }

    [Test]
    public static void Matrix3x3_TRS_RoundTrip()
    {
        let euler = Vector3<double>(0.9, -0.35, 0.42);
        let rotation = Quaternion<double>.FromEulerRadians(euler).Normalized();
        let scale = Vector3<double>(2.5, 0.5, 4.0);

        var matrix = Matrix3x3<double>.TRS(Vector3<double>.Zero, rotation, scale);

        Test.Assert(matrix.ValidTRS());
        AssertVectorApprox(scale, matrix.ExtractScale());

        var extractedRotation = matrix.ExtractRotation();
        Test.Assert(QuaternionApproxEquals(rotation, extractedRotation));
        AssertVectorApprox(Vector3<double>.Zero, matrix.ExtractPosition());
    }

    [Test]
    public static void Quaternion_Euler_RoundTrip()
    {
        let euler = Vector3<double>(0.4, -0.2, 1.2);
        let quaternion = Quaternion<double>.FromEulerRadians(euler).Normalized();

        let recoveredEuler = quaternion.ToEulerRadians();
        let reconstructed = Quaternion<double>.FromEulerRadians(recoveredEuler).Normalized();

        Test.Assert(QuaternionApproxEquals(quaternion, reconstructed, 5e-6));
        AssertEulerApprox(euler, recoveredEuler, 1e-6);
    }

    [Test]
    public static void Quaternion_Euler_GimbalClamp()
    {
        let euler = Vector3<double>(0.6, Math.PI_d * 0.5, -1.0);
        let quaternion = Quaternion<double>.FromEulerRadians(euler).Normalized();

        let recoveredEuler = quaternion.ToEulerRadians();
        let reconstructed = Quaternion<double>.FromEulerRadians(recoveredEuler).Normalized();

        Test.Assert(QuaternionApproxEquals(quaternion, reconstructed, 5e-5));
        Test.Assert(NearlyAngleEquals(Math.PI_d * 0.5, recoveredEuler.y, 1e-5));
    }

    [Test]
    public static void Quaternion_Euler_GimbalClamp_NegativePitch()
    {
        let euler = Vector3<double>(-0.4, -Math.PI_d * 0.5, 0.8);
        let quaternion = Quaternion<double>.FromEulerRadians(euler).Normalized();

        let recoveredEuler = quaternion.ToEulerRadians();
        let reconstructed = Quaternion<double>.FromEulerRadians(recoveredEuler).Normalized();

        Test.Assert(QuaternionApproxEquals(quaternion, reconstructed, 5e-5));
        Test.Assert(NearlyAngleEquals(-Math.PI_d * 0.5, recoveredEuler.y, 1e-5));
    }

    [Test]
    public static void Quaternion_FromYawPitchRoll_MatchesEuler()
    {
        double yaw = -1.2;
        double pitch = 0.35;
        double roll = 0.9;

        let fromYawPitchRoll = Quaternion<double>.FromYawPitchRoll((double)yaw, (double)pitch, (double)roll).Normalized();
        let fromEuler = Quaternion<double>.FromEulerRadians(Vector3<double>(pitch, yaw, roll)).Normalized();

        Test.Assert(QuaternionApproxEquals(fromEuler, fromYawPitchRoll));
    }

    [Test]
    public static void Quaternion_ToEuler_ProducesNormalizedAngles()
    {
        let euler = Vector3<double>(Math.PI_d * 1.5, -0.9, Math.PI_d * -2.25);
        let quaternion = Quaternion<double>.FromEulerRadians(euler).Normalized();

        let recoveredEuler = quaternion.ToEulerRadians();

        double epsilon = 1e-9;
        Test.Assert(recoveredEuler.x >= -Math.PI_d - epsilon && recoveredEuler.x <= Math.PI_d + epsilon);
        Test.Assert(recoveredEuler.y >= -Math.PI_d * 0.5 - epsilon && recoveredEuler.y <= Math.PI_d * 0.5 + epsilon);
        Test.Assert(recoveredEuler.z >= -Math.PI_d - epsilon && recoveredEuler.z <= Math.PI_d + epsilon);

        let reconstructed = Quaternion<double>.FromEulerRadians(recoveredEuler).Normalized();
        Test.Assert(QuaternionApproxEquals(quaternion, reconstructed));
    }

    [Test]
    public static void Quaternion_FromAxisAngle()
    {
        let axis = Vector3<double>(1.0, 0.0, 0.0).Normalized();
        double angle = Math.PI_d * 0.5;
        let quaternion = Quaternion<double>.FromAxisAngle(axis, angle);

        let expectedEuler = Vector3<double>(angle, 0.0, 0.0);
        let recoveredEuler = quaternion.ToEulerRadians();

        AssertEulerApprox(expectedEuler, recoveredEuler, 1e-6);
    }

    [Test]
    public static void Quaternion_Matrix_RoundTrip()
    {
        let euler = Vector3<double>(0.1, -0.2, 0.3);
        let quaternion = Quaternion<double>.FromEulerRadians(euler).Normalized();

        let matrix = quaternion.ToMatrix3x3();
        let reconstructed = Quaternion<double>.FromMatrix(matrix).Normalized();

        Test.Assert(QuaternionApproxEquals(quaternion, reconstructed));
    }

    [Test]
    public static void Vector3_Normalization()
    {
        let vec = Vector3<double>(3.0, 4.0, 5.0);
        let normalized = vec.Normalized();

        Test.Assert(NearlyEquals(normalized.Magnitude(), 1.0, 1e-10));
        AssertVectorApprox(vec / vec.Magnitude(), normalized);
    }

    [Test]
    public static void Vector3_DotProduct()
    {
        let a = Vector3<double>(1.0, 2.0, 3.0);
        let b = Vector3<double>(4.0, 5.0, 6.0);
        double dot = a.DotProduct(b);

        Test.Assert(NearlyEquals(dot, 32.0, 1e-10));
    }

    [Test]
    public static void Matrix3x3_Inversion()
    {
        let matrix = Matrix3x3<double>.RotationX(0.5) * Matrix3x3<double>.RotationY(0.3);
        let inverted = matrix.Inverted();
        let identity = matrix * inverted;

        AssertMatrixApprox(Matrix3x3<double>.Identity, identity);
    }

    [Test]
    public static void Matrix3x3_Multiplication()
    {
        let a = Matrix3x3<double>.RotationX(0.2);
        let b = Matrix3x3<double>.RotationY(0.3);
        let combined = a * b;

        let vec = Vector3<double>(1.0, 0.0, 0.0);
        let result1 = combined * vec;
        let result2 = a * (b * vec);

        AssertVectorApprox(result1, result2);
    }

    [Test]
    public static void Quaternion_Identity()
    {
        let identity = Quaternion<double>.Identity;
        let vec = Vector3<double>(1.0, 2.0, 3.0);
        let rotated = identity.Rotate(vec);

        AssertVectorApprox(vec, rotated);
    }

    [Test]
    public static void Vector3_Zero()
    {
        let zero = Vector3<double>.Zero;
        Test.Assert(zero.x == 0.0 && zero.y == 0.0 && zero.z == 0.0);
    }

    [Test]
    public static void Vector3_CrossProduct()
    {
        let a = Vector3<double>(1.0, 0.0, 0.0);
        let b = Vector3<double>(0.0, 1.0, 0.0);
        let cross = a.CrossProduct(b);

        AssertVectorApprox(Vector3<double>(0.0, 0.0, 1.0), cross);
    }

    [Test]
    public static void Vector2_Normalization()
    {
        let vec = Vector2<double>(3.0, 4.0);
        let normalized = vec.Normalized();

        Test.Assert(NearlyEquals(normalized.Magnitude(), 1.0, 1e-10));
        AssertVector2Approx(vec / vec.Magnitude(), normalized);
    }

    [Test]
    public static void Vector2_DotProduct()
    {
        let a = Vector2<double>(1.0, 2.0);
        let b = Vector2<double>(3.0, 4.0);
        double dot = a.DotProduct(b);

        Test.Assert(NearlyEquals(dot, 11.0, 1e-10));
    }

    [Test]
    public static void Vector2_Zero()
    {
        let zero = Vector2<double>.Zero;
        Test.Assert(zero.x == 0.0 && zero.y == 0.0);
    }

    [Test]
    public static void Vector4_Normalization()
    {
        let vec = Vector4<double>(1.0, 2.0, 3.0, 4.0);
        let normalized = vec.Normalized();

        Test.Assert(NearlyEquals(normalized.Magnitude(), 1.0, 1e-10));
        AssertVector4Approx(vec / vec.Magnitude(), normalized);
    }

    [Test]
    public static void Vector4_DotProduct()
    {
        let a = Vector4<double>(1.0, 2.0, 3.0, 4.0);
        let b = Vector4<double>(5.0, 6.0, 7.0, 8.0);
        double dot = a.DotProduct(b);

        Test.Assert(NearlyEquals(dot, 70.0, 1e-10));
    }

    [Test]
    public static void Vector4_Zero()
    {
        let zero = Vector4<double>.Zero;
        Test.Assert(zero.x == 0.0 && zero.y == 0.0 && zero.z == 0.0 && zero.w == 0.0);
    }

    [Test]
    public static void Matrix4x4_Multiplication()
    {
        let a = Matrix4x4<double>.Scale(Vector3<double>(2.0, 3.0, 4.0));
        let b = Matrix4x4<double>.TRS(Vector3<double>(1.0, 0.0, 0.0), Quaternion<double>.Identity, Vector3<double>(1.0, 1.0, 1.0));
        let combined = a * b;

        let vec = Vector4<double>(1.0, 1.0, 1.0, 1.0);
        let result1 = combined * vec;
        let result2 = a * (b * vec);

        AssertVector4Approx(result1, result2);
    }

    [Test]
    public static void Matrix4x4_Identity()
    {
        let identity = Matrix4x4<double>.Identity();
        let vec = Vector4<double>(1.0, 2.0, 3.0, 4.0);
        let result = identity * vec;

        AssertVector4Approx(vec, result);
    }

    [Test]
    public static void Matrix3x4_Multiplication()
    {
        let a = Matrix3x4<double>.TRS(Vector3<double>(1.0, 0.0, 0.0), Quaternion<double>.Identity, Vector3<double>(2.0, 2.0, 2.0));
        let b = Matrix3x4<double>.TRS(Vector3<double>(0.0, 1.0, 0.0), Quaternion<double>.Identity, Vector3<double>(1.0, 1.0, 1.0));
        let combined = a * b;

        let vec = Vector3<double>(1.0, 1.0, 1.0);
        let result1 = combined * vec;
        let result2 = a * (b * vec);

        AssertVectorApprox(result1, result2);
    }

    [Test]
    public static void Matrix3x4_Identity()
    {
        let identity = Matrix3x4<double>.Identity();
        let vec = Vector3<double>(1.0, 2.0, 3.0);
        let result = identity * vec;

        AssertVectorApprox(vec, result);
    }

    private static void AssertVector2Approx(Vector2<double> expected, Vector2<double> actual, double epsilon = DefaultEpsilon)
    {
        Test.Assert(NearlyEquals(expected.x, actual.x, epsilon));
        Test.Assert(NearlyEquals(expected.y, actual.y, epsilon));
    }

    private static void AssertVector4Approx(Vector4<double> expected, Vector4<double> actual, double epsilon = DefaultEpsilon)
    {
        Test.Assert(NearlyEquals(expected.x, actual.x, epsilon));
        Test.Assert(NearlyEquals(expected.y, actual.y, epsilon));
        Test.Assert(NearlyEquals(expected.z, actual.z, epsilon));
        Test.Assert(NearlyEquals(expected.w, actual.w, epsilon));
    }

    [Test]
    public static void Matrix3x3_Identity()
    {
        let identity = Matrix3x3<double>.Identity;
        let vec = Vector3<double>(1.0, 2.0, 3.0);
        let result = identity * vec;

        AssertVectorApprox(vec, result);
    }

    private static void AssertMatrixApprox(Matrix3x3<double> expected, Matrix3x3<double> actual, double epsilon = DefaultEpsilon)
    {
        AssertVectorApprox(expected.x, actual.x, epsilon);
        AssertVectorApprox(expected.y, actual.y, epsilon);
        AssertVectorApprox(expected.z, actual.z, epsilon);
    }

    private static void AssertVectorApprox(Vector3<double> expected, Vector3<double> actual, double epsilon = DefaultEpsilon)
    {
        Test.Assert(NearlyEquals(expected.x, actual.x, epsilon));
        Test.Assert(NearlyEquals(expected.y, actual.y, epsilon));
        Test.Assert(NearlyEquals(expected.z, actual.z, epsilon));
    }

    private static bool QuaternionApproxEquals(Quaternion<double> expected, Quaternion<double> actual, double epsilon = DefaultEpsilon)
    {
        let normExpected = expected.Normalized();
        let normActual = actual.Normalized();
        var delta = normExpected * normActual.Conjugated();
        double angle = 2.0 * Math.Acos(Math.Min(Math.Abs((double)delta.w), 1.0));
        return Math.Abs(angle) <= Math.Max(epsilon * 10.0, 1e-3);
    }

    private static bool NearlyEquals(double lhs, double rhs, double epsilon)
    {
        return Math.Abs(lhs - rhs) <= epsilon;
    }

    private static void AssertEulerApprox(Vector3<double> expected, Vector3<double> actual, double epsilon)
    {
        Test.Assert(NearlyAngleEquals(expected.x, actual.x, epsilon));
        Test.Assert(NearlyAngleEquals(expected.y, actual.y, epsilon));
        Test.Assert(NearlyAngleEquals(expected.z, actual.z, epsilon));
    }

    private static bool NearlyAngleEquals(double expected, double actual, double epsilon)
    {
        double diff = WrapRadians(actual - expected);
        return Math.Abs(diff) <= epsilon;
    }

    private static double WrapRadians(double angle)
    {
        double twoPi = Math.PI_d * 2.0;
        double wrapped = angle;
        if (wrapped < -twoPi || wrapped > twoPi)
            wrapped = wrapped % twoPi;
        if (wrapped > Math.PI_d)
            wrapped -= twoPi;
        else if (wrapped < -Math.PI_d)
            wrapped += twoPi;
        return wrapped;
    }
}
