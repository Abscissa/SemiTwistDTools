// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.mixins;

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
//	pragma(msg, "initMember: " ~ initMember);
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
//TODO: Add ability to specify format (binary, hex, etc)
//TODO: Make nameLength work by using Layout.format (at runtime)
//      on data passed to Stdout.formatln
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
Useful in class/struct declarations for DRY.

Usage:

----
mixin(getter("int", "myVar", "getMyVar"));
----

Turns Into:

----
private int myVar;
public int getMyVar()
{
	return myVar;
}
----
*/
char[] getter(char[] varType, char[] varName, char[] getterName, char[] initialValue="")
{
	return "private "~varType~" "~varName~(initialValue == "" ? "" : "=" ~ initialValue)~"; "~
		   "public "~varType~" "~getterName~"() {return "~varName~";}";
}
