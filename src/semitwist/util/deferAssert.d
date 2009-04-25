// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Consider this to be under the zlib license.
*/

//TODO? Rename this module to assert or deferAssert
module semitwist.util.deferAssert;

import tango.io.Stdout;
import tango.util.Convert;

/**
Sounds like a contradiction of terms, but this is just
intended to allow unittests to output ALL failures instead
of only outputting the first one and then stopping.
*/
template deferAssert(char[] condStr, char[] msg="")
{
	const char[] deferAssert =
	"{\n"~
	"    bool _deferAssert_condResult = ("~condStr~");\n"~
	// The "__LINE__-2" is a workaround for DMD Bug #2887
	"    _deferAssert!(__LINE__-2, __FILE__, "~condStr.stringof~", "~msg.stringof~")(_deferAssert_condResult);\n"~
	"}\n";
	//pragma(msg, "deferAssert: "~deferAssert);
}

bool _deferAssert(long line, char[] file, char[] condStr, char[] msg="")(bool condResult)
{
	if(!condResult)
	{
		assertCount++;
		Stdout.formatln("{}({}): Assert Failed ({}){}",
						file, line, condStr,
						msg=="" ? "" : ": " ~ msg);
	}
	
	return condResult;
}

template deferEnsure(char[] value, char[] condStr, char[] msg="")
{
	const char[] deferEnsure =
	"{\n"~
	"    auto _ = ("~value~");\n"~
	"    bool _deferEnsure_condResult = ("~condStr~");\n"~
	// The "__LINE__-3" is a workaround for DMD Bug #2887
	"    _deferEnsure!(__LINE__-3, __FILE__, "~value.stringof~", "~condStr.stringof~", typeof("~value~"), "~msg.stringof~")(_, _deferEnsure_condResult);\n"~
	"}\n";
	//pragma(msg, "deferEnsure: "~deferEnsure);
}

bool _deferEnsure(long line, char[] file, char[] valueStr, char[] condStr, T, char[] msg="")(T valueResult, bool condResult)
{
	if(!condResult)
	{
		assertCount++;
		Stdout.formatln("{}({}): Ensure Failed{}\n"~
		                "Expression '{}':\n"~
						"Expected: {}\n"~
						"Actual: {}",
						file, line, msg=="" ? "" : ": " ~ msg,
						valueStr, condStr, valueResult);
	}
	
	return condResult;
}
private uint assertCount=0;
uint getAssertCount()
{
	return assertCount;
}
void resetAssertCount()
{
	assertCount = 0;
}

void flushAsserts()
{
	if(getAssertCount() > 0)
	{
		Stdout.flush();
		assert(false,
			to!(char[])(getAssertCount()) ~
			" Assert Failure" ~
			(getAssertCount() == 1 ? "" : "s")
		);
	}
}
