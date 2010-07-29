// SemiTwist Library
// Written in the D programming language.

module semitwist.util.deferAssert;

// deferEnsure requires this to exist in the calling context
import std.traits;//tango.core.Traits : _deferAssert_ExprTypeOf = ExprTypeOf;
public import semitwist.util.reflect : _deferAssert_ExprTypeOf = ExprTypeOf;

import std.stdio;//tango.io.Stdout;
//import tango.util.Convert;
import std.conv;

import semitwist.util.all;
import semitwist.util.compat.all;

//TODO: Properly handle stuff that (for whatever bizarre reason) throws null.
//TODO: Modify deferEnsureThrows to (optionally?) accept subclasses of TExpected
//TODO? Change deferEnsureThrows to take an expression instead of a statement
//TODO? Better naming convention


/**
Sounds like a contradiction of terms, but this is just
intended to allow unittests to output ALL failures instead
of only outputting the first one and then stopping.
*/
template deferAssert(string condStr, string msg="")
{
	const string deferAssert =
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

bool _deferAssert(long line, string file, string condStr, string msg="")(bool condResult)
{
	if(!condResult)
	{
		assertCount++;
		writefln("%s(%s): Assert Failed (%s)%s",
		         file, line, condStr,
		         msg=="" ? "" : ": " ~ msg);
	}
	
	return condResult;
}

void _deferAssertException(long line, string file, string condStr, string msg="")(Object thrown)
{
	assertCount++;
	writef("%s(%s): Assert Threw (%s)%s:\nThrew: ",
	       file, line, condStr,
	       msg=="" ? "" : ": " ~ msg);
	Exception e = cast(Exception)thrown;
	if(e)
		write(thrown);
	else
		writefln("Object: type '%s': %s", thrown.classinfo.name, thrown);
}

//TODO: Something like: mixin(blah!(`_1 == (_2 ~ _3)`, `"Hello"`, `"He"`, `"llo"`));

template deferEnsure(string value, string condStr, string msg="")
{
	const string deferEnsure =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ const long _deferAssert_line = __LINE__;\n"~
	"    try\n"~
	"    {\n"~
	"        auto _ = ("~value~");\n"~
	"        bool _deferAssert_condResult = ("~condStr~");\n"~
	"        _deferEnsure!(_deferAssert_line, __FILE__, "~value.stringof~", "~condStr.stringof~", _deferAssert_ExprTypeOf!(typeof("~value~")), "~msg.stringof~")(_, _deferAssert_condResult);\n"~
	"    }\n"~
	"    catch(Object _deferAssert_e)\n"~
	"        _deferEnsureException!(_deferAssert_line, __FILE__, "~value.stringof~", "~condStr.stringof~", "~msg.stringof~")(_deferAssert_e);\n"~
	"}\n";
}

bool _deferEnsure(long line, string file, string valueStr, string condStr, T, string msg="")(T valueResult, bool condResult)
{
	if(!condResult)
	{
		assertCount++;
		writefln("%s(%s): Ensure Failed%s\n"~
		         "Expression '%s':\n"~
		         "Expected: %s\n"~
		         "Actual: %s",
		         file, line, msg=="" ? "" : ": " ~ msg,
		         valueStr, condStr, valueResult);
	}
	
	return condResult;
}

void _deferEnsureException(long line, string file, string valueStr, string condStr, string msg="")(Object thrown)
{
	assertCount++;
	writef("%s(%s): Ensure Threw%s:\n"~
	       "Expression '%s':\n"~
	       "Expected: %s\n"~
	       "Threw: ",
	       file, line, msg=="" ? "" : ": " ~ msg,
	       valueStr, condStr);
	Exception e = cast(Exception)thrown;
	if(e)
		write(thrown);
	else
		writefln("Object: type '%s': %s", thrown.classinfo.name, thrown);
}

template deferEnsureThrows(string stmtStr, TExpected, string msg="")
{
	const string deferEnsureThrows =
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

void _deferEnsureThrows(long line, string file, string stmtStr, TExpected, string msg="")(Object thrown)
{
	string actualType = (thrown is null)? "{null}" : thrown.classinfo.name;
	
	if(actualType != TExpected.classinfo.name)
	{
		assertCount++;
		writef("%s(%s): Ensure Throw Failed%s\n"~
		       "Statement '%s':\n"~
		       "Expected: %s\n"~
		       "Actual:   ",
		       file, line, msg=="" ? "" : ": " ~ msg,
		       stmtStr, TExpected.classinfo.name, actualType);
		Exception e = cast(Exception)thrown;
		if(e)
			e.writeOut( (string msg) {Stdout(msg);} );
		else
			writefln("%s: %s", actualType, thrown);
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
		stdout.flush();
		assert(false,
			to!(string)(saveAssertCount) ~
			" Assert Failure" ~
			(saveAssertCount == 1 ? "" : "s")
		);
	}
}
