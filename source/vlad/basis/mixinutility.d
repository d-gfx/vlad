/**
 *	mixinutility.d
 */
module vlad.basis.mixinutility;

alias MixinUtil = vlad.basis.mixinutility;

/**
 *	compile time message
 *	usage : mixin (CompileMsg!"FIXME");
 */
template CompileMsg(string MSG)
{
	const string CompileMsg = 
		"pragma(msg, \"CompileMsg = \" ~ __FILE__ ~ \"(\" ~ __LINE__.stringof ~ \"):" ~ MSG ~ "\");";
}

/**
 *	initialize by value
 */
template InitAll(string value, int N)
{
	static if (N == 1)	{ const string InitAll = value; }
	else				{ const string InitAll = value ~ ", " ~ InitAll!(value, N-1); }
}

/**
 *	initialize by value and other is zero
 */
template InitValueZero(string Value, int N, int ValuePos)
{
	static if (N == ValuePos)	{ const string InitValueZero = Value ~ ", " ~ InitValueZero!(Value, N-1, ValuePos); }
	else static if (N == 0)		{ const string InitValueZero = ""; }
	else						{ const string InitValueZero = "0, " ~ InitValueZero!(Value, N-1, ValuePos); }
}