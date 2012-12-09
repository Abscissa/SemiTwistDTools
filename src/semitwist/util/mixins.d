// SemiTwist Library
// Written in the D programming language.

module semitwist.util.mixins;

import std.traits;
import std.stdio;
import std.conv;

import semitwist.util.all;

/++
Useful in constructors for DRY.

Usage:
----
mixin(initMember("someVar"));
mixin(initMember("a", "b", "c"));
----

Turns Into:
----
this.someVar = someVar;
this.a = a;
this.b = b;
this.c = c;
----
+/
string initMember(string[] vars...)
{
	return initMemberX("this.%s = %s", vars);
}

/++
Generic version of initMember.

Usage:
----
mixin(initMemberX("foo1.%s = foo2.%s", "someVar"));
mixin(initMemberX("this._%s = foo.%s", "a", "b", "c"));
----

Turns Into:
----
foo1.someVar = foo2.someVar;
this._a = foo.a;
this._b = foo.b;
this._c = foo.c;
----
+/
string initMemberX(string str, string[] vars...)
{
	//enum string initMemberX = ctfe_subMapJoin!string(str~";\n", "%s", /+templateArgsToStrings!(+/vars/+)+/);
	return ctfe_subMapJoin!string(str~";\n", "%s", vars);
}

/++
Useful in copy constructors for DRY.

Usage:
----
class myClass
{
	// Declarations of 'someVar', 'a1', 'b', and 'c' here.
	this(myClass copyOf)
	{
		mixin(initMemberFrom("copyOf", "someVar"));
		mixin(initMemberFrom("copyOf", "a1", "b", "c"));
	}
}
----

Turns Into:
----
class myClass
{
	// Declarations of 'someVar', 'a1', 'b', and 'c' here.
	this(myClass copyOf)
	{
		this.someVar = copyOf.someVar;
		this.a1 = copyOf.a1;
		this.b = copyOf.b;
		this.c = copyOf.c;
	}
}
----
+/
string initMemberFrom(string from, string[] vars...)
{
	return initMemberX("this.%s = "~from~".%s", vars);
}

string initMemberTo(string to, string[] vars...)
{
	return initMemberX(to~".%s = %s", vars);
}

string initFrom(string from, string[] vars...)
{
	return initMemberX("%s = "~from~".%s", vars);
}

/++
A DRY way to display an expression and its value to Stdout.

Usage:

----
int myVar=100;
mixin(traceVal!("myVar"));
mixin(traceVal!("   myVar-1 "));
mixin(traceVal!("min(4,7)", "max(4,7)")); // from tango.math.Math
----

Turns Into:

----
int myVar=100;
writefln("%s: %s", "myVar", myVar);
writefln("%s: %s", "   myVar-1 ",   myVar-1 );
writefln("%s: %s", "min(4,7)", min(4,7));
writefln("%s: %s", "max(4,7)", max(4,7));
----

Outputs:

----
myVar: 100
   myVar-1 : 99
min(4,7): 4
max(4,7): 7
----
+/

//TODO: Add ability to specify format (binary, hex, etc)
//TODO: Make nameLength work by using format (at runtime)
//      on data passed to writefln
//      (ie, align name/value)
//TODO: Messes up on "ctfe_repeat_test_日本語3"
template traceVal(values...)
{
	enum traceVal = traceVal!(false, values);
}

template traceVal(bool useNewline, values...)
{
	static if(values.length == 0)
		enum traceVal = "";
	else
	{
		enum traceVal =
			"writefln(\"%s:"~(useNewline?"\\n":" ")~"%s\", "~values[0].stringof~", "~unescapeDDQS(values[0].stringof)~");"
			~ traceVal!(useNewline, values[1..$]);
	}
}

/++
Easy way to output file/line for debugging.

Usage:

----
trace();
someFunc();
trace("Blah blah blah");
int x = *(cast(int*)null); // Dereference null
trace();
----

Example Output:

----
C:\path\file.d(1): trace
C:\path\file.d(3): Blah blah blah
{segfault!}
----
+/

void trace(string file=__FILE__, size_t line=__LINE__)(string msg="trace")
{
	writefln("%s(%s): %s", file, line, msg);
	stdout.flush();
}

/++
Wraps a string mixin and displays the string at compile-time. Useful for debugging.

Usage:

----
template defineFloat(string name)
{ enum defineFloat = "float "~name~";"; }
string defineInt(string name, string value)
{ return "int "~name~"="~value";"; }

mixin(traceMixin!("defineFloat!", `"myFloat"`));
mixin(traceMixin!("defineInt!", `"myInt", 5`));
----

Turns Into:

----
template defineFloat(string name)
{ enum defineFloat = "float "~name~";"; }
string defineInt(string name, string value)
{ return "int "~name~"="~value";"; }

float myFloat;
pragma(msg, "defineFloat:\n float myFloat;");
int myInt=5;
pragma(msg, "defineInt:\n int myInt=5;");
----

Compiler Output:

----
defineFloat:
float myFloat;
defineInt:
int myInt=5;
----
+/

template traceMixin(string name, string args)
{
	enum traceMixin = 
		`pragma(msg, "` ~ name ~ `: \n"~`~name~`(`~args~`));`~"\n"~
		"mixin("~name~"("~args~"));\n";
}

/++
Compile-time version of traceVal.

Only works for string values right now.

Usage:

----
enum fooStr = "Hi";
enum fooStr2 = "Hi2";
mixin(traceValCT!("fooStr", "fooStr2"));
mixin(traceValCT!(`fooStr~" Joe"`));

template fooTmpl
{
	enum fooTempl = "Hello World";
	mixin(traceValCT!(true, "fooTempl"));
}
----

Turns Into:

----
enum fooStr = "Hi";
enum fooStr2 = "Hi2";
pragma(msg, "fooStr: " ~ (fooStr));
pragma(msg, "fooStr2: " ~ (fooStr2));
pragma(msg, "fooStr~\" Joe\""~": " ~ (fooStr~" Joe"));

template fooTmpl
{
	enum fooTempl = "Hello World";
	pragma(msg, "fooTempl:\n" ~ (fooTempl));
}
----

Compiler Output:

----
fooStr: Hi
fooStr2: Hi2
fooStr~" Joe": Hi Joe
fooTempl:
Hello World
----
+/

template traceValCT(values...)
{
	enum traceValCT = traceValCT!(false, values);
}

template traceValCT(bool useNewline, values...)
{
	static if(values.length == 0)
	{
		enum traceValCT = "";
	}
	else
	{
		enum traceValCT =
			"pragma(msg, "~escapeDDQS(values[0])~"~\":"~(useNewline? "\\n":" ")~"\" ~ ("~values[0]~"));\n"~
			traceValCT!(useNewline, values[1..$]);

		//pragma(msg, "traceValCT: " ~ traceValCT);
	}
}

/// Part of a workaround for DMD Issues #5029 and #5030
string fixAATypeName(string str)
{
	enum prefix = "AssociativeArray!(";
	if(str.length > prefix.length && str[0..prefix.length] == prefix)
	{
		auto strippedStr = str[prefix.length..$-1];
		int nestLevel=0;
		size_t i;
		bool done=false;
		for(i=0; !done && i < strippedStr.length; i++)
		{
			switch(strippedStr[i])
			{
			case '(': nestLevel++; break;
			case ')': nestLevel--; break;
			case ',':
				if(nestLevel==0)
					done=true;
				break;
			default: break;
			}
		}
		i--;
		auto typeKey = strippedStr[0..i];
		auto typeVal = strippedStr[i+1..$];
		
		return typeVal~"["~typeKey~"]";
	}
	else
		return str;
}

/++
Useful in class/struct declarations for DRY.

Generates a public getter, private setter, and a hidden private var.

Usage:

----
mixin(getter!(int, "myVar"));
mixin(getter!("protected", float, "someFloat", 2.5));
mixin(getter!(string, "str"));
----

Turns Into:

----
private int _myVar;
@property private int myVar(int _NEW_VAL_)
{
	_myVar = _NEW_VAL_;
	return _myVar;
}
@property public int myVar()
{
	return _myVar;
}

protected float _someFloat = 2.5;
@property protected float someFloat(float _NEW_VAL_)
{
	_someFloat = _NEW_VAL_;
	return _someFloat;
}
@property public float someFloat()
{
	return _someFloat;
}

private string _str;
@property private string str(string _NEW_VAL_)
{
	_str = _NEW_VAL_;
	return _str;
}
@property public string str()
{
	return _str;
}
----
+/
template getter(varType, string name, varType initialValue=varType.init)
{
	static if(is(varType.init))
		enum getter = getter!("private", varType, name, initialValue);
	else
		enum getter = getter!("private", varType, name);
}

template getter(string writeAccess, varType, string name, varType initialValue=varType.init)
{
	static if(is(varType.init))
	{
		enum getter =
			writeAccess~" "~fixAATypeName(varType.stringof)~" _"~name~(initialValue.stringof == varType.init.stringof ? "" : "=" ~ initialValue.stringof)~";\n"~
			"@property "~writeAccess~" "~fixAATypeName(varType.stringof)~" "~name~"("~fixAATypeName(varType.stringof)~" _NEW_VAL_) {_"~name~"=_NEW_VAL_;return _"~name~";}\n"~
			"@property public "~fixAATypeName(varType.stringof)~" "~name~"() {return _"~name~";}\n";
	}
	else
	{
		enum getter =
			writeAccess~" "~fixAATypeName(varType.stringof)~" _"~name~";\n"~
			"@property "~writeAccess~" "~fixAATypeName(varType.stringof)~" "~name~"("~fixAATypeName(varType.stringof)~" _NEW_VAL_) {_"~name~"=_NEW_VAL_;return _"~name~";}\n"~
			"@property public "~fixAATypeName(varType.stringof)~" "~name~"() {return _"~name~";}\n";
	}
}

/++
Similar to "getter", but for values that are to be lazily generated and cached.
This is useful for values that are complex to generate, not always used, and
either never or infrequently change.

The first time the getter is called, the generator function you have provided
is run, and it's return value is cached and returned. On subsequent calls to
the getter, the cached value is returned without the generator function being
called. The cache can be cleared, thus forcing the value to be re-generated
upon the next getter call, by setting "_myVarName_cached" to false.

Example use-case: If you have a property created by getter() and want
to change the "get" from a trivial "return _blah" to a more involved function, 
you will most likely just simply switch from getter to getterLazy.

Additional Info:

If you don't want the value to ever be cached, just set "_myVarName_cached"
to false within your provided generator function.

Usage:

----
mixin(getterLazy!(int, "myVar", `
	// Ordinarily, this function would be more complex
	return 7;
`));

mixin(getterLazy!("protected", int, "myVar2", `return 7;`));

mixin(getterLazy!(string, "str"));
private string _str_gen()
{
	return "Hello";
}
----

Turns Into:

----
private int _myVar;
private bool _myVar_cached = false;
@property public int myVar() {
	if(!_myVar_cached) {
		_myVar_cached = true;
		_myVar = _myVar_gen();
	}
	return _myVar;
}
private int _myVar_gen()
{
	// Ordinarily, this function would be more complex
	return 7;
}

protected int _myVar2;
protected bool _myVar2_cached = false;
@property public int myVar2() {
	if(!_myVar2_cached) {
		_myVar2_cached = true;
		_myVar2 = _myVar2_gen();
	}
	return _myVar2;
}
protected int _myVar2_gen()
{
	return 7;
}

private string _str;
private bool _str_cached = false;
@property public string str() {
	if(!_str_cached) {
		_str_cached = true;
		_str = customGenFunc();
	}
	return _str;
}
private string customGenFunc()
{
	return "Hello";
}

----
+/
//TODO? Merge with getter if reasonably possible
template getterLazy(varType, string name, string genFunc="")
{
	enum getterLazy = getterLazy!("private", varType, name, genFunc);
}

template getterLazy(string writeAccess, varType, string name, string genFunc="")
{
	enum getterLazy =
		"\n"~
		((genFunc=="")?
			"static if(!is(typeof(_"~name~"_gen)==function))\n"~
			`	static assert(false, "'getterLazy!(`~fixAATypeName(varType.stringof)~`, \"`~name~`\")' requires function '`~fixAATypeName(varType.stringof)~` _`~name~`_gen()' to be defined");`~"\n"

			// Blocked by DMD Bug #2885
			//"static if(!is(ReturnTypeOf!(_"~name~"_gen):"~varType.stringof~"))\n"~
			//`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires function '_`~name~`_gen' to return type '`~varType.stringof~`' (or a compatible type), not type '"~ReturnTypeOf!(_`~name~`_gen).stringof~"'");`~"\n"~

			// Forward reference issues prevent this too
			//"static if(!ParameterTupleOf!(_line_gen).length==0)\n"~
			//`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires an overload of function '_`~name~`_gen' that takes no arguments");`~"\n"~
		:"")~

		writeAccess~" "~varType.stringof~" _"~name~";\n"~
		writeAccess~" bool _"~name~"_cached = false;\n"~
		"@property public "~varType.stringof~" "~name~"() {\n"~
		"	if(!_"~name~"_cached) {\n"~
		"		_"~name~"_cached = true;\n"~
		"		_"~name~" = _"~name~"_gen();\n"~
		"	}\n"~
		"	return _"~name~";\n"~
		"}\n"~
		((genFunc=="")?"":
			writeAccess~" "~varType.stringof~" _"~name~"_gen()\n"~
			"{\n"~
			genFunc~
			"}\n"
		);
}

/++
OBSOLETE IN D2

Inserts a compile-time check that ensures a given type is a character type.
(ie, char, wchar, or dchar)

Usage:

----
void funcForStringsOnly(T)(T[] str)
{
	//Note, the second param is optional
	mixin(ensureCharType!("T", "funcForStringsOnly"));
	//Do stuff
	return str;
}
funcForStringsOnly("hello"); // Ok
funcForStringsOnly([cast(int)1,2,3]); // Compile error
----

Turns Into:

----
void funcForStringsOnly(T)(T[] str)
{
	static assert(
		is(T==char) || is(T==wchar) || is(T==dchar),
		"From 'funcForStringsOnly': 'T' must be char, wchar or dchar, not '"~T.stringof~"'"
	);`;
	//Do stuff
	return str;
}
funcForStringsOnly("hello"); // Ok
funcForStringsOnly([cast(int)1,2,3]); // Compile error
----

Compiler Output:

----
Error: static assert  "From 'funcForStringsOnly': 'T' must be char, wchar or dchar, not 'int'"
----
+/

/+template ensureCharType(string nameOfT, string nameOfCaller="")
{
	enum ensureCharType = 
		`static assert(`~"\n"~
		`	is(`~nameOfT~`==char) || is(`~nameOfT~`==wchar) || is(`~nameOfT~`==dchar),`~"\n"~
		`	"`~(nameOfCaller==""?"":"From '"~nameOfCaller~"': ")~`'`~nameOfT~`' must be char, wchar or dchar, not '"~`~nameOfT~`.stringof~"'"`~"\n"~
		`);`;
}+/

//TODO: Document genEnum
public string genEnum(string name, string[] values)
{
	return
		"enum "~name~" {"~values.ctfe_join(", ")~"}\n"~
		"enum uint "~name~"_length = "~to!string(values.length)~";\n"~
		_genEnumToString(name, values)~
		_genStringToEnum(name, values);
}

// The function this generates could probably be improved.
public string _genEnumToString(string enumName, string[] enumValues)
{
	string ret = "";
	
	foreach(string enumValue; enumValues)
		ret ~= "    if(value=="~enumName~"."~enumValue~") return \""~enumValue~"\";\n";
	
	ret =
		"string enum"~enumName~"ToString("~enumName~" value)\n"~
		"{\n"~
		ret~
		`    throw new Exception("Internal Error: Unhandled value in enum`~enumName~`ToString");`~"\n"~
		"}\n";
	
	return ret;
}

// The function this generates could probably be improved.
public string _genStringToEnum(string enumName, string[] enumValues)
{
	string ret = "";
	
	foreach(string enumValue; enumValues)
		ret ~= "    if(value==\""~enumValue~"\") return "~enumName~"."~enumValue~";\n";
	
	ret =
		enumName~" stringToEnum"~enumName~"(string value)\n"~
		"{\n"~
		ret~
		`    throw new Exception("'"~value~"' is not a valid value for '`~enumName~`'");`~"\n"~
		"}\n";
	
	return ret;
}

/++
Use verboseSection to display a message, flush it to the screen, and once the
scope is over, display how much time the scope took to run. Message and timing
info is only displayed when verbosity is enabled. Condition for "Is verbosity
enabled?" can be customized with setVerboseSectionCond.

Usage:

----
bool verbose;

void foo()
{
	mixin(verboseSection!"Running foo");
	[...code here...]
}

void bar()
{
	{
		mixin(verboseSection!"Running bar stage 1");
		[...code here...]
	}

	{
		auto msg = "Running bar stage "~to!string(2);
		mixin(verboseSection!msg);
		[...code here...]
	}
}

void main()
{
	verbose = false;
	writeln("Verbose off");
	foo();
	bar();

	verbose = true;
	writeln("Verbose on");
	foo();
	bar();
}
----

Output:

----
Verbose off
Verbose on
Running foo...261ms
Running bar stage 1...7ms
Running bar stage 2...3528ms
----

You can change the conditional expression to something other than the default
of "verbose" by using setVerboseSectionCond:

Usage:

----
struct Options
{
	bool verbose;
}
Options options;
mixin(setVerboseSectionCond!"options.verbose");

// Or:

int verbosityLevel;
mixin(setVerboseSectionCond!"verbosityLevel > 2");
----

Using setVerboseSectionCond only affects the current module.
Use it again in each module desired.
+/
template setVerboseSectionCond(string cond="verbose")
{
	immutable setVerboseSectionCond = `
		private template verboseSection(alias msg)
		{
			enum verboseSection = verboseSectionEx!(`~cond.stringof~`, msg);
		}
	`;
}

// The default
///ditto
template verboseSection(alias msg)
{
	enum verboseSection = verboseSectionEx!("verbose", msg);
}

public import std.datetime : _semitwist_util_mixins_StopWatchType = StopWatch;
public import std.stdio :
	_semitwist_util_mixins_write = write,
	_semitwist_util_mixins_writeln = writeln,
	_semitwist_util_mixins_stdout = stdout;

template verboseSectionEx(string verboseExpr, alias msg)
{
	immutable verboseSectionEx = `
		_semitwist_util_mixins_StopWatchType _semitwist_util_mixins_stopWatch;
		if(`~verboseExpr~`)
		{
			_semitwist_util_mixins_write(`~msg.stringof~` ~ "...");
			_semitwist_util_mixins_stdout.flush();
			_semitwist_util_mixins_stopWatch.start();
		}
		scope(exit) if(`~verboseExpr~`)
		{
			_semitwist_util_mixins_writeln(_semitwist_util_mixins_stopWatch.peek.msecs, "ms");
			_semitwist_util_mixins_stdout.flush();
		}
	`;
}
