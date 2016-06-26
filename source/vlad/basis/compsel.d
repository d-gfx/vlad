/**
 *	compsel.d
 *
 *	utility for generate component select getter/setter
 *
 *	Reference:	https://github.com/ParticlePeter/DLSL/blob/master/source/dlsl/vector.d
 *				http://www.mmartins.me/view/2015/9/27/vector-swizzle-in-d
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
		func_body ~= "array["~to!string(idx[i])~"]=v.array["~to!string(i)~"];";
	}
	string func_arg = "(TVector!(T, "~to!string(idx.length)~") v) { ";
	return "@property void "~compsel~func_arg~func_body~"}\n";
}

/// generates all possible component select setter
string setterCompSel(int[] idx, string[] comp)
{
	string result;
	if (idx.length == 1) {
		result="@property void "~comp[idx[0]]~"(T val){"~"array["~to!string(idx[0])~"]=val;}\n";
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
