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

//TODO: This module needs an overhall. Particularly with phobos's
//      new assert-related routines such as assertPred (hopefully) coming.

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
	const string deferEnsure =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ const long _deferAssert_line = __LINE__;\n"~
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
	const string deferEnsureThrows =
	// The "_deferAssert_line" is a workaround for DMD Bug #2887
	"{ const long _deferAssert_line = __LINE__;\n"~
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
string unittestSection(string debugIdent)(string sectionName, string unittestBody=null)
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
	
	return q{
		debug(_semitwist_unittestSection_debugIdent_)
		{
			unittest
			{
				int _unittestSection_dummy_;
				auto _unittestSection_moduleName_ =
					unittestSection_demangle( qualifiedName!_unittestSection_dummy_() )
						[
							"void ".length ..
							ctfe_find(unittestSection_demangle( qualifiedName!_unittestSection_dummy_() ), ".__unittest")
						];

				writeUnittestSection(
					_unittestSection_moduleName_ ~
					_semitwist_unittestSection_sectionName_
				);
				_semitwist_unittestSection_unittestBody_
			}
		}
	}
	.ctfe_substitute("\n", " ")
	.ctfe_substitute("\r", "")
	.ctfe_substitute("_semitwist_unittestSection_debugIdent_", debugIdent)
	.ctfe_substitute("_semitwist_unittestSection_sectionName_", sectionName)
	.ctfe_substitute("_semitwist_unittestSection_unittestBody_", unittestBody);
}
alias mangledName unittestSection_mangledName;
alias demangle unittestSection_demangle;

void writeUnittestSection(string sectionName)
{
	writeln("== unittest: ", sectionName);
}

alias unittestSection!"SemiTwistDLib_unittest" unittestSemiTwistDLib;
