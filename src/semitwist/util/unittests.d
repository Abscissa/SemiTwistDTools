// SemiTwist Library
// Written in the D programming language.

module semitwist.util.unittests;

// deferEnsure requires this to exist in the calling context
public import semitwist.util.reflect : _deferAssert_ExprTypeOf = ExprTypeOf;

import std.conv;
import std.demangle;
import std.stdio;
import std.traits;

import semitwist.util.all;

/**
Sounds like a contradiction of terms, but this is just
intended to allow unittests to output ALL failures instead
of only outputting the first one and then stopping.
*/
template deferAssert(string condStr, string msg="")
{
	enum deferAssert =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ enum long _deferAssert_line = __LINE__;\n"~
	"    try\n"~
	"    {\n"~
	"        bool _deferAssert_condResult = ("~condStr~")?true:false;\n"~
	"        _deferAssert!(_deferAssert_line, __FILE__, "~condStr.stringof~", "~msg.stringof~")(_deferAssert_condResult);\n"~
	"    }\n"~
	"    catch(Throwable _deferAssert_e)\n"~
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
		writeln();
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
		writeln(thrown);
	else
		writefln("Object: type '%s': %s", thrown.classinfo.name, thrown);
	writeln();
}

//TODO: Something like: mixin(blah!(`_1 == (_2 ~ _3)`, `"Hello"`, `"He"`, `"llo"`));

template deferEnsure(string value, string condStr, string msg="")
{
	enum deferEnsure =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ enum long _deferAssert_line = __LINE__;\n"~
	"    try\n"~
	"    {\n"~
	"        auto _ = ("~value~");\n"~
	"        bool _deferAssert_condResult = ("~condStr~")?true:false;\n"~
	"        _deferEnsure!(_deferAssert_line, __FILE__, "~value.stringof~", "~condStr.stringof~", _deferAssert_ExprTypeOf!(typeof("~value~")), "~msg.stringof~")(_, _deferAssert_condResult);\n"~
	"    }\n"~
	"    catch(Throwable _deferAssert_e)\n"~
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
		writeln();
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
		writeln(thrown);
	else
		writefln("Object: type '%s': %s", thrown.classinfo.name, thrown);
	writeln();
}

template deferEnsureThrows(string stmtStr, TExpected, string msg="")
{
	enum deferEnsureThrows =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ enum long _deferAssert_line = __LINE__;\n"~
	"    Object _deferAssert_caught=null;\n"~
	"    try\n"~
	"    {"~stmtStr~"}\n"~
	"    catch(Throwable _deferAssert_e)\n"~
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
		Throwable e = cast(Exception)thrown;
		if(e)
			writeln(e); //e.writeOut( (string msg) {Stdout(msg);} );
		else
			writefln("%s: %s", actualType, thrown);
		writeln();
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

/++
To be mixed in.

Note that if DMD Issue #2887 ever gets fixed, the line numbers for errors
in unittestBody may get messed up.

Suggested Usage:
-------------------
alias unittestSection!"MyProject_unittest" unittestMyProject;

mixin(unittestMyProject(q{
	// put unittests here
}));

mixin(unittestMyProject("This is for class Foo", q{
	// put unittests here
}));
-------------------

That will create a named unittest section that will only run
when -unittest and -debug=MyProject_unittest are passed to DMD.
When run, the following headings will be displayed:

== unittest: the.module.name
== unittest: the.module.name: This is for class Foo
+/
string unittestSection(string debugIdent, bool autoThrow=false)(string sectionName, string unittestBody=null)
{
	// Allow these two forms (without getting in the way of aliasing):
	//   unittestSection!debugIdent(unittestBody)
	//   unittestSection!debugIdent(sectionName, unittestBody)
	if(unittestBody==null)
	{
		unittestBody = sectionName;
		sectionName = "";
	}
	sectionName = ( sectionName==""? "" : ": "~sectionName ).escapeDDQS();
	auto autoThrowStr = autoThrow? "true" : "false";
	
	return
		"debug("~debugIdent~") "~
		"{ "~
		"	unittest "~
		"	{ "~
		"		auto saveAutoThrow = semitwist.util.unittests.autoThrow; "~
		"		semitwist.util.unittests.autoThrow = "~autoThrowStr~"; "~
		"		scope(exit) semitwist.util.unittests.autoThrow = saveAutoThrow; "~
		"		 "~
		"		int _unittestSection_dummy_; "~
		"		auto _unittestSection_moduleName_ = "~
		"			unittestSection_demangle( qualifiedName!_unittestSection_dummy_() ) "~
		"				[ "~
		"					\"void \".length .. "~
		"					ctfe_find(unittestSection_demangle( qualifiedName!_unittestSection_dummy_() ), \".__unittest\") "~
		"				]; "~
		" "~
		"		writeUnittestSection( "~
		"			_unittestSection_moduleName_ ~ "~
		"			"~sectionName~" "~
		"		); "~
		"		"~unittestBody~" "~
		"	} "~
		"} ";
}
alias mangledName unittestSection_mangledName;
alias demangle unittestSection_demangle;

void writeUnittestSection(string sectionName)
{
	writeln("== unittest: ", sectionName);
}

alias unittestSection!"SemiTwistDLib_unittest" unittestSemiTwistDLib;

///////////////////////////////////////////////////////////////////////////////

/// A modification of Jonathan M Davis's unittest routines below:

//Ideally, this would be safe, I suppose, but it's enough of
//a pain at the moment to make stuff safe that I'm just going to
//mark it as trusted for the moment.
@trusted


import std.stdio;

import core.exception;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.functional;
import std.range;
import std.string;
import std.traits;

/// This does not currently affect the defer* functions above.
bool autoThrow = true;

private void throwException(Throwable e)
{
	if(autoThrow)
		throw e;
	else
	{
		assertCount++;
		writeln(e);
		writeln();
	}
}

version(unittest)
{
    import std.datetime;
}


mixin(unittestSemiTwistDLib("assertPred: Overview Examples", q{
	autoThrow = true;

    //Verify Examples.
    assertPred!"=="(5 * 7, 35);

    assertPred!("opCmp", ">")(std.datetime.Clock.currTime(), std.datetime.SysTime(Date(1970, 1, 1)));

    assertPred!"opAssign"(std.datetime.SysTime(Date(1970, 1, 1)),
                          std.datetime.SysTime(Date(2010, 12, 31)));

    assertPred!"+"(5, 7, 12);

    assertPred!"+="(std.datetime.SysTime(Date(1970, 1, 1)),
                    core.time.dur!"days"(3),
                    std.datetime.SysTime(Date(1970, 1, 4)));

    assertPred!"a == 7"(12 - 5);

    assertPred!"a == b + 5"(12, 7);

    assertPred!((int a, int b, int c){return a + b < c;})(4, 12, 50);
}));


void assertPred(string op, L, R)
               (L lhs, R rhs, lazy string msg = null, string file = __FILE__, size_t line = __LINE__)
    if((op == "<" ||
        op == "<=" ||
        op == "==" ||
        op == "!=" ||
        op == ">=" ||
        op == ">") &&
       __traits(compiles, mixin("lhs " ~ op ~ " rhs")) &&
       isPrintable!L &&
       isPrintable!R)
{
    immutable result = mixin("lhs " ~ op ~ " rhs");

    if(!result)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertPred!\"%s\" failed:\n[%s] (lhs)\n[%s] (rhs)%s", op, lhs, rhs, tail),
                                        file,
                                        line)
		);
    }
}

mixin(unittestSemiTwistDLib("assertPred: Comparison Operators", q{
	autoThrow = true;

    struct IntWrapper
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        string toString()
        {
            return to!string(value);
        }
    }

    //Test ==.
    assertNotThrown!AssertError(assertPred!"=="(6, 6));
    assertNotThrown!AssertError(assertPred!"=="(6, 6.0));
    assertNotThrown!AssertError(assertPred!"=="(IntWrapper(6), IntWrapper(6)));

    assertThrown!AssertError(assertPred!"=="(6, 7));
    assertThrown!AssertError(assertPred!"=="(6, 6.1));
    assertThrown!AssertError(assertPred!"=="(IntWrapper(6), IntWrapper(7)));
    assertThrown!AssertError(assertPred!"=="(IntWrapper(7), IntWrapper(6)));

    assertPred!"=="(collectExceptionMsg(assertPred!"=="(6, 7)),
                    "assertPred!\"==\" failed:\n[6] (lhs)\n[7] (rhs).");
    assertPred!"=="(collectExceptionMsg(assertPred!"=="(6, 7, "It failed!")),
                    "assertPred!\"==\" failed:\n[6] (lhs)\n[7] (rhs): It failed!");

    //Test !=.
    assertNotThrown!AssertError(assertPred!"!="(6, 7));
    assertNotThrown!AssertError(assertPred!"!="(6, 6.1));
    assertNotThrown!AssertError(assertPred!"!="(IntWrapper(6), IntWrapper(7)));
    assertNotThrown!AssertError(assertPred!"!="(IntWrapper(7), IntWrapper(6)));

    assertThrown!AssertError(assertPred!"!="(6, 6));
    assertThrown!AssertError(assertPred!"!="(6, 6.0));
    assertThrown!AssertError(assertPred!"!="(IntWrapper(6), IntWrapper(6)));

    assertPred!"=="(collectExceptionMsg(assertPred!"!="(6, 6)),
                    "assertPred!\"!=\" failed:\n[6] (lhs)\n[6] (rhs).");
    assertPred!"=="(collectExceptionMsg(assertPred!"!="(6, 6, "It failed!")),
                    "assertPred!\"!=\" failed:\n[6] (lhs)\n[6] (rhs): It failed!");

    //Test <, <=, >=, >.
    assertNotThrown!AssertError(assertPred!"<"(5, 7));
    assertNotThrown!AssertError(assertPred!"<="(5, 7));
    assertNotThrown!AssertError(assertPred!"<="(5, 5));
    assertNotThrown!AssertError(assertPred!">="(7, 7));
    assertNotThrown!AssertError(assertPred!">="(7, 5));
    assertNotThrown!AssertError(assertPred!">"(7, 5));

    assertThrown!AssertError(assertPred!"<"(7, 5));
    assertThrown!AssertError(assertPred!"<="(7, 5));
    assertThrown!AssertError(assertPred!">="(5, 7));
    assertThrown!AssertError(assertPred!">"(5, 7));

    assertPred!"=="(collectExceptionMsg(assertPred!"<"(7, 5)),
                    "assertPred!\"<\" failed:\n[7] (lhs)\n[5] (rhs).");
    assertPred!"=="(collectExceptionMsg(assertPred!"<"(7, 5, "It failed!")),
                    "assertPred!\"<\" failed:\n[7] (lhs)\n[5] (rhs): It failed!");

    //Test default arguments.
    assertPred!"=="(12, 12);
    assertPred!"=="(12, 12, "msg");
    assertPred!"=="(12, 12, "msg", "file");
    assertPred!"=="(12, 12, "msg", "file", 42);

    //Verify Examples.
    assertPred!"<"(5 / 2 + 4, 27);

    assertPred!"<="(4, 5);

    assertPred!"=="(1 * 2.1, 2.1);

    assertPred!"!="("hello " ~ "world", "goodbye world");

    assertPred!">="(14.2, 14);

    assertPred!">"(15, 2 + 1);

    assert(collectExceptionMsg(assertPred!"=="("hello", "goodbye")) ==
           "assertPred!\"==\" failed:\n" ~
           "[hello] (lhs)\n" ~
           "[goodbye] (rhs).");

    assert(collectExceptionMsg(assertPred!"<"(5, 2, "My test failed!")) ==
           "assertPred!\"<\" failed:\n" ~
           "[5] (lhs)\n" ~
           "[2] (rhs): My test failed!");
}));


void assertPred(string func, string expected, L, R)
               (L lhs, R rhs, lazy string msg = null, string file = __FILE__, size_t line = __LINE__)
    if(func == "opCmp" &&
       (expected == "<" ||
        expected == "==" ||
        expected == ">") &&
       __traits(compiles, lhs.opCmp(rhs)) &&
       isPrintable!L &&
       isPrintable!R)
{
    immutable result = lhs.opCmp(rhs);

    if(mixin("result " ~ expected ~ " 0"))
        return;

    immutable tail = msg.empty ? "." : ": " ~ msg;
    immutable actual = result < 0 ? "<" : (result == 0 ? "==" : ">");

    throwException( new AssertError(format("assertPred!(\"opCmp\", \"%s\") failed:\n[%s] %s\n[%s]%s", expected, lhs, actual, rhs, tail),
                                    file,
                                    line)
	);
}

mixin(unittestSemiTwistDLib("assertPred: opCmp", q{
	autoThrow = true;

    struct IntWrapper
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        int opCmp(const ref IntWrapper rhs) const
        {
            if(value < rhs.value)
                return -1;
            else if(value > rhs.value)
                return 1;

            return 0;
        }

        string toString()
        {
            return to!string(value);
        }
    }

    assertNotThrown!AssertError(assertPred!("opCmp", "<")(IntWrapper(0), IntWrapper(6)));
    assertNotThrown!AssertError(assertPred!("opCmp", "<")(IntWrapper(6), IntWrapper(7)));
    assertNotThrown!AssertError(assertPred!("opCmp", "==")(IntWrapper(6), IntWrapper(6)));
    assertNotThrown!AssertError(assertPred!("opCmp", "==")(IntWrapper(0), IntWrapper(0)));
    assertNotThrown!AssertError(assertPred!("opCmp", ">")(IntWrapper(6), IntWrapper(0)));
    assertNotThrown!AssertError(assertPred!("opCmp", ">")(IntWrapper(7), IntWrapper(6)));

    assertThrown!AssertError(assertPred!("opCmp", "<")(IntWrapper(6), IntWrapper(6)));
    assertThrown!AssertError(assertPred!("opCmp", "<")(IntWrapper(7), IntWrapper(6)));
    assertThrown!AssertError(assertPred!("opCmp", "==")(IntWrapper(6), IntWrapper(7)));
    assertThrown!AssertError(assertPred!("opCmp", "==")(IntWrapper(7), IntWrapper(6)));
    assertThrown!AssertError(assertPred!("opCmp", ">")(IntWrapper(6), IntWrapper(6)));
    assertThrown!AssertError(assertPred!("opCmp", ">")(IntWrapper(6), IntWrapper(7)));

    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "<")(IntWrapper(5), IntWrapper(5))),
                    "assertPred!(\"opCmp\", \"<\") failed:\n[5] ==\n[5].");
    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "<")(IntWrapper(5), IntWrapper(5), "It failed!")),
                    "assertPred!(\"opCmp\", \"<\") failed:\n[5] ==\n[5]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "<")(IntWrapper(14), IntWrapper(7))),
                    "assertPred!(\"opCmp\", \"<\") failed:\n[14] >\n[7].");
    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "<")(IntWrapper(14), IntWrapper(7), "It failed!")),
                    "assertPred!(\"opCmp\", \"<\") failed:\n[14] >\n[7]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "==")(IntWrapper(5), IntWrapper(7))),
                    "assertPred!(\"opCmp\", \"==\") failed:\n[5] <\n[7].");
    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "==")(IntWrapper(5), IntWrapper(7), "It failed!")),
                    "assertPred!(\"opCmp\", \"==\") failed:\n[5] <\n[7]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "==")(IntWrapper(14), IntWrapper(7))),
                    "assertPred!(\"opCmp\", \"==\") failed:\n[14] >\n[7].");
    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", "==")(IntWrapper(14), IntWrapper(7), "It failed!")),
                    "assertPred!(\"opCmp\", \"==\") failed:\n[14] >\n[7]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", ">")(IntWrapper(5), IntWrapper(7))),
                    "assertPred!(\"opCmp\", \">\") failed:\n[5] <\n[7].");
    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", ">")(IntWrapper(5), IntWrapper(7), "It failed!")),
                    "assertPred!(\"opCmp\", \">\") failed:\n[5] <\n[7]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", ">")(IntWrapper(7), IntWrapper(7))),
                    "assertPred!(\"opCmp\", \">\") failed:\n[7] ==\n[7].");
    assertPred!"=="(collectExceptionMsg(assertPred!("opCmp", ">")(IntWrapper(7), IntWrapper(7), "It failed!")),
                    "assertPred!(\"opCmp\", \">\") failed:\n[7] ==\n[7]: It failed!");

    //Test default arguments.
    assertPred!("opCmp", "<")(Date(2010, 11, 30), Date(2010, 12, 31));
    assertPred!("opCmp", "<")(Date(2010, 11, 30), Date(2010, 12, 31), "msg");
    assertPred!("opCmp", "<")(Date(2010, 11, 30), Date(2010, 12, 31), "msg", "file");
    assertPred!("opCmp", "<")(Date(2010, 11, 30), Date(2010, 12, 31), "msg", "file", 42);

    assertPred!("opCmp", "==")(Date(2010, 12, 31), Date(2010, 12, 31));
    assertPred!("opCmp", "==")(Date(2010, 12, 31), Date(2010, 12, 31), "msg");
    assertPred!("opCmp", "==")(Date(2010, 12, 31), Date(2010, 12, 31), "msg", "file");
    assertPred!("opCmp", "==")(Date(2010, 12, 31), Date(2010, 12, 31), "msg", "file", 42);

    assertPred!("opCmp", ">")(Date(2010, 12, 31), Date(2010, 11, 30));
    assertPred!("opCmp", ">")(Date(2010, 12, 31), Date(2010, 11, 30), "msg");
    assertPred!("opCmp", ">")(Date(2010, 12, 31), Date(2010, 11, 30), "msg", "file");
    assertPred!("opCmp", ">")(Date(2010, 12, 31), Date(2010, 11, 30), "msg", "file", 42);
}));

mixin(unittestSemiTwistDLib("assertPred: opCmp: Examples", q{
	autoThrow = true;

    //Verify Examples
    assertPred!("opCmp", "<")(std.datetime.SysTime(Date(1970, 1, 1)),
                              std.datetime.SysTime(Date(2010, 12, 31)));

    assertPred!("opCmp", "==")(std.datetime.SysTime(Date(1970, 1, 1)),
                               std.datetime.SysTime(Date(1970, 1, 1)));

    assertPred!("opCmp", ">")(std.datetime.SysTime(Date(2010, 12, 31)),
                              std.datetime.SysTime(Date(1970, 1, 1)));

    assert(collectExceptionMsg(assertPred!("opCmp", "<")(std.datetime.SysTime(Date(2010, 12, 31)),
                                                         std.datetime.SysTime(Date(1970, 1, 1)))) ==
           "assertPred!(\"opCmp\", \"<\") failed:\n" ~
           "[2010-Dec-31 00:00:00] >\n" ~
           "[1970-Jan-01 00:00:00].");

    assert(collectExceptionMsg(assertPred!("opCmp", "==")(std.datetime.SysTime(Date(1970, 1, 1)),
                                                          std.datetime.SysTime(Date(2010, 12, 31)))) ==
           "assertPred!(\"opCmp\", \"==\") failed:\n" ~
           "[1970-Jan-01 00:00:00] <\n" ~
           "[2010-Dec-31 00:00:00].");

    assert(collectExceptionMsg(assertPred!("opCmp", ">")(std.datetime.SysTime(Date(1970, 1, 1)),
                                                         std.datetime.SysTime(Date(1970, 1, 1)))) ==
           "assertPred!(\"opCmp\", \">\") failed:\n" ~
           "[1970-Jan-01 00:00:00] ==\n" ~
           "[1970-Jan-01 00:00:00].");
}));


void assertPred(string func, L, R)
               (L lhs, R rhs, lazy string msg = null, string file = __FILE__, size_t line = __LINE__)
    if(func == "opAssign" &&
       __traits(compiles, lhs = rhs) &&
       __traits(compiles, lhs == rhs) &&
       __traits(compiles, (lhs = rhs) == rhs) &&
       isPrintable!L &&
       isPrintable!R)
{
    auto result = lhs = rhs;

    if(lhs != rhs)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertPred!\"opAssign\" failed: lhs was assigned to\n[%s] instead of\n[%s]%s",
                                               lhs,
                                               rhs,
                                               tail),
                                        file,
                                        line)
		);
    }

    if(result != rhs)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertPred!\"opAssign\" failed:\n[%s] (return value) !=\n[%s] (assigned value)%s",
                                               result,
                                               rhs,
                                               tail),
                                        file,
                                        line)
		);
    }
}

mixin(unittestSemiTwistDLib("assertPred: opAssign", q{
	autoThrow = true;

    struct IntWrapper
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        IntWrapper opAssign(IntWrapper rhs)
        {
            this.value = rhs.value;

            return this;
        }

        string toString()
        {
            return to!string(value);
        }
    }

    struct IntWrapper_BadAssign
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        IntWrapper_BadAssign opAssign(IntWrapper_BadAssign rhs)
        {
            this.value = -rhs.value;

            return IntWrapper_BadAssign(rhs.value);
        }

        string toString()
        {
            return to!string(value);
        }
    }

    struct IntWrapper_BadReturn
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        IntWrapper_BadReturn opAssign(IntWrapper_BadReturn rhs)
        {
            this.value = rhs.value;

            return IntWrapper_BadReturn(-rhs.value);
        }

        string toString()
        {
            return to!string(value);
        }
    }

    assertNotThrown!AssertError(assertPred!"opAssign"(IntWrapper(5), IntWrapper(2)));

    assertThrown!AssertError(assertPred!"opAssign"(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2)));
    assertThrown!AssertError(assertPred!"opAssign"(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2)));

    assertPred!"=="(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2))),
                    "assertPred!\"opAssign\" failed: lhs was assigned to\n[-2] instead of\n[2].");
    assertPred!"=="(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadAssign(5),
                                                              IntWrapper_BadAssign(2),
                                                              "It failed!")),
                    "assertPred!\"opAssign\" failed: lhs was assigned to\n[-2] instead of\n[2]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2))),
                    "assertPred!\"opAssign\" failed:\n[-2] (return value) !=\n[2] (assigned value).");
    assertPred!"=="(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadReturn(5),
                                                              IntWrapper_BadReturn(2),
                                                              "It failed!")),
                    "assertPred!\"opAssign\" failed:\n[-2] (return value) !=\n[2] (assigned value): It failed!");

    //Test default arguments.
    assertPred!"opAssign"(0, 12);
    assertPred!"opAssign"(0, 12, "msg");
    assertPred!"opAssign"(0, 12, "msg", "file");
    assertPred!"opAssign"(0, 12, "msg", "file", 42);
}));

mixin(unittestSemiTwistDLib("assertPred: opAssign: Examples", q{
	autoThrow = true;

    //Verify Examples
    assertPred!"opAssign"(std.datetime.SysTime(Date(1970, 1, 1)), std.datetime.SysTime(Date(2000, 12, 12)));

    struct IntWrapper_BadAssign
    {
        int value;

        IntWrapper_BadAssign opAssign(IntWrapper_BadAssign rhs)
        {
            this.value = -rhs.value;

            return IntWrapper_BadAssign(rhs.value);
        }

        string toString() { return to!string(value); }
    }

    assert(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2))) ==
           "assertPred!\"opAssign\" failed: lhs was assigned to\n" ~
           "[-2] instead of\n" ~
           "[2].");

    assert(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadAssign(5),
                                                     IntWrapper_BadAssign(2),
                                                     "It failed!")) ==
           "assertPred!\"opAssign\" failed: lhs was assigned to\n" ~
           "[-2] instead of\n" ~
           "[2]: It failed!");


    struct IntWrapper_BadReturn
    {
        int value;

        IntWrapper_BadReturn opAssign(IntWrapper_BadReturn rhs)
        {
            this.value = rhs.value;

            return IntWrapper_BadReturn(-rhs.value);
        }

        string toString() { return to!string(value); }
    }

    assert(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2))) ==
           "assertPred!\"opAssign\" failed:\n" ~
           "[-2] (return value) !=\n" ~
           "[2] (assigned value).");

    assert(collectExceptionMsg(assertPred!"opAssign"(IntWrapper_BadReturn(5),
                                                     IntWrapper_BadReturn(2),
                                                     "It failed!")) ==
           "assertPred!\"opAssign\" failed:\n" ~
           "[-2] (return value) !=\n" ~
           "[2] (assigned value): It failed!");
}));


void assertPred(string op, L, R, E)
               (L lhs, R rhs, E expected, lazy string msg = null, string file = __FILE__, size_t line = __LINE__)
    if((op == "+" ||
        op == "-" ||
        op == "*" ||
        op == "/" ||
        op == "%" ||
        op == "^^" ||
        op == "&" ||
        op == "|" ||
        op == "^" ||
        op == "<<" ||
        op == ">>" ||
        op == ">>>" ||
        op == "~") &&
       __traits(compiles, mixin("lhs " ~ op ~ " rhs")) &&
       __traits(compiles, mixin("(lhs " ~ op ~ " rhs) == expected")) &&
       isPrintable!L &&
       isPrintable!R)
{
    const result = mixin("lhs " ~ op ~ " rhs");

    if(result != expected)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertPred!\"%s\" failed: [%s] %s [%s]:\n[%s] (actual)\n[%s] (expected)%s",
                                               op,
                                               lhs,
                                               op,
                                               rhs,
                                               result,
                                               expected,
                                               tail),
                                         file,
                                         line)
		);
    }
}

mixin(unittestSemiTwistDLib("assertPred: Operators", q{
	autoThrow = true;

    assertNotThrown!AssertError(assertPred!"+"(7, 5, 12));
    assertNotThrown!AssertError(assertPred!"-"(7, 5, 2));
    assertNotThrown!AssertError(assertPred!"*"(7, 5, 35));
    assertNotThrown!AssertError(assertPred!"/"(7, 5, 1));
    assertNotThrown!AssertError(assertPred!"%"(7, 5, 2));
    assertNotThrown!AssertError(assertPred!"^^"(7, 5, 16_807));
    assertNotThrown!AssertError(assertPred!"&"(7, 5, 5));
    assertNotThrown!AssertError(assertPred!"|"(7, 5, 7));
    assertNotThrown!AssertError(assertPred!"^"(7, 5, 2));
    assertNotThrown!AssertError(assertPred!"<<"(7, 1, 14));
    assertNotThrown!AssertError(assertPred!">>"(7, 1, 3));
    assertNotThrown!AssertError(assertPred!">>>"(-7, 1, 2_147_483_644));
    assertNotThrown!AssertError(assertPred!"~"("hello ", "world", "hello world"));

    assertThrown!AssertError(assertPred!"+"(7, 5, 0));
    assertThrown!AssertError(assertPred!"-"(7, 5, 0));
    assertThrown!AssertError(assertPred!"*"(7, 5, 0));
    assertThrown!AssertError(assertPred!"/"(7, 5, 0));
    assertThrown!AssertError(assertPred!"%"(7, 5, 0));
    assertThrown!AssertError(assertPred!"^^"(7, 5, 0));
    assertThrown!AssertError(assertPred!"&"(7, 5, 0));
    assertThrown!AssertError(assertPred!"|"(7, 5, 0));
    assertThrown!AssertError(assertPred!"^"(7, 5, 0));
    assertThrown!AssertError(assertPred!"<<"(7, 1, 0));
    assertThrown!AssertError(assertPred!">>"(7, 1, 0));
    assertThrown!AssertError(assertPred!">>>"(-7, 1, 0));
    assertThrown!AssertError(assertPred!"~"("hello ", "world", "goodbye world"));

    assertPred!"=="(collectExceptionMsg(assertPred!"+"(7, 5, 11)),
                    "assertPred!\"+\" failed: [7] + [5]:\n[12] (actual)\n[11] (expected).");
    assertPred!"=="(collectExceptionMsg(assertPred!"+"(7, 5, 11, "It failed!")),
                    "assertPred!\"+\" failed: [7] + [5]:\n[12] (actual)\n[11] (expected): It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"^^"(7, 5, 42)),
                    "assertPred!\"^^\" failed: [7] ^^ [5]:\n[16807] (actual)\n[42] (expected).");
    assertPred!"=="(collectExceptionMsg(assertPred!"^^"(7, 5, 42, "It failed!")),
                    "assertPred!\"^^\" failed: [7] ^^ [5]:\n[16807] (actual)\n[42] (expected): It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"~"("hello ", "world", "goodbye world")),
                    "assertPred!\"~\" failed: [hello ] ~ [world]:\n[hello world] (actual)\n[goodbye world] (expected).");
    assertPred!"=="(collectExceptionMsg(assertPred!"~"("hello ", "world", "goodbye world", "It failed!")),
                    "assertPred!\"~\" failed: [hello ] ~ [world]:\n[hello world] (actual)\n[goodbye world] (expected): It failed!");

    //Verify Examples
    assertPred!"+"(7, 5, 12);
    assertPred!"-"(7, 5, 2);
    assertPred!"*"(7, 5, 35);
    assertPred!"/"(7, 5, 1);
    assertPred!"%"(7, 5, 2);
    assertPred!"^^"(7, 5, 16_807);
    assertPred!"&"(7, 5, 5);
    assertPred!"|"(7, 5, 7);
    assertPred!"^"(7, 5, 2);
    assertPred!"<<"(7, 1, 14);
    assertPred!">>"(7, 1, 3);
    assertPred!">>>"(-7, 1, 2_147_483_644);
    assertPred!"~"("hello ", "world", "hello world");

    assert(collectExceptionMsg(assertPred!"+"(7, 5, 11)) ==
           "assertPred!\"+\" failed: [7] + [5]:\n" ~
           "[12] (actual)\n" ~
           "[11] (expected).");

    assert(collectExceptionMsg(assertPred!"/"(11, 2, 6, "It failed!")) ==
           "assertPred!\"/\" failed: [11] / [2]:\n" ~
           "[5] (actual)\n" ~
           "[6] (expected): It failed!");

    //Test default arguments.
    assertPred!"+"(0, 12, 12);
    assertPred!"+"(0, 12, 12, "msg");
    assertPred!"+"(0, 12, 12, "msg", "file");
    assertPred!"+"(0, 12, 12, "msg", "file", 42);
}));


void assertPred(string op, L, R, E)
               (L lhs, R rhs, E expected, lazy string msg = null, string file = __FILE__, size_t line = __LINE__)
    if((op == "+=" ||
        op == "-=" ||
        op == "*=" ||
        op == "/=" ||
        op == "%=" ||
        op == "^^=" ||
        op == "&=" ||
        op == "|=" ||
        op == "^=" ||
        op == "<<=" ||
        op == ">>=" ||
        op == ">>>=" ||
        op == "~=") &&
       __traits(compiles, mixin("lhs " ~ op ~ " rhs")) &&
       __traits(compiles, mixin("(lhs " ~ op ~ " rhs) == expected")) &&
       isPrintable!L &&
       isPrintable!R)
{
    immutable origLHSStr = to!string(lhs);
    const result = mixin("lhs " ~ op ~ " rhs");

    if(lhs != expected)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertPred!\"%s\" failed: After [%s] %s [%s], lhs was assigned to\n[%s] instead of\n[%s]%s",
                                               op,
                                               origLHSStr,
                                               op,
                                               rhs,
                                               lhs,
                                               expected,
                                               tail),
                                         file,
                                         line)
		);
    }

    if(result != expected)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertPred!\"%s\" failed: Return value of [%s] %s [%s] was\n[%s] instead of\n[%s]%s",
                                               op,
                                               origLHSStr,
                                               op,
                                               rhs,
                                               result,
                                               expected,
                                               tail),
                                         file,
                                         line)
		);
    }
}

mixin(unittestSemiTwistDLib("assertPred: Assignment Operators", q{
	autoThrow = true;

    assertNotThrown!AssertError(assertPred!"+="(7, 5, 12));
    assertNotThrown!AssertError(assertPred!"-="(7, 5, 2));
    assertNotThrown!AssertError(assertPred!"*="(7, 5, 35));
    assertNotThrown!AssertError(assertPred!"/="(7, 5, 1));
    assertNotThrown!AssertError(assertPred!"%="(7, 5, 2));
    assertNotThrown!AssertError(assertPred!"^^="(7, 5, 16_807));
    assertNotThrown!AssertError(assertPred!"&="(7, 5, 5));
    assertNotThrown!AssertError(assertPred!"|="(7, 5, 7));
    assertNotThrown!AssertError(assertPred!"^="(7, 5, 2));
    assertNotThrown!AssertError(assertPred!"<<="(7, 1, 14));
    assertNotThrown!AssertError(assertPred!">>="(7, 1, 3));
    assertNotThrown!AssertError(assertPred!">>>="(-7, 1, 2_147_483_644));
    assertNotThrown!AssertError(assertPred!"~="("hello ", "world", "hello world"));

    assertThrown!AssertError(assertPred!"+="(7, 5, 0));
    assertThrown!AssertError(assertPred!"-="(7, 5, 0));
    assertThrown!AssertError(assertPred!"*="(7, 5, 0));
    assertThrown!AssertError(assertPred!"/="(7, 5, 0));
    assertThrown!AssertError(assertPred!"%="(7, 5, 0));
    assertThrown!AssertError(assertPred!"^^="(7, 5, 0));
    assertThrown!AssertError(assertPred!"&="(7, 5, 0));
    assertThrown!AssertError(assertPred!"|="(7, 5, 0));
    assertThrown!AssertError(assertPred!"^="(7, 5, 0));
    assertThrown!AssertError(assertPred!"<<="(7, 1, 0));
    assertThrown!AssertError(assertPred!">>="(7, 1, 0));
    assertThrown!AssertError(assertPred!">>>="(-7, 1, 0));
    assertThrown!AssertError(assertPred!"~="("hello ", "world", "goodbye world"));

    assertPred!"=="(collectExceptionMsg(assertPred!"+="(7, 5, 11)),
                    "assertPred!\"+=\" failed: After [7] += [5], lhs was assigned to\n[12] instead of\n[11].");
    assertPred!"=="(collectExceptionMsg(assertPred!"+="(7, 5, 11, "It failed!")),
                    "assertPred!\"+=\" failed: After [7] += [5], lhs was assigned to\n[12] instead of\n[11]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"^^="(7, 5, 42)),
                    "assertPred!\"^^=\" failed: After [7] ^^= [5], lhs was assigned to\n[16807] instead of\n[42].");
    assertPred!"=="(collectExceptionMsg(assertPred!"^^="(7, 5, 42, "It failed!")),
                    "assertPred!\"^^=\" failed: After [7] ^^= [5], lhs was assigned to\n[16807] instead of\n[42]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"~="("hello ", "world", "goodbye world")),
                    "assertPred!\"~=\" failed: After [hello ] ~= [world], lhs was assigned to\n[hello world] instead of\n[goodbye world].");
    assertPred!"=="(collectExceptionMsg(assertPred!"~="("hello ", "world", "goodbye world", "It failed!")),
                    "assertPred!\"~=\" failed: After [hello ] ~= [world], lhs was assigned to\n[hello world] instead of\n[goodbye world]: It failed!");

    struct IntWrapper
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        IntWrapper opOpAssign(string op)(IntWrapper rhs)
        {
            mixin("this.value " ~ op ~ "= rhs.value;");

            return this;
        }

        string toString()
        {
            return to!string(value);
        }
    }

    struct IntWrapper_BadAssign
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        IntWrapper_BadAssign opOpAssign(string op)(IntWrapper_BadAssign rhs)
        {
            auto old = this.value;

            mixin("this.value " ~ op ~ "= -rhs.value;");

            return IntWrapper_BadAssign(mixin("old " ~ op ~ " rhs.value"));
        }

        string toString()
        {
            return to!string(value);
        }
    }

    struct IntWrapper_BadReturn
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        IntWrapper_BadReturn opOpAssign(string op)(IntWrapper_BadReturn rhs)
        {
            mixin("this.value " ~ op ~ "= rhs.value;");

            return IntWrapper_BadReturn(rhs.value);
        }

        string toString()
        {
            return to!string(value);
        }
    }

    assertNotThrown!AssertError(assertPred!"+="(IntWrapper(5), IntWrapper(2), IntWrapper(7)));
    assertNotThrown!AssertError(assertPred!"*="(IntWrapper(5), IntWrapper(2), IntWrapper(10)));

    assertThrown!AssertError(assertPred!"+="(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2), IntWrapper_BadAssign(7)));
    assertThrown!AssertError(assertPred!"+="(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2), IntWrapper_BadReturn(7)));
    assertThrown!AssertError(assertPred!"*="(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2), IntWrapper_BadAssign(10)));
    assertThrown!AssertError(assertPred!"*="(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2), IntWrapper_BadReturn(10)));

    assertPred!"=="(collectExceptionMsg(assertPred!"+="(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2), IntWrapper_BadAssign(7))),
                    "assertPred!\"+=\" failed: After [5] += [2], lhs was assigned to\n[3] instead of\n[7].");
    assertPred!"=="(collectExceptionMsg(assertPred!"+="(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2), IntWrapper_BadAssign(7), "It failed!")),
                    "assertPred!\"+=\" failed: After [5] += [2], lhs was assigned to\n[3] instead of\n[7]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"+="(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2), IntWrapper_BadReturn(7))),
                    "assertPred!\"+=\" failed: Return value of [5] += [2] was\n[2] instead of\n[7].");
    assertPred!"=="(collectExceptionMsg(assertPred!"+="(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2), IntWrapper_BadReturn(7), "It failed!")),
                    "assertPred!\"+=\" failed: Return value of [5] += [2] was\n[2] instead of\n[7]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"*="(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2), IntWrapper_BadAssign(10))),
                    "assertPred!\"*=\" failed: After [5] *= [2], lhs was assigned to\n[-10] instead of\n[10].");
    assertPred!"=="(collectExceptionMsg(assertPred!"*="(IntWrapper_BadAssign(5), IntWrapper_BadAssign(2), IntWrapper_BadAssign(10), "It failed!")),
                    "assertPred!\"*=\" failed: After [5] *= [2], lhs was assigned to\n[-10] instead of\n[10]: It failed!");

    assertPred!"=="(collectExceptionMsg(assertPred!"*="(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2), IntWrapper_BadReturn(10))),
                    "assertPred!\"*=\" failed: Return value of [5] *= [2] was\n[2] instead of\n[10].");
    assertPred!"=="(collectExceptionMsg(assertPred!"*="(IntWrapper_BadReturn(5), IntWrapper_BadReturn(2), IntWrapper_BadReturn(10), "It failed!")),
                    "assertPred!\"*=\" failed: Return value of [5] *= [2] was\n[2] instead of\n[10]: It failed!");

    //Test default arguments.
    assertPred!"+="(0, 12, 12);
    assertPred!"+="(0, 12, 12, "msg");
    assertPred!"+="(0, 12, 12, "msg", "file");
    assertPred!"+="(0, 12, 12, "msg", "file", 42);
}));

mixin(unittestSemiTwistDLib("assertPred: Assignment Operators: Examples", q{
	autoThrow = true;

    //Verify Examples
    assertPred!"+="(5, 7, 12);
    assertPred!"-="(7, 5, 2);
    assertPred!"*="(7, 5, 35);
    assertPred!"/="(7, 5, 1);
    assertPred!"%="(7, 5, 2);
    assertPred!"^^="(7, 5, 16_807);
    assertPred!"&="(7, 5, 5);
    assertPred!"|="(7, 5, 7);
    assertPred!"^="(7, 5, 2);
    assertPred!"<<="(7, 1, 14);
    assertPred!">>="(7, 1, 3);
    assertPred!">>>="(-7, 1, 2_147_483_644);
    assertPred!"~="("hello ", "world", "hello world");

    struct IntWrapper_BadAssign
    {
        int value;

        IntWrapper_BadAssign opOpAssign(string op)(IntWrapper_BadAssign rhs)
        {
            auto old = this.value;

            mixin("this.value " ~ op ~ "= -rhs.value;");

            return IntWrapper_BadAssign(mixin("old " ~ op ~ " rhs.value"));
        }

        string toString() { return to!string(value); }
    }

    assert(collectExceptionMsg(assertPred!"+="(IntWrapper_BadAssign(5),
                                               IntWrapper_BadAssign(2),
                                               IntWrapper_BadAssign(7))) ==
           "assertPred!\"+=\" failed: After [5] += [2], lhs was assigned to\n" ~
           "[3] instead of\n" ~
           "[7].");

    assert(collectExceptionMsg(assertPred!"+="(IntWrapper_BadAssign(5),
                                               IntWrapper_BadAssign(2),
                                               IntWrapper_BadAssign(7),
                                               "It failed!")) ==
           "assertPred!\"+=\" failed: After [5] += [2], lhs was assigned to\n" ~
           "[3] instead of\n" ~
           "[7]: It failed!");

    struct IntWrapper_BadReturn
    {
        int value;

        IntWrapper_BadReturn opOpAssign(string op)(IntWrapper_BadReturn rhs)
        {
            mixin("this.value " ~ op ~ "= rhs.value;");

            return IntWrapper_BadReturn(rhs.value);
        }

        string toString() { return to!string(value); }
    }

    assert(collectExceptionMsg(assertPred!"+="(IntWrapper_BadReturn(5),
                                               IntWrapper_BadReturn(2),
                                               IntWrapper_BadReturn(7))) ==
           "assertPred!\"+=\" failed: Return value of [5] += [2] was\n" ~
           "[2] instead of\n" ~
           "[7].");

    assert(collectExceptionMsg(assertPred!"+="(IntWrapper_BadReturn(5),
                                               IntWrapper_BadReturn(2),
                                               IntWrapper_BadReturn(7),
                                               "It failed!")) ==
           "assertPred!\"+=\" failed: Return value of [5] += [2] was\n" ~
           "[2] instead of\n" ~
           "[7]: It failed!");
}));


void assertPred(string pred, string msg = null, string file = __FILE__, size_t line = __LINE__, T)
               (T a)
    if(__traits(compiles, unaryFun!pred(a)) &&
       is(typeof(unaryFun!pred(a)) : bool) &&
       isPrintable!T)
{
    if(!unaryFun!pred(a))
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format(`assertPred!"%s" failed: [%s] (a)%s`, pred, a, tail),
                                        file,
                                        line)
		);
    }
}

mixin(unittestSemiTwistDLib("assertPred: unaryFun", q{
	autoThrow = true;

    assertNotThrown!AssertError(assertPred!"a == 1"(1));
    assertNotThrown!AssertError(assertPred!"a"(true));
    assertNotThrown!AssertError(assertPred!"!a"(false));

    assertThrown!AssertError(assertPred!"a == 1"(2));
    assertThrown!AssertError(assertPred!"a"(false));
    assertThrown!AssertError(assertPred!"!a"(true));

    assertPred!"=="(collectExceptionMsg(assertPred!"a == 1"(2)),
                    `assertPred!"a == 1" failed: [2] (a).`);
    assertPred!"=="(collectExceptionMsg(assertPred!("a == 1", "It failed!")(2)),
                    `assertPred!"a == 1" failed: [2] (a): It failed!`);

    //Test default arguments.
    assertPred!"a == 7"(7);
    assertPred!("a == 7", "msg")(7);
    assertPred!("a == 7", "msg", "file")(7);
    assertPred!("a == 7", "msg", "file", 42)(7);

    //Verify Examples.
    assertPred!"a == 1"(1);

    assertPred!"a * 2.0 == 4.0"(2);

    assert(collectExceptionMsg(assertPred!"a == 1"(2)),
           `assertPred!"a == 1" failed: [2] (a).`);

    assert(collectExceptionMsg(assertPred!("a * 2.0 == 4.0", "Woe is me!")(7)),
           `assertPred!"a * 2.0 == 4.0" failed: [7] (a): Woe is me!`);
}));


void assertPred(string pred, string msg = null, string file = __FILE__, size_t line = __LINE__, T, U)
               (T a, U b)
    if(__traits(compiles, binaryFun!pred(a, b)) &&
       is(typeof(binaryFun!pred(a, b)) : bool) &&
       isPrintable!T)
{
    if(!binaryFun!pred(a, b))
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format(`assertPred!"%s" failed: [%s] (a), [%s] (b)%s`, pred, a, b, tail),
                                        file,
                                        line)
		);
    }
}

mixin(unittestSemiTwistDLib("assertPred: binaryFun", q{
	autoThrow = true;

    assertNotThrown!AssertError(assertPred!"a == b"(1, 1));
    assertNotThrown!AssertError(assertPred!"a * b == 2.0"(1, 2.0));

    assertThrown!AssertError(assertPred!"a == b"(1, 2));
    assertThrown!AssertError(assertPred!"a * b == 2.0"(2, 2.0));

    assertPred!"=="(collectExceptionMsg(assertPred!"a == b"(1, 2)),
                    `assertPred!"a == b" failed: [1] (a), [2] (b).`);
    assertPred!"=="(collectExceptionMsg(assertPred!("a == b", "It failed!")(1, 2)),
                    `assertPred!"a == b" failed: [1] (a), [2] (b): It failed!`);

    //Test default arguments.
    assertPred!"a == b"(7, 7);
    assertPred!("a == b", "msg")(7, 7);
    assertPred!("a == b", "msg", "file")(7, 7);
    assertPred!("a == b", "msg", "file", 42)(7, 7);

    //Verify Examples.
    assertPred!"a == b"(42, 42);

    assertPred!`a ~ b == "hello world"`("hello ", "world");

    assertPred!"=="(collectExceptionMsg(assertPred!"a == b"(1, 2)),
                    `assertPred!"a == b" failed: [1] (a), [2] (b).`);

    assertPred!"=="(collectExceptionMsg(assertPred!("a * b == 7", "It failed!")(2, 3)),
                    `assertPred!"a * b == 7" failed: [2] (a), [3] (b): It failed!`);
}));


void assertPred(alias pred, string msg = null, string file = __FILE__, size_t line = __LINE__, T...)
               (T args)
    if(isCallable!pred &&
       is(ReturnType!pred == bool) &&
       __traits(compiles, pred(args)) &&
       isPrintable!T)
{
    immutable result = pred(args);

    if(!result)
    {
        string argsStr;

        if(args.length > 0)
        {
            foreach(value; args)
                argsStr ~= format("[%s], ", to!string(value));

            argsStr.popBackN(", ".length);
        }
        else
            argsStr = "none";

        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertPred failed: arguments: %s%s", argsStr, tail), file, line) );
    }
}

mixin(unittestSemiTwistDLib("assertPred: Delegates", q{
	autoThrow = true;

    assertNotThrown!AssertError(assertPred!({return true;})());
    assertNotThrown!AssertError(assertPred!((bool a){return a;})(true));
    assertNotThrown!AssertError(assertPred!((int a, int b){return a == b;})(5, 5));
    assertNotThrown!AssertError(assertPred!((int a, int b, int c){return a == b && b == c;})(5, 5, 5));
    assertNotThrown!AssertError(assertPred!((int a, int b, int c, float d){return a * b < c * d;})(2, 4, 5, 1.7));

    assertThrown!AssertError(assertPred!({return false;})());
    assertThrown!AssertError(assertPred!((bool a){return a;})(false));
    assertThrown!AssertError(assertPred!((int a, int b){return a == b;})(5, 6));
    assertThrown!AssertError(assertPred!((int a, int b, int c){return a == b && b == c;})(5, 5, 6));
    assertThrown!AssertError(assertPred!((int a, int b, int c, float d){return a * b < c * d;})(3, 4, 5, 1.7));

    //Test default arguments.
    assertPred!((int a, int b){return a == b;})(7, 7);
    assertPred!((int a, int b){return a == b;}, "msg")(7, 7);
    assertPred!((int a, int b){return a == b;}, "msg", "file")(7, 7);
    assertPred!((int a, int b){return a == b;}, "msg", "file", 42)(7, 7);

    //Verify Examples.
    assertPred!((int[] range, int i){return canFind(range, i);})([1, 5, 7, 2], 7);

    assertPred!((int a, int b, int c){return a == b && b == c;})(5, 5, 5);

    assert(collectExceptionMsg(assertPred!((int a, int b, int c, float d){return a * b < c * d;})
                                           (22, 4, 5, 1.7)) ==
           "assertPred failed: arguments: [22], [4], [5], [1.7].");

    assert(collectExceptionMsg(assertPred!((string[] s...){return canFind(s, "hello");}, "Failure!")
                                          ("goodbye", "old", "friend")) ==
           "assertPred failed: arguments: [goodbye], [old], [friend]: Failure!");
}));

//==============================================================================
// Private Section.
//
// Note: assertNotThrown, assertThrown and collectExceptionMsg are included in
// this module because they're used by assertPred's unittests and haven't been
// added to Phobos just yet. But they're private becuase they're going to be
// in Phobos soon.
//==============================================================================
private:

void assertNotThrown(T : Throwable = Exception, F)
                    (lazy F funcToCall, string msg = null, string file = __FILE__, size_t line = __LINE__)
{
    try
        funcToCall();
    catch(T t)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertNotThrown failed: %s was thrown%s", T.stringof, tail), file, line, t) );
    }
}

mixin(unittestSemiTwistDLib("private assertNotThrown", q{
	autoThrow = true;
	
    void throwEx(Throwable t)
    {
        throw t;
    }

    void nothrowEx()
    {
    }

    try
        assertNotThrown!Exception(nothrowEx());
    catch(AssertError)
        assert(0);

    try
        assertNotThrown!Exception(nothrowEx(), "It's a message");
    catch(AssertError)
        assert(0);

    try
        assertNotThrown!AssertError(nothrowEx());
    catch(AssertError)
        assert(0);

    try
        assertNotThrown!AssertError(nothrowEx(), "It's a message");
    catch(AssertError)
        assert(0);


    {
        bool thrown = false;
        try
            assertNotThrown!Exception(throwEx(new Exception("It's an Exception")));
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            assertNotThrown!Exception(throwEx(new Exception("It's an Exception")), "It's a message");
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            assertNotThrown!AssertError(throwEx(new AssertError("It's an AssertError", __FILE__, __LINE__)));
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            assertNotThrown!AssertError(throwEx(new AssertError("It's an AssertError", __FILE__, __LINE__)), "It's a message");
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    //Verify Examples.
    assertNotThrown!DateTimeException(std.datetime.TimeOfDay(0, 0, 0));
    assertNotThrown!DateTimeException(std.datetime.TimeOfDay(12, 30, 27));
    assertNotThrown(std.datetime.TimeOfDay(23, 59, 59));  //Exception is default.

    assert(collectExceptionMsg(assertNotThrown!TimeException(std.datetime.TimeOfDay(12, 0, 60))) ==
           "assertNotThrown failed: TimeException was thrown.");

    assert(collectExceptionMsg(assertNotThrown!TimeException(std.datetime.TimeOfDay(25, 0, 0), "error!")) ==
           "assertNotThrown failed: TimeException was thrown: error!");
}));


void assertThrown(T : Throwable = Exception, F)
                 (lazy F funcToCall, string msg = null, string file = __FILE__, size_t line = __LINE__)
{
    bool thrown = false;

    try
        funcToCall();
    catch(T t)
        thrown = true;

    if(!thrown)
    {
        immutable tail = msg.empty ? "." : ": " ~ msg;

        throwException( new AssertError(format("assertThrown failed: No %s was thrown%s", T.stringof, tail), file, line) );
    }
}

mixin(unittestSemiTwistDLib("private assertThrown", q{
	autoThrow = true;
	
    void throwEx(Throwable t)
    {
        throw t;
    }

    void nothrowEx()
    {
    }

    try
        assertThrown!Exception(throwEx(new Exception("It's an Exception")));
    catch(AssertError)
        assert(0);

    try
        assertThrown!Exception(throwEx(new Exception("It's an Exception")), "It's a message");
    catch(AssertError)
        assert(0);

    try
        assertThrown!AssertError(throwEx(new AssertError("It's an AssertError", __FILE__, __LINE__)));
    catch(AssertError)
        assert(0);

    try
        assertThrown!AssertError(throwEx(new AssertError("It's an AssertError", __FILE__, __LINE__)), "It's a message");
    catch(AssertError)
        assert(0);


    {
        bool thrown = false;
        try
            assertThrown!Exception(nothrowEx());
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            assertThrown!Exception(nothrowEx(), "It's a message");
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            assertThrown!AssertError(nothrowEx());
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            assertThrown!AssertError(nothrowEx(), "It's a message");
        catch(AssertError)
            thrown = true;

        assert(thrown);
    }

    //Verify Examples.
    assertThrown!DateTimeException(std.datetime.TimeOfDay(-1, 15, 30));
    assertThrown!DateTimeException(std.datetime.TimeOfDay(12, 60, 30));
    assertThrown(std.datetime.TimeOfDay(12, 15, 60));  //Exception is default.


    assert(collectExceptionMsg(assertThrown!AssertError(std.datetime.TimeOfDay(12, 0, 0))) ==
           "assertThrown failed: No AssertError was thrown.");

    assert(collectExceptionMsg(assertThrown!AssertError(std.datetime.TimeOfDay(12, 0, 0), "error!")) ==
           "assertThrown failed: No AssertError was thrown: error!");
}));


string collectExceptionMsg(T)(lazy T funcCall)
{
    try
    {
        funcCall();

        return cast(string)null;
    }
    catch(Throwable t)
        return t.msg;
}

mixin(unittestSemiTwistDLib("private collectExceptionMsg", q{
	autoThrow = true;

    //Verify Example.
    void throwFunc() {throw new Exception("My Message.");}
    assert(collectExceptionMsg(throwFunc()) == "My Message.");

    void nothrowFunc() {}
    assert(collectExceptionMsg(nothrowFunc()) is null);
}));


/+
    Whether the given type can be converted to a string.
  +/
template isPrintable(T...)
{
    static if(T.length == 0)
        enum isPrintable = true;
    else static if(T.length == 1)
    {
        enum isPrintable = (!isArray!(T[0]) && __traits(compiles, to!string(T[0].init))) ||
                           (isArray!(T[0]) && __traits(compiles, to!string(T[0].init[0])));
    }
    else
    {
        enum isPrintable = isPrintable!(T[0]) && isPrintable!(T[1 .. $]);
    }
}
