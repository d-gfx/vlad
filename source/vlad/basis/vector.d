﻿/**
 *	vector.d
 */
module vlad.basis.vector;

private
{
	import vlad.basis;
	import core.simd;
	import std.conv;
	import std.math;
	import std.traits;

	template VecInit(string initializers)
	{
		const string VecInit = "Self(" ~ initializers ~ ");";
	}
}

struct TVector(T, int N)
{
	alias Self = TVector!(T, N);

	// define member
	static if (is(Vector!(T[N])))
	{
		Vector!(T[N]) vec = 0;
		enum isSimd = true;
		alias vec this;
	}
	else
	{
		enum isSimd = false;
		mixin("T[N] array = [" ~ InitAll!("0", N) ~ "];");
	}

	// define min, max
	static if (std.traits.isIntegral!(T))
	{
		static immutable(T) TMax = T.max;
		static immutable(T) TMin = T.min;
	}
	else static if (std.traits.isFloatingPoint!(T))
	{
		static immutable(T) TMax = T.max;
		static immutable(T) TMin = -T.max;//T.min_normal;
	}
	else static assert(0, "Not Supported " ~ std.conv.to!string(T));

	// define const

	mixin("static immutable(Self) Min = " ~ VecInit!(InitAll!("TMin", N)));
	mixin("static immutable(Self) Max = " ~ VecInit!(InitAll!("TMax", N)));
	mixin("static immutable(Self) Zero  = " ~ VecInit!(InitAll!("0", N)));
	mixin("static immutable(Self) One   = " ~ VecInit!(InitAll!("1", N)));
	static if (std.traits.isFloatingPoint!(T))
	{
		// unit axis vector
		mixin("static immutable(Self) Ex    = " ~ VecInit!(InitValueZero!("1",  N, N)));
		mixin("static immutable(Self) NegEx = " ~ VecInit!(InitValueZero!("-1", N, N)));
		static if (2 <= N)
		{
			mixin("static immutable(Self) Ey    = " ~ VecInit!(InitValueZero!("1",  N, N-1)));
			mixin("static immutable(Self) NegEy = " ~ VecInit!(InitValueZero!("-1", N, N-1)));
		}
		static if (3 <= N)
		{
			mixin("static immutable(Self) Ez    = " ~ VecInit!(InitValueZero!("1",  N, N-2)));
			mixin("static immutable(Self) NegEz = " ~ VecInit!(InitValueZero!("-1", N, N-2)));
		}
		static if (4 <= N)
		{
			mixin("static immutable(Self) Ew    = " ~ VecInit!(InitValueZero!("1",  N, N-3)));
			mixin("static immutable(Self) NegEw = " ~ VecInit!(InitValueZero!("-1", N, N-3)));
		}

		bool isNaN() const
		{
			foreach (ref v; array) { if (std.math.isNaN(v)) return true; }
			return false;
		}
	}
	static if (N == 4 && std.traits.isFloatingPoint!(T)) // color
	{
		static immutable(Self) Red		= Self(1, 0, 0, 1);
		static immutable(Self) Green	= Self(0, 1, 0, 1);
		static immutable(Self) Blue		= Self(0, 0, 1, 1);
		static immutable(Self) White	= Self(1, 1, 1, 1);
		static immutable(Self) Black	= Self(0, 0, 0, 1);
		static immutable(Self) Yellow	= Self(1, 1, 0, 1);
		static immutable(Self) Cyan		= Self(0, 1, 1, 1);
		static immutable(Self) Magenta	= Self(1, 0, 1, 1);
		static immutable(Self) Gray	= Self(1.0/4.0, 1.0/4.0, 1.0/4.0, 1.0);
	}

	// define property
	@property T opDispatch(string X)() const
	{
		static if ((1<=N) && (X=="x"||X=="r"||X=="u"))		{ return array[0]; }
		else static if ((2<=N) && (X=="y"||X=="g"||X=="v"))	{ return array[1]; }
		else static if ((3<=N) && (X=="z"||X=="b"||X=="s"))	{ return array[2]; }
		else static if ((4<=N) && (X=="w"||X=="a"||X=="t"))	{ return array[3]; }
		else static assert(0, "Not Support Member Func : " ~ X);
	}
	@property ref T opDispatch(string X)()
	{
		static if ((1<=N) && (X=="x"||X=="r"||X=="u"))		{ return array[0]; }
		else static if ((2<=N) && (X=="y"||X=="g"||X=="v"))	{ return array[1]; }
		else static if ((3<=N) && (X=="z"||X=="b"||X=="s"))	{ return array[2]; }
		else static if ((4<=N) && (X=="w"||X=="a"||X=="t"))	{ return array[3]; }
		else static assert(0, "Not Support Member Func : " ~ X);
	}
	@property T opDispatch(string X)(T value)
	{
		static if ((1<=N) && (X=="x"||X=="r"||X=="u"))		{ array[0] = value; return array[0]; }
		else static if ((2<=N) && (X=="y"||X=="g"||X=="v"))	{ array[1] = value; return array[1]; }
		else static if ((3<=N) && (X=="z"||X=="b"||X=="s"))	{ array[2] = value; return array[2]; }
		else static if ((4<=N) && (X=="w"||X=="a"||X=="t"))	{ array[3] = value; return array[3]; }
		else static assert(0, "Not Support TVector(" ~ T.stringof ~ ", " ~ N.stringof ~ ") property " ~ X);
	}

	// constructor
	this(T[N] ar ...)	{ array[] = ar[];	}
	this(T all_value)	{ array[] = all_value;	}
	this (in Self v)	{ static if (isSimd) vec = v.vec; else this(v.array); }
	static if (3 <= N)
	{
		this(in TVector!(T, N-1) dec_dim_vec, in T v) { set(dec_dim_vec, v); }
		void set(in TVector!(T, N-1) dec_dim_vec, in T v)
		{
			array[0..$-1] = dec_dim_vec.array[];
			array[$-1] = v;
		}
	}
	Self opAssign(in Self v)		{ static if (isSimd)  vec = v.vec; else opAssign(v.array); return this; }
	Self opAssign(in T v)			{ static if (isSimd)  vec = v; else array[] = v; return this; }
	Self opAssign(in T[N] arry)		{ array[] = arry[]; return this; }

	Self opOpAssign(string op)(in Self v)
	{
		static if (op == "+")		{ static if (isSimd)  vec += v.vec; else array[] += v.array[]; return this; }
		else static if (op == "-")	{ static if (isSimd)  vec -= v.vec; else array[] -= v.array[]; return this; }
		else static if (op == "*")	{ static if (isSimd)  vec *= v.vec; else array[] *= v.array[]; return this; }
		else static if (op == "/")	{ static if (isSimd)  vec /= v.vec; else array[] /= v.array[]; return this; }
	}
	Self opOpAssign(string op)(in T v)
	{
		static if (op == "+")		{ static if (isSimd)  vec += v; else array[] += v; return this; }
		else static if (op == "-")	{ static if (isSimd)  vec -= v; else array[] -= v; return this; }
		else static if (op == "*")	{ static if (isSimd)  vec *= v; else array[] *= v; return this; }
		else static if (op == "/")	{ static if (isSimd)  vec /= v; else array[] /= v; return this; }
	}
	Self opOpAssign(string op)(in T[N] arry)
	{
		static if (op == "+")		{ array[] += arry[]; return this; }
		else static if (op == "-")	{ array[] -= arry[]; return this; }
		else static if (op == "*")	{ array[] *= arry[]; return this; }
		else static if (op == "/")	{ array[] /= arry[]; return this; }
	}

	Self opAdd(in Self v) const { Self r = this; r.opOpAssign!"+"(v); return r; }
	Self opAdd(in T[N] arry) const { Self r = this; r.opOpAssign!"+"(arry); return r; }

	T opIndex(size_t i)		const	{ return array[i]; }
	ref T opIndex(size_t i)			{ return array[i]; }
	string toString() { return std.conv.to!string(array[]); }


	void setAll(T value)		{ opAssign(value);	}
	void set(T[N] ar ...)		{ opAssign(ar[]);	}
	void setMinus(in Self v)	{ static if (isSimd)  vec = -v.vec; else array[] = -v.array[];	}
	void setMinus(T[N] ar ...)	{ array[] = -ar[];	}
	void add(T[N] ar ...)		{ opOpAssign!"+"(ar[]); }
	void sub(T[N] ar ...)		{ opOpAssign!"-"(ar[]);	}
	void add(in T[N] ar)		{ opOpAssign!"+"(ar[]); }
	void sub(in T[N] ar)		{ opOpAssign!"-"(ar[]); }

	void set(in Self v)			{ opAssign(v);		}
	void add(in Self v)			{ opOpAssign!"+"(v);}
	void sub(in Self v)			{ opOpAssign!"-"(v);}
	void mul(T value)			{ opOpAssign!"*"(value); }
	void div(T value)			{ opOpAssign!"/"(value); }
	void zero()					{ opAssign(0);	}

	void scaleSet(in Self v, T scale) { set(v); mul(scale); }
	void scaleAdd(in Self v, T scale) { add(v); mul(scale); }
	void scaleSub(in Self v, T scale) { sub(v); mul(scale); }

	void setAdd(in Self a, in Self b) { set(a); add(b); }
	void setSub(in Self a, in Self b) { set(a); sub(b); }
	void diff(in Self v1, in Self v2) { setSub(v1, v2); }
	void addDiff(in Self v1, in Self v2) { add(v1); sub(v2); }
	static if (isSigned!T)
	{
		void reverse() { mul(-1); }
	}

}

unittest
//void unittestVector()
{
	version(unittest) { auto var = UnitTestLogger(0); }
	alias vec3f = TVector!(float, 3);

	auto a = vec3f(0, 0, 0);
	auto b = vec3f(1, 2, 3);
	auto c = a + b;

	assert(c.x == 1.0);
	assert(c.y == 2.0);
	assert(c.z == 3.0);
}
