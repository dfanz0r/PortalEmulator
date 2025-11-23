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
    public static void Vector_BitwiseOperators_WorkForIntegers()
    {
        Vector2Int v2A = .(0b1010, 0b1100);
        Vector2Int v2B = .(0b0110, 0b0011);
        Vector3Int v3A = .(0b1111, 0b0001, 0b0101);
        Vector3Int v3B = .(0b0011, 0b0110, 0b1100);
        Vector4Int v4A = .(0b11110000, 0b00001111, 0b01010101, 0b10101010);
        Vector4Int v4B = .(0b00110011, 0b11001100, 0b11110000, 0b00001111);

        var v2And = v2A & v2B;
        Test.Assert(v2And.x == (v2A.x & v2B.x) && v2And.y == (v2A.y & v2B.y));
        var v2Or = v2A | v2B;
        Test.Assert(v2Or.x == (v2A.x | v2B.x) && v2Or.y == (v2A.y | v2B.y));
        var v2Xor = v2A ^ v2B;
        Test.Assert(v2Xor.x == (v2A.x ^ v2B.x) && v2Xor.y == (v2A.y ^ v2B.y));
        var v2Scalar = v2A & 0b1111;
        Test.Assert(v2Scalar.x == (v2A.x & 0b1111) && v2Scalar.y == (v2A.y & 0b1111));
        var v2Not = ~v2A;
        Test.Assert(v2Not.x == ~v2A.x && v2Not.y == ~v2A.y);
        var v2Accum = v2A;
        v2Accum &= v2B;
        Test.Assert(v2Accum.x == v2And.x && v2Accum.y == v2And.y);
        v2Accum |= Vector2Int(0b0100, 0b1000);
        Test.Assert(v2Accum.x == (v2And.x | 0b0100) && v2Accum.y == (v2And.y | 0b1000));
        v2Accum ^= Vector2Int(0b0010, 0b0001);
        Test.Assert(v2Accum.x == ((v2And.x | 0b0100) ^ 0b0010));
        Test.Assert(v2Accum.y == ((v2And.y | 0b1000) ^ 0b0001));

        var v3And = v3A & v3B;
        Test.Assert(v3And.x == (v3A.x & v3B.x) && v3And.y == (v3A.y & v3B.y) && v3And.z == (v3A.z & v3B.z));
        var v3Or = v3A | 0b1111;
        Test.Assert(v3Or.x == (v3A.x | 0b1111) && v3Or.y == (v3A.y | 0b1111) && v3Or.z == (v3A.z | 0b1111));
        var v3Not = ~v3B;
        Test.Assert(v3Not.x == ~v3B.x && v3Not.y == ~v3B.y && v3Not.z == ~v3B.z);
        var v3Accum = v3A;
        v3Accum ^= v3B;
        Test.Assert(v3Accum.x == (v3A.x ^ v3B.x) && v3Accum.y == (v3A.y ^ v3B.y) && v3Accum.z == (v3A.z ^ v3B.z));
        v3Accum &= 0b1010;
        Test.Assert(v3Accum.x == ((v3A.x ^ v3B.x) & 0b1010));
        Test.Assert(v3Accum.y == ((v3A.y ^ v3B.y) & 0b1010));
        Test.Assert(v3Accum.z == ((v3A.z ^ v3B.z) & 0b1010));

        var v4Or = v4A | v4B;
        Test.Assert(v4Or.x == (v4A.x | v4B.x) && v4Or.y == (v4A.y | v4B.y) && v4Or.z == (v4A.z | v4B.z) && v4Or.w == (v4A.w | v4B.w));
        var v4Xor = v4A ^ 0b11111111;
        Test.Assert(v4Xor.x == (v4A.x ^ 0b11111111) && v4Xor.y == (v4A.y ^ 0b11111111));
        Test.Assert(v4Xor.z == (v4A.z ^ 0b11111111) && v4Xor.w == (v4A.w ^ 0b11111111));
        var v4Not = ~v4B;
        Test.Assert(v4Not.x == ~v4B.x && v4Not.y == ~v4B.y && v4Not.z == ~v4B.z && v4Not.w == ~v4B.w);
        var v4Accum = v4B;
        v4Accum |= v4A;
        Test.Assert(v4Accum.Equals(v4Or));
        v4Accum ^= Vector4Int(0b01010101, 0, 0, 0);
        Test.Assert(v4Accum.x == (v4Or.x ^ 0b01010101));
        v4Accum &= Vector4Int(0b11111111, 0b11111111, 0b00000000, 0b11111111);
        Test.Assert(v4Accum.x == ((v4Or.x ^ 0b01010101) & 0b11111111));
        Test.Assert(v4Accum.z == 0);
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

    [Test]
    public static void Matrix4x4_LookAt()
    {
        let eye = Vector3<double>(0, 0, 10);
        let target = Vector3<double>(0, 0, 0);
        let up = Vector3<double>(0, 1, 0);

        let view = Matrix4x4<double>.LookAt(eye, target, up);
        
        // View matrix should transform eye to origin
        let transformedEye = view.TransformPoint(eye);
        AssertVectorApprox(Vector3<double>.Zero, transformedEye);

        // Target should be at (0, 0, -10) in view space (looking down -Z)
        let transformedTarget = view.TransformPoint(target);
        AssertVectorApprox(Vector3<double>(0, 0, -10), transformedTarget);
    }

    [Test]
    public static void Matrix4x4_PerspectiveFov()
    {
        let fov = Math.PI_d / 2.0; // 90 degrees
        let aspect = 1.0;
        let near = 1.0;
        let far = 100.0;

        let proj = Matrix4x4<double>.PerspectiveFov(fov, aspect, near, far);

        // Verify structure of perspective matrix
        // Col 0 (x)
        Test.Assert(proj.x.x != 0);
        Test.Assert(proj.x.y == 0);
        Test.Assert(proj.x.z == 0);
        Test.Assert(proj.x.w == 0);

        // Col 1 (y)
        Test.Assert(proj.y.x == 0);
        Test.Assert(proj.y.y != 0);
        Test.Assert(proj.y.z == 0);
        Test.Assert(proj.y.w == 0);

        // Col 2 (z)
        Test.Assert(proj.z.x == 0);
        Test.Assert(proj.z.y == 0);
        Test.Assert(proj.z.z != 0);
        Test.Assert(proj.z.w == -1); // Standard perspective has -1 here for Z division

        // Col 3 (w)
        Test.Assert(proj.w.x == 0);
        Test.Assert(proj.w.y == 0);
        Test.Assert(proj.w.z != 0);
        Test.Assert(proj.w.w == 0);
    }

    [Test]
    public static void Matrix4x4_Ortho()
    {
        let width = 10.0;
        let height = 10.0;
        let near = 0.0;
        let far = 100.0;

        // Centered ortho
        let ortho = Matrix4x4<double>.Ortho(-width/2, width/2, -height/2, height/2, near, far);

        // Center point should stay center
        let center = Vector3<double>(0, 0, -50);
        let projCenter = ortho.TransformPoint(center);
        Test.Assert(projCenter.x == 0);
        Test.Assert(projCenter.y == 0);
        
        // Top-right near corner (5, 5, 0) -> (1, 1, 0) (assuming OpenGL style clip space -1..1)
        // Or 0..1 depending on implementation.
        // Beef implementation:
        // scaleX = 2.0 * invWidth;
        // scaleY = 2.0 * invHeight;
        // scaleZ = -2.0 * invDepth;
        // This looks like OpenGL standard (-1 to 1).
        
        // let corner = Vector3<double>(5, 5, -near); // Z is -near because camera looks down -Z? 
        // Wait, Ortho implementation:
        // scaleZ = -2.0 * invDepth;
        // offsetZ = -(f + n) * invDepth;
        // z' = z * scaleZ + offsetZ
        // If z = -near (0) -> 0 * scale + offset = offset = -(100+0)/100 = -1.
        // If z = -far (-100) -> -100 * (-2/100) + (-1) = 2 - 1 = 1.
        // So it maps -near to -1 and -far to 1.
        
        let cornerPoint = Vector3<double>(5, 5, 0);
        let projCorner = ortho.TransformPoint(cornerPoint);
        Test.Assert(NearlyEquals(projCorner.x, 1.0, 1e-5));
        Test.Assert(NearlyEquals(projCorner.y, 1.0, 1e-5));
    }

    [Test]
    public static void Matrix4x4_TransformPoint_Vs_TransformVector()
    {
        let translate = Matrix4x4<double>.Translation(Vector3<double>(10, 20, 30));
        
        let v = Vector3<double>(1, 1, 1);
        
        // TransformPoint applies translation
        let p = translate.TransformPoint(v);
        AssertVectorApprox(Vector3<double>(11, 21, 31), p);
        
        // TransformVector ignores translation (w=0)
        let d = translate.TransformVector(v);
        AssertVectorApprox(Vector3<double>(1, 1, 1), d);
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
