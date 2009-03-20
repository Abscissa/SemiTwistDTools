// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Consider this to be under the zlib license.
*/

module semitwist.util.nonFatalAssert;

import tango.io.Stdout;
import tango.util.Convert;

/**
Sounds like a contradiction of terms, but this is just
intended to allow unittests to output ALL failures instead
of only outputting the first one and then stopping.
*/
// *REALLY* need a way to get file/line of template's instantiation
template NonFatalAssert(long line, char[] file, char[] cond, char[] msg="")
{
	const char[] NonFatalAssert =
	"{\n"~
	"bool _NonFatalAssert_result = "~cond~";\n"~
	"_NonFatalAssert!("~line.stringof~", "~file.stringof~", "~cond.stringof~", "~msg.stringof~")(_NonFatalAssert_result);"~
	"}";
	//pragma(msg, "NonFatalAssert: "~NonFatalAssert);
}

template _NonFatalAssert(long line, char[] file, char[] cond, char[] msg="")
{
	bool _NonFatalAssert(bool result)
	{
		if(!result)
		{
			nonFatalAssertCount++;
			Stdout.formatln("{}({}): Assert Failure ({}){}",
			                file, line, cond,
						    msg=="" ? "" : ": " ~ msg);
		}
		
		return result;
	}
}
private uint nonFatalAssertCount=0;
uint getNonFatalAssertCount()
{
	return nonFatalAssertCount;
}
void resetNonFatalAssertCount()
{
	nonFatalAssertCount = 0;
}

void FatalizeAsserts()
{
	if(getNonFatalAssertCount() > 0)
	{
		Stdout.flush();
		assert(false,
			to!(char[])(getNonFatalAssertCount()) ~
			" Assert Failure" ~
			(getNonFatalAssertCount() == 1 ? "" : "s")
		);
	}
}
