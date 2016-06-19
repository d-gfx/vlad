/**
 *	mixinutility.d
 */
module vlad.basis.mixinutility;

alias MixinUtil = vlad.basis.mixinutility;

template CompileMsg(string MSG)
{
	const string CompileMsg = 
		"pragma(msg, \"CompileMsg = \" ~ __FILE__ ~ \"(\" ~ __LINE__.stringof ~ \"):" ~ MSG ~ "\");";
}
