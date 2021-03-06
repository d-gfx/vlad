/**
 *	fixedstring.d
 */
module vlad.string.fixedstring;

private
{
	import vlad.basis;
	import std.format;
	import std.traits : ReturnType
		, isImplicitlyConvertible
		, isSomeChar
		, Unqual
		, isSomeString;
	import std.typecons;
	import std.string;
	import std.algorithm.mutation: copy;
	import std.algorithm.comparison: max;
}

//version = NeedException;

/**
 *	struct of string interface
 */
struct IString(A : T[], T)
{
	alias Self = IString!(A);
	alias CHAR = Unqual!T;
public:
	A dstr() @property @nogc const { return mSliceString; }
	alias dstr this; // implicit cast

	const(CHAR)* cstr() const pure @nogc
	{
		version(NeedException){}else{
			if (mBufStringz is null)
				return cast(ReturnType!(Self.cstr))"\0";
		}
		return cast(ReturnType!(Self.cstr))&mBufStringz[0];
	}
	CHAR* cstr() @nogc { return &mBufStringz[0]; }

	size_t maxSize()	const pure @nogc { return max(0, mBufStringz.length - 1); } // exclude null-terminated
	size_t maxSizez()	const pure @nogc { return mBufStringz.length;	 } // include null-terminated
	size_t length()		const pure @nogc { return (mSliceString is null) ? 0 : mSliceString.length; }
	size_t lengthz()	const pure @nogc { return (mSliceString is null) ? 0 : mSliceString.length + 1; } // include null-terminated
	bool	isReady()	const pure @nogc { return (mBufStringz !is null); }

	/**
	 *	store
	 */
	void opAssign(in Self s)
	in {
		vlAssert(s.isReady(), "source buffer is not ready");
		vlAssert(isReady(), "mBufStringz is null");
		vlAssert(s.length <= maxSize(), "s.length[%s] <= maxSize[%s]", s.length, maxSize());
	}
	body {
		s.mBufStringz.copy(mBufStringz);	// better method
	//	mBufStringz[0..s.lengthz] = s.mBufStringz[0..s.lengthz];
	}

	/**
	 *	input range for formattedRead
	 */
	struct InputRange
	{
		this (in Self host) @nogc { mHost = host; }
		CHAR front() const @property @nogc { return mHost.mBufStringz[mInputIndex]; }
		CHAR popFront() @property @nogc { return mHost.mBufStringz[mInputIndex++]; }
		bool empty() const @property @nogc { return mInputIndex == mHost.mBufStringz.length; }
		size_t	mInputIndex = 0;
		const(Self) mHost;
	}

	/**
	 *	output range for formattedWrite
	 */
	struct OutputRange
	{
		Self* mHost;
		this (ref Self host) @nogc { mHost = &host; }
		void put(U)(U item) @nogc
		{
			auto len = mHost.length();
			if (len < mHost.maxSize())
			{
				mHost.mBufStringz[len] = item;
				mHost.mBufStringz[len+1] = '\0';
				mHost.mSliceString = cast(A)mHost.mBufStringz[0..len+1]; // not include null-terminated
//				if (!__ctfe) vlPrintlnInfo("len = %s, item = %s, mSliceString.length = %s", len, item, mHost.mSliceString.length);
			}
		}
		void put(const(char)[] s) @nogc
		{
//			std.format.sformat(mHost.mBufStringz[0..mHost.mBufStringz.length], "%s", s);
			foreach (e; s) { put(e); }
		}
	}

	void clear() @nogc
	{
		mSliceString = null;
		if (mBufStringz !is null)	mBufStringz[0] = '\0';
	}

	bool isEmpty() const @nogc { return mSliceString is null; }
	bool isEqualString(A str) const pure @nogc { return 0 == cmp(dstr, str); }

	/**
	 *	find null-terminate and make apropriate slice
	 *	when using C-like function ex. win32 api
	 */
	void ajustSlicez() @nogc
	{
		foreach (int i, ch; mBufStringz)
		{
			if (ch == '\0')
			{
				mSliceString = cast(A)mBufStringz[0..i]; // not include null-terminated
				return;
			}
		}
		// if not found null-terminated
		clear();
	}
private:
	CHAR[]		mBufStringz;	// for C style string include null-terminated 
	A			mSliceString;	// for D style string exclude null-terminated 
}

/**
 *	fixed length string
 */
struct FixedString(int N, A : T[], T)
{
	alias CHAR = Unqual!T;
public:
	const(IString!A) getString() @property const @nogc { return mString; }
	alias getString this; // for interface
	CHAR* cstr() @nogc { trySetupBuffer(); return mString.cstr; }	// non-const version
	void ajustSlicez() @nogc { return mString.ajustSlicez(); }
	void clear() @nogc { return mString.clear(); }

	private void trySetupBuffer() @nogc
	{
		if (mString.mBufStringz is null)
		{
			mString.mBufStringz = mFixArray;
			clear();
		}
	}

	this (A...)(A args)
	{
		trySetupBuffer();
		formattedWrite(mString.OutputRange(mString), args);
	}

	/**
	 *	store
	 */
	void opAssign(in IString!A s)
	{
		mString = s;
	}

	static import std.range.primitives;
	static assert(std.range.primitives.isOutputRange!(IString!A.OutputRange, CHAR));
	/**
	 *	formatted store with null-terminated
	 */
	void formatz(A...)(A args)
	{
		trySetupBuffer();
		clear();
		formattedWrite(mString.OutputRange(mString), args);
	}

	/**
	 *	formatted append with null-terminated
	 */
	void appendFormatz(A...)(A args)
	{
		trySetupBuffer();
		formattedWrite(mString.OutputRange(mString), args);
	}

	/**
	 *	read with format
	 */
	void formatRead(A...)(A args) const
	{
		try
		{
			auto input = mString.InputRange(mString);
			//	auto input = mString.dstr();
			formattedRead(input, args);
		}
		catch (Exception e)
		{
			vlPrintlnInfo("Failed formatRead.");
			vlPrintlnInfo("%s", e);
		}
	}

private:
	CHAR[N+1]	mFixArray;
	IString!A	mString;
}

alias StringBuf32	= FixedString!(32,  string);
alias StringBuf64	= FixedString!(64,  string);
alias StringBuf128	= FixedString!(128, string);
alias StringBuf256	= FixedString!(256, string);
alias StringBuf512	= FixedString!(512, string);
alias StringBuf1024	= FixedString!(1024, string);

alias WStringBuf32	= FixedString!(32,  wstring);
alias WStringBuf64	= FixedString!(64,  wstring);
alias WStringBuf128	= FixedString!(128, wstring);
alias WStringBuf256	= FixedString!(256, wstring);
alias WStringBuf512	= FixedString!(512, wstring);

alias String	= IString!string;
alias WString	= IString!wstring;

unittest
{
	auto var = UnitTestLogger(0);
	alias Fixed8 = FixedString!(8, string);

	static import std.range;
	//	static assert(std.range.isOutputRange!(Fixed8, char) == true);
	//	static assert(std.range.isOutputRange!(Tmp8, char) == false);
	//	static assert(std.range.isOutputRange!(StringBuf128, char) == true);
	//	static assert(std.range.isOutputRange!(WStringBuf32, wchar) == true);
	static assert(std.range.isInputRange!(StringBuf128.InputRange) == true);
	auto fixed8 = Fixed8("Test%sTest", 5);
	//	formattedWrite(&tmp, "Test%sTest", 5);
	vlPrintlnInfo("tmp = %s", fixed8.dstr);
	assert(fixed8.dstr == "Test5Tes"); // only 8 character

	auto buf = StringBuf128("Test%sTest", 3);
	vlPrintlnInfo("buf.toString = %s", buf.dstr);
	vlPrintlnInfo("buf.mBufStringz = %s", buf.mBufStringz);
	vlPrintlnInfo("buf.mBufStringz length = %s", buf.mBufStringz.length);
	//	std.stdio.writefln("length = %s", mStringImpl.mBufStringz.length);
	assert(buf.dstr == "Test3Test");
	buf.formatz("Add?");
	assert(buf.dstr == "Add?", "buf.dstr = " ~ buf.dstr);
	buf.formatz("This is Test%s. Dlang is %ssmart!", 2, 3);
	assert(buf.dstr == "This is Test2. Dlang is 3smart!");

	vlPrintlnInfo("fixedstring unittest");
}
