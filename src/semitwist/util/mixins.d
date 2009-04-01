// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.mixins;

import tango.core.Traits;

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
Stdout.formatln("myVar: {}", myVar);
Stdout.formatln("   myVar-1 : {}",   myVar-1 );
Stdout.formatln("min(4,7): {}", min(4,7));
Stdout.formatln("max(4,7): {}", max(4,7));
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
//TODO?: Find way to convert nameLength to string at compile time
/// 'values' should be strings
template traceVal(values...)
{
	static if(values.length == 0)
		const char[] traceVal = "";
	else
		const char[] traceVal =
			"Stdout.formatln(\""~values[0].stringof[1..$-1]~": {}\", "~values[0].stringof[1..$-1]~");"
			~ traceVal!(values[1..$]);
}
/+
char[] traceVal(char[] varName/*, uint nameLength=0*/)
{
	//TODO: Find way to convert nameLength to string at compile time
//	return "Stdout.formatln(\"" ~ varName ~ ": {," ~ toString(-nameLength) ~ "}\", " ~ varName ~ ");";
//	return "Stdout.formatln(\"" ~ varName ~ ": {,-" ~ nameLength ~ "}\", " ~ varName ~ ");";
	return "Stdout.formatln(\"" ~ varName ~ ": {}\", " ~ varName ~ ");";

	// Using pad() at compile-time causes an out-of-memory error
	//return "Stdout.formatln(\"" ~ pad(varName ~ ":", 20u+1u, false) ~ " {}\", " ~ varName ~ ");";

/*	auto format = new Layout!(char)();
	// Stdout.formatln("[varName]: {}", [varName]);
	// "Stdout.formatln(\"{,} {{}\", {});", varName ~ ":", varName
//	return format("Stdout.formatln(\"{,-" ~ nameLength ~ "} {{}\", {});", varName ~ ":", varName);
	return format("Stdout.formatln(\"{}: {{}\", {});", varName, varName);
*/}

char[] traceVal(char[][] varNames/*, uint nameLength=0*/)
{
	char[] ret = "";
	//int maxLen = maxLength(varNames);
	//auto maxLen = nameLength;
	
	foreach(char[] name; varNames)
		ret ~= traceVal(name/*, maxLen*/);

	return ret;
}
+/

/**
Generates a public getter, private setter, and a hidden private var.
If the type is an array, the getter automatically returns a shallow ".dup".
Useful in class/struct declarations for DRY.

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
	const char[] getter =
		"private "~varType.stringof~" _"~name~(initialValue == varType.init ? "" : "=" ~ initialValue.stringof)~";\n"~
		"private "~varType.stringof~" "~name~"("~varType.stringof~" _NEW_VAL_) {_"~name~"=_NEW_VAL_;return _"~name~";}\n"~
		"public "~varType.stringof~" "~name~"() {return _"~name~(isAnyArrayType!(varType)?".dup":"")~";}\n";
	//pragma(msg, "getter: " ~ getter);
}

template isAnyArrayType(T)
{
	const bool isAnyArrayType =
		isArray!(T) ||
		isAssocArrayType!(T);
}

// From Tango trunk
template isArray(T)
{
	static if (is( T U : U[] ))
		const bool isArray=true;
	else
		const bool isArray=false;
}

// From Tango trunk
template KeyTypeOfAA(T){
	alias typeof(T.init.keys[0]) KeyTypeOfAA;
}

// From Tango trunk
template ValTypeOfAA(T){
	alias typeof(T.init.values[0]) ValTypeOfAA;
}

// If T is a static array, it's changed to a dynamic array, otherwise just returns T.
template PreventStaticArray(T)
{
	static if(isArray!(T))
		private alias ElementTypeOfArray!(T)[] PreventStaticArray;
	else
		private alias T PreventStaticArray;
}
