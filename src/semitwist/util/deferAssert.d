// SemiTwist Library
// Written in the D programming language.

module semitwist.util.deferAssert;

// deferEnsure requires this to exist in the calling context
//public import semitwist.util.reflect;

import tango.io.Stdout;
import tango.util.Convert;

import semitwist.util.all;

//TODO: Properly handle stuff that (for whatever bizarre reason) throws null.
//TODO: Modify deferEnsureThrows to (optionally?) accept subclasses of TExpected
//TODO? Change deferEnsureThrows to take an expression instead of a statement
//TODO? Better naming convention


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
		Stdout.formatln("Object: type '{}': {}", thrown.classinfo.name, thrown);
}

//TODO: Something like: mixin(blah!(`_1 == (_2 ~ _3)`, `"Hello"`, `"He"`, `"llo"`));

template deferEnsure(char[] value, char[] condStr, char[] msg="")
{
	const char[] deferEnsure =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ const long _deferAssert_line = __LINE__;\n"~
	"    try\n"~
	"    {\n"~
	"        auto _ = ("~value~");\n"~
	"        bool _deferAssert_condResult = ("~condStr~");\n"~
	"        _deferEnsure!(_deferAssert_line, __FILE__, "~value.stringof~", "~condStr.stringof~", ExprTypeOf!(typeof("~value~")), "~msg.stringof~")(_, _deferAssert_condResult);\n"~
	"    }\n"~
	"    catch(Object _deferAssert_e)\n"~
	"        _deferEnsureException!(_deferAssert_line, __FILE__, "~value.stringof~", "~condStr.stringof~", "~msg.stringof~")(_deferAssert_e);\n"~
	"}\n";
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
		Stdout.formatln("Object: type '{}': {}", thrown.classinfo.name, thrown);
}

template deferEnsureThrows(char[] stmtStr, TExpected, char[] msg="")
{
	const char[] deferEnsureThrows =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ const long _deferAssert_line = __LINE__;\n"~
	"    Object _deferAssert_caught=null;\n"~
	"    try\n"~
	"    {"~stmtStr~"}\n"~
	"    catch(Object _deferAssert_e)\n"~
	"        _deferAssert_caught = _deferAssert_e;\n"~
	"    _deferEnsureThrows!(_deferAssert_line, __FILE__, "~stmtStr.stringof~", "~TExpected.stringof~", "~msg.stringof~")(_deferAssert_caught);\n"~
	"}\n";
}

void _deferEnsureThrows(long line, char[] file, char[] stmtStr, TExpected, char[] msg="")(Object thrown)
{
	char[] actualType = (thrown is null)? "{null}" : thrown.classinfo.name;
	
	if(actualType != TExpected.classinfo.name)
	{
		assertCount++;
		Stdout.format("{}({}): Ensure Throw Failed{}\n"~
		              "Statement '{}':\n"~
		              "Expected: {}\n"~
		              "Actual:   ",
		              file, line, msg=="" ? "" : ": " ~ msg,
		              stmtStr, TExpected.classinfo.name, actualType);
		Exception e = cast(Exception)thrown;
		if(e)
			e.writeOut( (char[] msg) {Stdout(msg);} );
		else
			Stdout.formatln("{}: {}", actualType, thrown);
	}
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
	if(assertCount > 0)
	{
		uint saveAssertCount = assertCount;
		assertCount = 0;
		Stdout.flush();
		assert(false,
			to!(char[])(saveAssertCount) ~
			" Assert Failure" ~
			(saveAssertCount == 1 ? "" : "s")
		);
	}
}
