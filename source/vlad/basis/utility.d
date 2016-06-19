/**
 *	utility.d
 */

module vlad.basis.utility;

private
{
	import vlad.string;
	import std.path; // extension
	import std.format;
	import core.exception; // AssertError
}

// assert
void dlAssert(string file = __FILE__, size_t line = __LINE__, string func = __FUNCTION__, A...)(bool eq, A args)
{
	debug
	{
		if (!eq)
		{
			auto info = format("%s : ", std.path.extension(func)[1..$]);
			throw new AssertError(info, file, line);
		}
	}
}
void dlCheckedMsg(size_t line = __LINE__, string file = __FILE__, string func = __FUNCTION__, A...)(bool eq, A args)
{
	debug
	{
		if (!eq)
		{
			std.stdio.writef("%s : %s : %s ", file, line, std.path.extension(func)[1..$]);
			std.stdio.writefln(args);
		}
	}
}
