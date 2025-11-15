using System;
using System.Numerics;
namespace Sizzle.Math;

[CRepr, UnderlyingArray(typeof(T), 4, true)]
internal struct Num4<T>
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
	public T x;
	public T y;
	public T z;
	public T w;

	[Inline]
	public this()
	{
		this = default;
	}

	[Inline]
	public this(T x, T y, T z, T w)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	public extern T this[int idx] { [Intrinsic("index")] get; [Intrinsic("index")] set; }

	public extern Self wzyx { [Intrinsic("shuffle3210")] get; [Intrinsic("shuffle3210")] set; }

	[Intrinsic("min")]
	public static extern Self min(Self lhs, Self rhs);

	[Intrinsic("max")]
	public static extern Self max(Self lhs, Self rhs);

	[Intrinsic("add")]
	public static extern Self operator +(Self lhs, Self rhs);
	[Intrinsic("add"), Commutable]
	public static extern Self operator +(Self lhs, T rhs);
	[Intrinsic("add")]
	public static extern Self operator ++(Self lhs);

	[Intrinsic("sub")]
	public static extern Self operator -(Self lhs, Self rhs);
	[Intrinsic("sub"), Commutable]
	public static extern Self operator -(Self lhs, T rhs);
	[Intrinsic("sub")]
	public static extern Self operator --(Self lhs);

	[Intrinsic("mul")]
	public static extern Self operator *(Self lhs, Self rhs);
	[Intrinsic("mul"), Commutable]
	public static extern Self operator *(Self lhs, T rhs);

	[Intrinsic("div")]
	public static extern Self operator /(Self lhs, Self rhs);
	[Intrinsic("div")]
	public static extern Self operator /(Self lhs, T rhs);
	[Intrinsic("div")]
	public static extern Self operator /(T lhs, Self rhs);

	[Intrinsic("mod")]
	public static extern Self operator %(Self lhs, Self rhs);
	[Intrinsic("mod")]
	public static extern Self operator %(Self lhs, T rhs);
	[Intrinsic("mod")]
	public static extern Self operator %(T lhs, Self rhs);

	[Intrinsic("eq")]
	public static extern bool4 operator ==(Self lhs, Self rhs);
	[Intrinsic("eq"), Commutable]
	public static extern bool4 operator ==(Self lhs, T rhs);

	[Intrinsic("neq")]
	public static extern bool4 operator !=(Self lhs, Self rhs);
	[Intrinsic("neq"), Commutable]
	public static extern bool4 operator !=(Self lhs, T rhs);

	[Intrinsic("lt")]
	public static extern bool4 operator <(Self lhs, Self rhs);
	[Intrinsic("lt")]
	public static extern bool4 operator <(Self lhs, T rhs);

	[Intrinsic("lte")]
	public static extern bool4 operator <=(Self lhs, Self rhs);
	[Intrinsic("lte")]
	public static extern bool4 operator <=(Self lhs, T rhs);

	[Intrinsic("gt")]
	public static extern bool4 operator >(Self lhs, Self rhs);
	[Intrinsic("gt")]
	public static extern bool4 operator >(Self lhs, T rhs);

	[Intrinsic("gte")]
	public static extern bool4 operator >=(Self lhs, Self rhs);
	[Intrinsic("gte")]
	public static extern bool4 operator >=(Self lhs, T rhs);

	[Intrinsic("cast")]
	public static extern explicit operator v128(Self lhs);
	[Intrinsic("cast")]
	public static extern explicit operator Self(v128 lhs);
}