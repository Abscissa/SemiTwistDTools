// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Consider this to be under the zlib license.
*/

module semitwist.util.deferAssert;

// deferEnsure requires this to exist in the calling context
public import semitwist.util.reflect;

import tango.io.Stdout;
import tango.util.Convert;

import semitwist.util.text;

/**
Sounds like a contradiction of terms, but this is just
intended to allow unittests to output ALL failures instead
of only outputting the first one and then stopping.
*/
template deferAssert(char[] condStr, char[] msg="")
{
	const char[] deferAssert =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ const long _deferAssert_line = __LINE__;\n"~
	"    try\n"~
	"    {\n"~
	"        bool _deferAssert_condResult = ("~condStr~");\n"~
	"        _deferAssert!(_deferAssert_line, __FILE__, "~condStr.stringof~", "~msg.stringof~")(_deferAssert_condResult);\n"~
	"    }\n"~
	"    catch(Object _deferAssert_e)\n"~
	"        _deferAssertException!(_deferAssert_line, __FILE__, "~condStr.stringof~", "~msg.stringof~")(_deferAssert_e);\n"~
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

void _deferAssertException(long line, char[] file, char[] condStr, char[] msg="")(Object thrown)
{
	assertCount++;
	Stdout.format("{}({}): Assert Threw ({}){}:\nThrew: ",
				  file, line, condStr,
				  msg=="" ? "" : ": " ~ msg);
	Exception e = cast(Exception)thrown;
	if(e)
		e.writeOut( (char[] msg) {Stdout(msg);} );
	else
		Stdout.formatln("Object: type '{}':\n{}", thrown.classinfo.name, thrown);
}

//TODO: Something like: mixin(blah!(`_1 == (_2 ~ _3)`, `"Hello"`, `"He"`, `"llo"`));

template deferEnsure(char[] value, char[] condStr, char[] msg="")
{
	const char[] deferEnsure =
	// The "_deferEnsure_line" is a workaround for DMD Bug #2887
	"{ const long _deferEnsure_line = __LINE__;\n"~
	"    try\n"~
	"    {\n"~
	"        auto _ = ("~value~");\n"~
	"        bool _deferEnsure_condResult = ("~condStr~");\n"~
	"        _deferEnsure!(_deferEnsure_line, __FILE__, "~value.stringof~", "~condStr.stringof~", ExprTypeOf!(typeof("~value~")), "~msg.stringof~")(_, _deferEnsure_condResult);\n"~
	"    }\n"~
	"    catch(Object _deferEnsure_e)\n"~
	"        _deferEnsureException!(_deferEnsure_line, __FILE__, "~value.stringof~", "~condStr.stringof~", "~msg.stringof~")(_deferEnsure_e);\n"~
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

void _deferEnsureException(long line, char[] file, char[] valueStr, char[] condStr, char[] msg="")(Object thrown)
{
	assertCount++;
	Stdout.format("{}({}): Ensure Threw{}:\n"~
				  "Expression '{}':\n"~
				  "Expected: {}\n"~
				  "Threw: ",
				  file, line, msg=="" ? "" : ": " ~ msg,
				  valueStr, condStr);
	Exception e = cast(Exception)thrown;
	if(e)
		e.writeOut( (char[] msg) {Stdout(msg);} );
	else
		Stdout.formatln("Object: type '{}':\n{}", thrown.classinfo.name, thrown);
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
