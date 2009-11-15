// SemiTwist Library
// Written in the D programming language.

module semitwist.util.mixins;

import tango.core.Traits;
import tango.io.Stdout;

import semitwist.util.ctfe;
import semitwist.util.reflect;
import semitwist.util.text;

/++
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
+/
template initMember(vars...)
{
	const char[] initMember = initMemberX!("this.{} = {}", vars);
}

/++
Generic version of initMember.

Usage:
----
mixin(initMemberX!("foo1.{} = foo2.{}", someVar));
mixin(initMemberX!("this._{} = foo.{}", a, b, c));
----

Turns Into:
----
foo1.someVar = foo2.someVar;
this._a = foo.a;
this._b = foo.b;
this._c = foo.c;
----
+/
template initMemberX(char[] str, vars...)
{
	const char[] initMemberX = ctfe_subMapJoin(str~";\n", "{}", templateArgsToStrings!(vars));
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
+/
template initMemberFrom(alias from, vars...)
{
	const char[] initMemberFrom = initMemberX!("this.{} = "~from.stringof~".{}", vars);
}

template initMemberTo(alias to, vars...)
{
	const char[] initMemberTo = initMemberX!(to.stringof~".{} = {}", vars);
}

template initFrom(alias from, vars...)
{
	const char[] initFrom = initMemberX!("{} = "~from.stringof~".{}", vars);
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
+/

//TODO: Add ability to specify format (binary, hex, etc)
//TODO: Make nameLength work by using Layout.format (at runtime)
//      on data passed to Stdout.formatln
//      (ie, align name/value)
//TODO: Messes up on "ctfe_repeat_test_日本語3"
template traceVal(values...)
{
	const char[] traceVal = traceVal!(false, values);
}

template traceVal(bool useNewline, values...)
{
	static if(values.length == 0)
		const char[] traceVal = "";
	else
	{
		const char[] traceVal =
			"Stdout.formatln(\"{}:"~(useNewline?"\\n":" ")~"{}\", "~values[0].stringof~", "~unescape(values[0].stringof, EscapeSequence.DoubleQuoteString)~");"
			~ traceVal!(useNewline, values[1..$]);
	}
}

/++
Easy way to output file/line. Useful for debugging.

Usage:

----
mixin(trace!());
funcSuspectedOfCrashing1_notTheRealCause()
mixin(trace!("--EASY TO VISUALLY GREP--"));
funcSuspectedOfCrashing2_isTheRealCause()
mixin(trace!());
----

Turns Into:

----
Stdout.formatln("{}({}): trace", __FILE__, __LINE__);
funcSuspectedOfCrashing1_notTheRealCause()
Stdout.formatln("{}{}({}): trace", "--EASY TO VISUALLY GREP--", __FILE__, __LINE__);
funcSuspectedOfCrashing2_isTheRealCause()
Stdout.formatln("{}({}): trace", __FILE__, __LINE__);
----

Example Output:

----
C:\path\file.d(1): trace
--EASY TO VISUALLY GREP--: C:\path\file.d(3): trace
{segfault!}
----
+/
template trace(char[] prefix="")
{
	static if(prefix=="")
		const char[] trace =
			`Stdout.formatln("{}({}): trace", __FILE__, __LINE__);`;
	else
		const char[] trace =
			`Stdout.formatln("{}: {}({}): trace", `~prefix.stringof~`, __FILE__, __LINE__);`;
}

/++
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
+/

template traceMixin(char[] name, char[] args)
{
	const char[] traceMixin = 
		`pragma(msg, "` ~ name ~ `: \n"~`~name~`(`~args~`));`~"\n"~
		"mixin("~name~"("~args~"));\n";
}

/++
Compile-time version of traceVal.

Only works for string values right now.

Usage:

----
const char[] fooStr = "Hi";
const char[] fooStr2 = "Hi2";
mixin(traceValCT!("fooStr", "fooStr2"));
mixin(traceValCT!(`fooStr~" Joe"`));

template fooTmpl
{
	const char[] fooTempl = "Hello World";
	mixin(traceValCT!(true, "fooTempl"));
}
----

Turns Into:

----
const char[] fooStr = "Hi";
const char[] fooStr2 = "Hi2";
pragma(msg, "fooStr: " ~ (fooStr));
pragma(msg, "fooStr2: " ~ (fooStr2));
pragma(msg, "fooStr~\" Joe\""~": " ~ (fooStr~" Joe"));

template fooTmpl
{
	const char[] fooTempl = "Hello World";
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
	const char[] traceValCT = traceValCT!(false, values);
}

template traceValCT(bool useNewline, values...)
{
	static if(values.length == 0)
	{
		const char[] traceValCT = "";
	}
	else
	{
		const char[] traceValCT =
			"pragma(msg, "~escapeDoubleQuoteString(values[0])~"~\":"~(useNewline? "\\n":" ")~"\" ~ ("~values[0]~"));\n"~
			traceValCT!(useNewline, values[1..$]);

		//pragma(msg, "traceValCT: " ~ traceValCT);
	}
}

/++
Useful in class/struct declarations for DRY.

Generates a public getter, private setter, and a hidden private var.
If the type is an array, the getter automatically returns a
shallow ".dup" (for safety).

As with any getter in D1, care should be taken when using this for
reference types, as there is no general way to prevent a caller from
changing the data that is being pointed to.

Usage:

----
mixin(getter!(int, "myVar"));
mixin(getter!("protected", float, "someFloat", 2.5));
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

protected float _someFloat = 2.5;
protected float someFloat(float _NEW_VAL_)
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
+/
template getter(varType, char[] name, varType initialValue=varType.init)
{
	static if(is(varType.init))
		const char[] getter = getter!("private", varType, name, initialValue);
	else
		const char[] getter = getter!("private", varType, name);
}

template getter(char[] writeAccess, varType, char[] name, varType initialValue=varType.init)
{
	static if(is(varType.init))
	{
		const char[] getter =
			writeAccess~" "~varType.stringof~" _"~name~(initialValue.stringof == varType.init.stringof ? "" : "=" ~ initialValue.stringof)~";\n"~
			writeAccess~" "~varType.stringof~" "~name~"("~varType.stringof~" _NEW_VAL_) {_"~name~"=_NEW_VAL_;return _"~name~";}\n"~
			"public "~varType.stringof~" "~name~"() {return _"~name~(isAnyArrayType!(varType)?".dup":"")~";}\n";
	}
	else
	{
		const char[] getter =
			writeAccess~" "~varType.stringof~" _"~name~";\n"~
			writeAccess~" "~varType.stringof~" "~name~"("~varType.stringof~" _NEW_VAL_) {_"~name~"=_NEW_VAL_;return _"~name~";}\n"~
			"public "~varType.stringof~" "~name~"() {return _"~name~(isAnyArrayType!(varType)?".dup":"")~";}\n";
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

As with "getter", if the type is an array, the getter automatically
returns a shallow ".dup" (for safety).

As with any getter in D1, care should be taken when using this for
reference types, as there is no general way to prevent a caller from
changing the data that is being pointed to.

Usage:

----
mixin(getterLazy!(int, "myVar", `
	// Ordinarily, this function would be more complex
	return 7;
`));

mixin(getterLazy!("protected", int, "myVar2", `return 7;`));

mixin(getterLazy!(char[], "str"));
private char[] _str_gen()
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

protected int _myVar2;
protected bool _myVar2_cached = false;
public int myVar2() {
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
+/
//TODO? Merge with getter if reasonably possible
template getterLazy(varType, char[] name, char[] genFunc="")
{
	const char[] getterLazy = getterLazy!("private", varType, name, genFunc);
}

template getterLazy(char[] writeAccess, varType, char[] name, char[] genFunc="")
{
	const char[] getterLazy =
		"\n"~
		((genFunc=="")?
			"static if(!is(typeof(_"~name~"_gen)==function))\n"~
			`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires function '`~varType.stringof~` _`~name~`_gen()' to be defined");`~"\n"

			// Blocked by DMD Bug #2885
			//"static if(!is(ReturnTypeOf!(_"~name~"_gen):"~varType.stringof~"))\n"~
			//`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires function '_`~name~`_gen' to return type '`~varType.stringof~`' (or a compatible type), not type '"~ReturnTypeOf!(_`~name~`_gen).stringof~"'");`~"\n"~

			// Forward reference issues prevent this too
			//"static if(!ParameterTupleOf!(_line_gen).length==0)\n"~
			//`	static assert(false, "'getterLazy!(`~varType.stringof~`, \"`~name~`\")' requires an overload of function '_`~name~`_gen' that takes no arguments");`~"\n"~
		:"")~

		writeAccess~" "~varType.stringof~" _"~name~";\n"~
		writeAccess~" bool _"~name~"_cached = false;\n"~
		"public "~varType.stringof~" "~name~"() {\n"~
		"	if(!_"~name~"_cached) {\n"~
		"		_"~name~"_cached = true;\n"~
		"		_"~name~" = _"~name~"_gen();\n"~
		"	}\n"~
		"	return _"~name~(isAnyArrayType!(varType)?".dup":"")~";\n"~
		"}\n"~
		((genFunc=="")?"":
			"private "~varType.stringof~" _"~name~"_gen()\n"~
			"{\n"~
			genFunc~
			"}\n"
		);
}

/++
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

template ensureCharType(char[] nameOfT, char[] nameOfCaller="")
{
	const char[] ensureCharType = 
		`static assert(`~"\n"~
		`	is(`~nameOfT~`==char) || is(`~nameOfT~`==wchar) || is(`~nameOfT~`==dchar),`~"\n"~
		`	"`~(nameOfCaller==""?"":"From '"~nameOfCaller~"': ")~`'`~nameOfT~`' must be char, wchar or dchar, not '"~`~nameOfT~`.stringof~"'"`~"\n"~
		`);`;
}

//TODO: Document genEnum
public char[] genEnum(char[] name, char[][] values)
{
	return
		"enum "~name~" {"~values.ctfe_join(", ")~"}\n"~
		"const uint "~name~"_length = "~ctfe_i2a(values.length)~";\n"~
		_genEnumToString(name, values);
}

// The function this generates could probably be improved.
public char[] _genEnumToString(char[] enumName, char[][] enumValues)
{
	char[] value = "";
	
	foreach(char[] enumValue; enumValues)
		value ~= "    if(value=="~enumName~"."~enumValue~") return \""~enumValue~"\";\n";
	
	value =
		"char[] enumToString("~enumName~" value)\n"~
		"{\n"~
		value~
		`    throw new Exception("Internal Error: Unhandled value in `~enumName~`ToString");`~"\n"~
		"}\n";
	
	return value;
}
