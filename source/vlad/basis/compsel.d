/**
 *	compsel.d
 *
 *	utility for generate component select getter/setter
 *
 *	Reference:
 *	https://github.com/ParticlePeter/DLSL/blob/master/source/dlsl/vector.d
 *	http://www.mmartins.me/view/2015/10/2/vector-swizzling-in-d-now-with-swizzle-assignment
 */
module vlad.basis.compsel;

private
{
	import std.conv;
}

// define component select getter/setter
string genSetterCompSel(int[] idx, string[] comp)
{
	string compsel;
	string func_body;
	foreach (i; 0..idx.length) {
		compsel ~= comp[idx[i]];
		func_body ~= "this.array["~to!string(idx[i])~"]=v.array["~to!string(i)~"];";
	}
	string func_arg = "(TVector!(T, "~to!string(idx.length)~") v) { ";
	return "@property void "~compsel~func_arg~func_body~"}\n";
}

/// generates all possible component select setter
string setterCompSel(int[] idx, string[] comp)
{
	string result;
	if (idx.length == 1) {
		result="@property void "~comp[idx[0]]~"(T val){ this.array["~to!string(idx[0])~"]=val;}\n";
	}
	else if (idx.length == 2) {
		foreach(i;0..2){
			result ~= "\n"~setterCompSel([idx[i]], comp);
			result ~= genSetterCompSel([idx[i],idx[(i+1)%2]], comp);
		}
	}
	else if (idx.length == 3) {
		foreach(i;0..3){
			result ~= "\n"~setterCompSel([idx[i]], comp);
			foreach(j;0..2) result ~= genSetterCompSel([idx[i],idx[(i+j+1)%3]], comp);
			foreach(j;0..2) result ~= genSetterCompSel([idx[i],idx[(i+j+1)%3],idx[(i+(j+1)%2+1)%3]], comp);
		}
	}
	else if (idx.length == 4) {
		foreach(i;0..4){
			result ~= "\n"~setterCompSel([idx[i]], comp);
			foreach(j;0..3){
				result ~= genSetterCompSel([idx[i],idx[(i+j+1)%4]], comp);
				foreach(k;0..2) result ~= genSetterCompSel([idx[i],idx[(i+j+1)%4],idx[(i+(j+k+1)%3+1)%4]], comp);
				foreach(k;0..2) result ~= genSetterCompSel([idx[i],idx[(i+j+1)%4],idx[(i+(j+k+1)%3+1)%4],idx[(i+(j+(k+1)%2+1)%3+1)%4]], comp);
			}
		}
	}
	return result;
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
		string str_ret_elem = r~"this.array["~to!string(i)~"]";
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

template isAllElemInList(string comp_sel, string comp_list)
{
	import std.algorithm;
	import std.string : indexOf;
	import std.array : array;
	enum match = comp_sel.map!(x=>comp_list.indexOf(x)).array;
	enum bool isAllElemInList = !match.canFind(-1); // return true when not found "-1"
}

template getterCompSelWithList(string comp_sel, string comp_list)
{
	import std.string : indexOf, join;
	import std.conv : to;
	import std.array : array;
	import std.algorithm : map;

	static if (comp_sel.length == 1)
	{
		enum int index = comp_list.indexOf(comp_sel[0]);
		enum getterCompSelWithList = "return this.array["~index.to!string~"];";
	}
	else
	{
		enum int[] indices = comp_sel.map!(x => comp_list.indexOf(x)).array;
		enum getterCompSelWithList = "return TVector!(T, "~to!string(comp_sel.length)~")("~indices.map!(x=>"this.array["~x.to!string~"]").join(", ")~");";
	}
}

template getCompList(string comp_sel)
{
	static if (isAllElemInList!(comp_sel, "xyzw"))		{ enum getCompList = "xyzw"; }
	else static if (isAllElemInList!(comp_sel, "rgba"))	{ enum getCompList = "rgba"; }
	else static if (isAllElemInList!(comp_sel, "stpq"))	{ enum getCompList = "stpq"; }
	else static assert(0, comp_sel~" is invalid component selection.");
}

unittest
{
	pragma(msg, "compsel unittest");
	static assert(isAllElemInList!("zxy", "xyzw"));
	static assert(isAllElemInList!("x", "xyzw"));
	static assert(isAllElemInList!("yyy", "xyzw"));
	static assert(isAllElemInList!("wxwx", "xyzw"));
	static assert(!isAllElemInList!("wxr", "xyzw"));
}
