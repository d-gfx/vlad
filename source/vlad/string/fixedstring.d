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

struct IString(A : T[], T)
{
	alias Self = IString!(A);
	alias CHAR = Unqual!T;
public:
	A dstr() @property const { return mSlice; }
	alias dstr this; // implicit cast

	const(CHAR)* cstr() const pure
	{
		version(NeedException){}else{
			if (mBuffer is null)
				return cast(ReturnType!(Self.cstr))"\0";
		}
		return cast(ReturnType!(Self.cstr))&mBuffer[0];
	}
	CHAR* cstr() { return &mBuffer[0]; }

	size_t maxSize()	const pure { return max(0, mBuffer.length - 1); } // exclude null-terminated
	size_t maxSizez()	const pure { return mBuffer.length;	 } // include null-terminated
	size_t length()		const pure { return max(0, mSlice.length - 1); }
	size_t lengthz()	const pure { return mSlice.length; } // include null-terminated
	bool	isReady()	const pure { return (mBuffer !is null); }

	/**
	 *	store
	 */
	void opAssign(in Self s)
	in {
		dlAssert(s.isReady(), "source buffer is not ready");
		dlAssert(isReady(), "mBuffer is null");
		dlAssert(s.length <= maxSize(), "s.length[%s] <= maxSize[%s]", s.length, maxSize());
	}
	body {
		s.mBuffer.copy(mBuffer);	// better method
	//	mBuffer[0..s.lengthz] = s.mBuffer[0..s.lengthz];
	}

	/**
	 *	input range for formattedRead
	 */
	struct InputRange
	{
		this (in Self host) { mHost = host; }
		CHAR front() const @property { return mHost.mBuffer[mInputIndex]; }
		CHAR popFront() @property { return mHost.mBuffer[mInputIndex++]; }
		bool empty() const @property { return mInputIndex == mHost.mBuffer.length; }
		size_t	mInputIndex = 0;
		const(Self) mHost;
	}

	/**
	 *	output range for formattedWrite
	 */
	struct OutputRange
	{
		Self mHost;
		this (ref Self host) { mHost = host; }
		void put(U)(U item)
		{
			auto len = mHost.length();
			if (len < mHost.maxSize())
			{
				mHost.mBuffer[len] = item;
				mHost.mBuffer[len+1] = '\0';
				mHost.mSlice = cast(A)mHost.mBuffer[0..len+1]; // not include null-terminated
	//			if (!__ctfe) std.stdio.writefln("len, item, mSlice.length = %s, %s, %s", len, item, mSlice.length);
			}
		}
		void put(const(char)[] s)
		{
//			std.format.sformat(mHost.mBuffer[0..mHost.mBuffer.length], "%s", s);
			foreach (e; s) { put(e); }
		}
	}

	void clear()
	{
		mSlice = null;
		if (mBuffer !is null)	mBuffer[0] = '\0';
	}

	bool isEmpty() const { return mSlice is null; }
	bool isEqualString(A str) const pure { return 0 == cmp(dstr, str); }

	/**
	 *	find null-terminate and make apropriate slice
	 *	when using C-like function ex. win32 api
	 */
	void applySliceUntilZero()
	{
		foreach (int i, ch; mBuffer)
		{
			if (ch == '\0')
			{
				mSlice = cast(A)mBuffer[0..i]; // not include null-terminated
				return;
			}
		}
		// if not found null-terminated
		clear();
	}
private:
	CHAR[]		mBuffer;
	A			mSlice;
}

struct FixedString(int N, A : T[], T)
{
	alias CHAR = Unqual!T;
public:
	const(IString!A) getString() @property const { return mString; }
	alias getString this;
	CHAR* cstr() { trySetupBuffer(); return mString.cstr; }	// non-const version
	void applySliceUntilZero() { return mString.applySliceUntilZero(); }
	void clear() { return mString.clear(); }

	private void trySetupBuffer()
	{
		if (mString.mBuffer is null)
		{
			mString.mBuffer = mFixArray;
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
	 *	フォーマットリード
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
			std.stdio.writefln("Failed formatRead.");
			std.stdio.writefln("%s", e);
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
	auto var = UnitTestBeginEnd(0);
	alias Fixed8 = FixedString!(8, string);

	//	static assert(std.range.isOutputRange!(Fixed8, char) == true);
	//	static assert(std.range.isOutputRange!(Tmp8, char) == false);
	//	static assert(std.range.isOutputRange!(StringBuf128, char) == true);
	//	static assert(std.range.isOutputRange!(WStringBuf32, wchar) == true);
	static assert(std.range.isInputRange!(StringBuf128.InputRange) == true);
	auto fixed8 = Fixed8("Test%sTest", 5);
	//	formattedWrite(&tmp, "Test%sTest", 5);
	std.stdio.writefln("tmp = %s", fixed8.dstr);
	assert(fixed8.dstr == "Test5Tes"); // only 8 character

	auto buf = StringBuf128("Test%sTest", 3);
	std.stdio.writefln("buf.toString = %s", buf.dstr);
	std.stdio.writefln("buf.mBuffer = %s", buf.mBuffer);
	std.stdio.writefln("buf.mBuffer length = %s", buf.mBuffer.length);
	//	std.stdio.writefln("length = %s", mStringImpl.mBuffer.length);
	assert(buf.dstr == "Test3Test");
	buf.formatz("Add?");
	assert(buf.dstr == "Add?", "buf.dstr = " ~ buf.dstr);
	buf.formatz("This is Test%s. Dlang is %ssmart!", 2, 3);
	assert(buf.dstr == "This is Test2. Dlang is 3smart!");
}
