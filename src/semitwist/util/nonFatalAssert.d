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
template NonFatalAssert(long line, char[] file, char[] condStr, char[] msg="")
{
	const char[] NonFatalAssert =
	"{\n"~
	"    bool _NonFatalAssert_condResult = ("~condStr~");\n"~
	"    _NonFatalAssert!("~line.stringof~", "~file.stringof~", "~condStr.stringof~", "~msg.stringof~")(_NonFatalAssert_condResult);\n"~
	"}\n";
	//pragma(msg, "NonFatalAssert: "~NonFatalAssert);
}

bool _NonFatalAssert(long line, char[] file, char[] condStr, char[] msg="")(bool condResult)
{
	if(!condResult)
	{
		nonFatalAssertCount++;
		Stdout.formatln("{}({}): Assert Failed ({}){}",
						file, line, condStr,
						msg=="" ? "" : ": " ~ msg);
	}
	
	return condResult;
}

template NonFatalEnsure(long line, char[] file, alias value, char[] condStr, char[] msg="")
{
	const char[] NonFatalEnsure =
	"{\n"~
	"    "~typeof(value).stringof~" _ = ("~value.stringof~");\n"~
	"    bool _NonFatalEnsure_condResult = ("~condStr~");\n"~
	"    _NonFatalEnsure!("~line.stringof~", "~file.stringof~", `"~value.stringof~"`, "~condStr.stringof~", "~typeof(value).stringof~", "~msg.stringof~")(_, _NonFatalEnsure_condResult);\n"~
	"}\n";
	//pragma(msg, "NonFatalEnsure: "~NonFatalEnsure);
}

bool _NonFatalEnsure(long line, char[] file, char[] valueStr, char[] condStr, T, char[] msg="")(T valueResult, bool condResult)
{
	if(!condResult)
	{
		nonFatalAssertCount++;
		Stdout.formatln("{}({}): Ensure Failed{}\n"~
		                "Value '{}':\n"~
						"Expected: {}\n"~
						"Actual: {}",
						file, line, msg=="" ? "" : ": " ~ msg,
						valueStr, condStr, valueResult);
	}
	
	return condResult;
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
