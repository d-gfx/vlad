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
	import std.stdio;
}

/// assert
void vlAssert(string file = __FILE__, size_t line = __LINE__, string func = __FUNCTION__, A...)(bool eq, A args)
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

/// print with info
void vlPrintlnInfo(size_t line = __LINE__, string file = __FILE__, string func = __FUNCTION__, A...)(A args)
{
	std.stdio.writef("%s : %s : %s ", file, line, std.path.extension(func)[1..$]);
	std.stdio.writefln(args);
}

/// checked print
void vlCheckedMsg(size_t line = __LINE__, string file = __FILE__, string func = __FUNCTION__, A...)(bool eq, A args)
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

/// unit test log
struct UnitTestLogger
{
	this (string file = __FILE__, int line = __LINE__)(int dummy)
	{
		mFile = file;
		writefln("Unit Test Begin[%s:%s]", mFile, line);
	}
	~this ()
	{
		writefln("Unit Test End[%s]", mFile);
	}
	string mFile;
}