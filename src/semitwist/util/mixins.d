// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.mixins;

import tango.core.Traits;
import tango.io.Stdout;

import semitwist.util.reflect;
import semitwist.util.text;

/**
Useful in constructors for DRY.

Usage:
----
mixin(initMember!(someVar));
mixin(initMember!(a, b, c));
----

Turns Into:
----
this.someVar = someVar;
this.a = a;
this.b = b;
this.c = c;
----
*/
template initMember(variables...)
{
	const char[] initMember = _initMemberFrom!("", variables);
	//pragma(msg, "initMember: " ~ initMember);
}

/**
Useful in copy constructors for DRY.

Usage:
----
class myClass
{
	// Declarations of 'someVar', 'a1', 'b', and 'c' here.
	this(myClass copyOf)
	{
		mixin(initMemberFrom!(copyOf, someVar));
		mixin(initMemberFrom!(copyOf, a1, b, c));
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
*/
template initMemberFrom(alias from, variables...)
{
	const char[] initMemberFrom = _initMemberFrom!(from.stringof ~ ".", variables);
//	pragma(msg, "initMemberFrom: " ~ initMemberFrom);
}

private template _initMemberFrom(char[] from, variables...)
{
	static if(variables.length == 0)
		const char[] _initMemberFrom = "";
	else
	{
		const char[] _initMemberFrom =
			"this."~variables[0].stringof~" = "~from~variables[0].stringof~";\n"
			~ _initMemberFrom!(from, variables[1..$]);
//		pragma(msg, "_initMemberFrom:\n" ~ _initMemberFrom);
	}
}

template initMemberTo(alias to, variables...)
{
	const char[] initMemberTo = _initMemberTo!(to.stringof ~ ".", variables);
//	pragma(msg, "initMemberTo: " ~ initMemberTo);
}

private template _initMemberTo(char[] to, variables...)
{
	static if(variables.length == 0)
		const char[] _initMemberTo = "";
	else
	{
		const char[] _initMemberTo =
			to~variables[0].stringof~" = "~variables[0].stringof~";\n"
			~ _initMemberTo!(to, variables[1..$]);
//		pragma(msg, "_initMemberTo:\n" ~ _initMemberTo);
	}
}

template initFrom(alias from, variables...)
{
	const char[] initFrom = _initFrom!(from.stringof ~ ".", variables);
//	pragma(msg, "initFrom: " ~ initFrom);
}

private template _initFrom(char[] from, variables...)
{
	static if(variables.length == 0)
		const char[] _initFrom = "";
	else
	{
		const char[] _initFrom =
			variables[0].stringof~" = "~from~variables[0].stringof~";\n"
			~ _initFrom!(from, variables[1..$]);
//		pragma(msg, "_initFrom:\n" ~ _initFrom);
	}
}
/**
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
Stdout.formatln("{}: {}", "myVar", myVar);
Stdout.formatln("{}: {}", "   myVar-1 ",   myVar-1 );
Stdout.formatln("{}: {}", "min(4,7)", min(4,7));
Stdout.formatln("{}: {}", "max(4,7)", max(4,7));
----

Outputs:

----
myVar: 100
   myVar-1 : 99
min(4,7): 4
max(4,7): 7
----
*/

//TODO: Add ability to specify format (binary, hex, etc)
//TODO: Make nameLength work by using Layout.format (at runtime)
//      on data passed to Stdout.formatln
//      (ie, align name/value)
/// 'values' should be strings
template traceVal(values...)
{
	static if(values.length == 0)
		const char[] traceVal = "";
	else
	{
		const char[] traceVal =
			"Stdout.formatln(\"{}: {}\", "~values[0].stringof~", "~unescape(values[0].stringof, EscapeSequence.DoubleQuoteString)~");"
			~ traceVal!(values[1..$]);
		//pragma(msg, "traceVal: "~traceVal);
	}
}

/**
Easy way to output file/line. Useful for debugging.

Usage:

----
mixin(trace!());
funcSuspectedOfCrashing()
mixin(trace!("--EASY TO VISUALLY GREP--"));
theRealCauseOfCrash()
mixin(trace!());
----

Turns Into:

----
Stdout.formatln("{}({}): trace", __FILE__, __LINE__);
funcSuspectedOfCrashing()
Stdout.formatln("{}{}({}): trace", "--EASY TO VISUALLY GREP--", __FILE__, __LINE__);
theRealCauseOfCrash()
Stdout.formatln("{}({}): trace", __FILE__, __LINE__);
----

Example Output:

----
C:\path\file.d(1): trace
--EASY TO VISUALLY GREP--: C:\path\file.d(3): trace
{segfault!}
----
*/
template trace(char[] prefix="")
{
	static if(prefix=="")
		const char[] trace =
			`Stdout.formatln("{}({}): trace", __FILE__, __LINE__);`;
	else
		const char[] trace =
			`Stdout.formatln("{}: {}({}): trace", `~prefix.stringof~`, __FILE__, __LINE__);`;
	//pragma(msg, "trace: " ~ trace);
}

/**
Wraps a string mixin and displays the string at compile-time. Useful for debugging.

Usage:

----
template defineFloat(char[] name)
{ const char[] defineFloat = "float "~name~";"; }
char[] defineInt(char[] name, char[] value)
{ return "int "~name~"="~value";"; }

mixin(traceMixin!("defineFloat!", `"myFloat"`));
mixin(traceMixin!("defineInt!", `"myInt", 5`));
----

Turns Into:

----
template defineFloat(char[] name)
{ const char[] defineFloat = "float "~name~";"; }
char[] defineInt(char[] name, char[] value)
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
*/

template traceMixin(char[] name, char[] args)
{
	const char[] traceMixin = 
		`pragma(msg, "` ~ name ~ `: \n"~`~name~`(`~args~`));`~"\n"~
		"mixin("~name~"("~args~"));\n";
	//pragma(msg, "traceMixin: "~traceMixin);
}

/**
Useful in class/struct declarations for DRY.

Generates a public getter, private setter, and a hidden private var.
If the type is an array, the getter automatically returns a
shallow ".dup" (for safety).

As with any getter in D1, care should be taken when using this for
reference types, as there is no general way to prevent a caller from
changing the data pointed to by the underlying reference.

Usage:

----
mixin(getter!(int, "myVar"));
mixin(getter!(float, "someFloat", 2.5));
mixin(getter!(char[], "str"));
----

Turns Into:

----
private int _myVar;
private int myVar(int _NEW_VAL_)
{
	_myVar = _NEW_VAL_;
	return _myVar;
}
public int myVar()
{
	return _myVar;
}

private float _someFloat = 2.5;
private float someFloat(float _NEW_VAL_)
{
	_someFloat = _NEW_VAL_;
	return _someFloat;
}
public float someFloat()
{
	return _someFloat;
}

private char[] _str;
private char[] str(char[] _NEW_VAL_)
{
	_str = _NEW_VAL_;
	return _str;
}
public char[] str()
{
	return _str.dup;
}
----
*/
template getter(varType, char[] name, varType initialValue=varType.init)
{
	static if(is(varType.init))
		const char[] getter = getterX!("private", varType, name, initialValue);
	else
		const char[] getter = getterX!("private", varType, name);
	//pragma(msg, "getter: " ~ getter);
}

template getterProtected(varType, char[] name, varType initialValue=varType.init)
{
	static if(is(varType.init))
		const char[] getter = getterX!("protected", varType, name, initialValue);
	else
		const char[] getter = getterX!("protected", varType, name);
	//pragma(msg, "getterProtected: " ~ getterProtected);
}

template getterX(char[] writeAccess, varType, char[] name, varType initialValue=varType.init)
{
	static if(is(varType.init))
	{
		const char[] getterX =
			writeAccess~" "~varType.stringof~" _"~name~(initialValue.stringof == varType.init.stringof ? "" : "=" ~ initialValue.stringof)~";\n"~
			writeAccess~" "~varType.stringof~" "~name~"("~varType.stringof~" _NEW_VAL_) {_"~name~"=_NEW_VAL_;return _"~name~";}\n"~
			"public "~varType.stringof~" "~name~"() {return _"~name~(isAnyArrayType!(varType)?".dup":"")~";}\n";
	}
	else
	{
		const char[] getterX =
			writeAccess~" "~varType.stringof~" _"~name~";\n"~
			writeAccess~" "~varType.stringof~" "~name~"("~varType.stringof~" _NEW_VAL_) {_"~name~"=_NEW_VAL_;return _"~name~";}\n"~
			"public "~varType.stringof~" "~name~"() {return _"~name~(isAnyArrayType!(varType)?".dup":"")~";}\n";
	}
//	pragma(msg, "getterX: " ~ getterX);
}

/**
Similar to "getter", but for values that are to be lazily generated
(ie, values that are complex to generate, not always used, and rarely
change). The first time the getter is called, it generates
the value (by calling "_myVarName_gen()") and caches it. On subsequent
calls, the cached value is returned. The cache can be cleared (privately)
by setting "_myVarName_cached" to false.

Example use-case: If you have a property created by getter() and want
to change the "get" from a trivial "return _blah" to a manual function, 
you will most likely just simply switch from getter to getterLazy.

If you don't want the value to ever be cached, just set "_myVarName_cached"
to false within your "_myVarName_gen()" function.

As with "getter", if the type is an array, the getter automatically
returns a shallow ".dup" (for safety).

As with any getter in D1, care should be taken when using this for
reference types, as there is no general way to prevent a caller from
changing the data pointed to by the cached reference.

Usage:

----
mixin(getterLazy!(int, "myVar"));
private int _myVar_gen()
{
	// Ordinarily, this function would be more complex
	return 7;
}

mixin(getterLazy!(char[], "str", "customGenFunc"));
private char[] customGenFunc()
{
	return "Hello";
}
----

Turns Into:

----
private int _myVar;
private bool _myVar_cached = false;
public int myVar() {
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

private char[] _str;
private bool _str_cached = false;
public char[] str() {
	if(!_str_cached) {
		_str_cached = true;
		_str = customGenFunc();
	}
	return _str.dup;
}
private char[] customGenFunc()
{
	return "Hello";
}

----
*/
//TODO? Make another version that doesn't need/use _myVar_cached
//TODO? Better name for this?
template getterLazy(varType, char[] name, char[] genFunc="")
{
	const char[] getterLazy =
		"\n"~
		"static if(!is(typeof(_"~name~"_gen)==function))\n"~
		`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires function '`~varType.stringof~` _`~name~`_gen()' to be defined");`~"\n"~

		// Blocked by DMD Bug #2885
		//"static if(!is(ReturnTypeOf!(_"~name~"_gen):"~varType.stringof~"))\n"~
		//`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires function '_`~name~`_gen' to return type '`~varType.stringof~`' (or a compatible type), not type '"~ReturnTypeOf!(_`~name~`_gen).stringof~"'");`~"\n"~

		// Forward reference issues prevent this too
		//"static if(!ParameterTupleOf!(_line_gen).length==0)\n"~
		//`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires an overload of function '_`~name~`_gen' that takes no arguments");`~"\n"~

		"private "~varType.stringof~" _"~name~";\n"~
		"private bool _"~name~"_cached = false;\n"~
		"public "~varType.stringof~" "~name~"() {\n"~
		"	if(!_"~name~"_cached) {\n"~
		"		_"~name~"_cached = true;\n"~
		"		_"~name~" = "~(genFunc!=""?genFunc:"_"~name~"_gen")~"();\n"~
		"	}\n"~
		"	return _"~name~(isAnyArrayType!(varType)?".dup":"")~";\n"~
		"}\n";

	//pragma(msg, "getterLazy: " ~ getterLazy);
}

/**
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
*/

template ensureCharType(char[] nameOfT, char[] nameOfCaller="")
{
	const char[] ensureCharType = 
		`static assert(`~"\n"~
		`	is(`~nameOfT~`==char) || is(`~nameOfT~`==wchar) || is(`~nameOfT~`==dchar),`~"\n"~
		`	"`~(nameOfCaller==""?"":"From '"~nameOfCaller~"': ")~`'`~nameOfT~`' must be char, wchar or dchar, not '"~`~nameOfT~`.stringof~"'"`~"\n"~
		`);`;

	//pragma(msg, "ensureCharType: " ~ ensureCharType);
}
