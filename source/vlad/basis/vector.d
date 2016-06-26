/**
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
	/// Generates all possible component select getter
	/// @fixme Can not put this function on vlad.basis.compsel.d [dmd v2.071.0]
	string getterCompSel(T)(string[] comp_list, string comp, string r, int term )
	{
		int N = comp_list.length;
		string str_dim = to!string(N - term + 1);
		string str_type = "@property auto ";
		string str_prefix = "() const { return ";
		string result;

		foreach (i; 0..N)  {
			string comp_sel = comp ~ comp_list[ i ];
			string str_ret_elem = r~"array["~to!string(i)~"]";
			string str_return = str_prefix ~ (term == N ? str_ret_elem ~ "; }"
											  : "TVector!(T, "~str_dim~")("~str_ret_elem~"); }");
			/// skip V2f.xy, V3f.xyz, V4f.xyzw which all return identity
			string skip; foreach (s; 0..N) skip ~= comp_list[s];
			if (N==2 && (comp_sel == skip))    result ~= str_type~comp_sel~"() const { return this; }\n";
			else  if(N==3 && (comp_sel==skip)) result ~= str_type~comp_sel~"() const { return this; }\n";
			else  if(N==4 && (comp_sel==skip)) result ~= str_type~comp_sel~"() const { return this; }\n";
			else { 
				result ~= str_type ~ comp_sel ~ str_return ~ "\n";
				if (term > 1)  result ~= getterCompSel!(T)(comp_list, comp_sel, str_ret_elem ~ ", ", term - 1 );
			}
		}
		return result;
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
	static if (N <= 4)
	{
		enum string[N] vec_comp = (["x", "y", "z", "w"])[0 .. N];
		enum string[N] col_comp = (["r", "g", "b", "a"])[0 .. N];
		enum string[N] tex_comp = (["s", "t", "p", "q"])[0 .. N];
		enum int[N] idcs = ([0, 1, 2, 3])[0..N];

	//	pragma(msg, setterCompSel(idcs, vec_comp));
	//	pragma(msg, setterCompSel(idcs, col_comp));
	//	pragma(msg, setterCompSel(idcs, uv_comp));
		mixin (setterCompSel(idcs, vec_comp));
		mixin (setterCompSel(idcs, col_comp));
		mixin (setterCompSel(idcs, tex_comp));
		mixin (getterCompSel!T(vec_comp, "", "", N));
		mixin (getterCompSel!T(col_comp, "", "", N));
		mixin (getterCompSel!T(tex_comp, "", "", N));
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

	Self opOpAssign(string op)(in Self v) if (op=="+" || op=="-" || op=="*" || op=="/")
	{
		static if (isSimd)  mixin("vec "~op~"= v.vec;"); else mixin("array[] "~op~"= v.array[];"); return this;
	}
	Self opOpAssign(string op)(in T v) if (op=="+" || op=="-" || op=="*" || op=="/")
	{
		static if (isSimd)  mixin("vec "~op~"= v;"); else mixin("array[] "~op~"= v;"); return this;
	}
	Self opOpAssign(string op)(in T[N] arry) if (op=="+" || op=="-" || op=="*" || op=="/")
	{
		mixin("array[] "~op~"= arry[];"); return this;
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

//unittest
void unittestVector()
{
	auto var = UnitTestLogger(0);
	alias vec3f = TVector!(float, 3);
	alias vec2f = TVector!(float, 2);

	auto a = vec3f(0, 0, 0);
	auto b = vec3f(1, 2, 3);
	auto c = a + b;

	assert(c.x == 1.0);
	assert(c.y == 2.0);
	assert(c.z == 3.0);
	c.rg = vec2f(-1, -2);
	assert(c.r == -1.0);
	assert(c.g == -2.0);
}
