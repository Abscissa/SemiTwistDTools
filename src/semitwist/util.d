// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

// DMD output capturing for Programmer's Notepad:
// %f\(%l\):

module semitwist.util;

import tango.io.Stdout;	
import tango.io.protocol.Reader;
import tango.io.stream.DataStream;
import tango.math.Math;
import tango.text.Util;
import tango.text.convert.Layout;

//TODO: Turn this into a debugmode-only alias/func
/*
Stdout.formatln("blah: {} (line {})", __FILE__, __LINE__);
*/

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

int maxLength(char[][] strs)
{
	int maxLen=0;
	foreach(char[] str; strs)
		maxLen = max(maxLen, str.length);
	return maxLen;
}

size_t indexOfMin(T)(T[] array)
{
	T best = T.max;
	size_t bestIndex;
	foreach(size_t i, T elem; array)
	{
		if(elem < best)
		{
			best = elem;
			bestIndex = i;
		}
	}
	return bestIndex;
}

size_t indexOfMax(T)(T[] array)
{
	T best = T.min;
	size_t bestIndex;
	foreach(size_t i, T elem; array)
	{
		if(elem > best)
		{
			best = elem;
			bestIndex = i;
		}
	}
	return bestIndex;
}

// Intended for CTFE, but tends to cause Out Of Memory error
private char[] pad(char[] str, uint length, char padChar=' ')
{
	return pad(str, length, true, padChar);
}
private char[] pad(char[] str, uint length, bool padLeft=true, char padChar=' ')
{
	if(str.length < length)
	{
		auto padding = _repeat(padChar, str.length - length);
		
		if(padLeft)
			str = padding ~ str;
		else
			str = str ~ padding;
	}
	
	return str;
}

// Intended for CTFE, but tends to cause Out Of Memory error
private char[] _repeat(char chr, uint count)
{
	return _repeat("" ~ chr, count);
}
private char[] _repeat(char[] str, uint count)
{
	if(count == 0)
		return "";
		
	for(int i=0; i<count-1; i++)
		str ~= str;
		
	return str;
}

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

/**
Anything in "data" must be doubly escaped.

For instance, if you want the generated function to return newline (ie, "\n"),
then "data" must be ['\\', 'n'], and thus the mixin call would look like this:

----
mixin(multiTypeString("unixNewline", "\\n"));
// Or
mixin(multiTypeString("unixNewline", r"\n"));
----

Or, if you want the generated function to return the escape sequence
for newline (ie, r"\n", or "\\n", or ['\\', 'n']), then "data" must
be ['\\', '\\', 'n'], and thus the mixin call would look like this:

----
mixin(multiTypeString("unixNewlineEscSequence", "\\\\n"));
// Or
mixin(multiTypeString("unixNewlineEscSequence", r"\\n"));
----

(This requirement could be changed if there is a way to automatically
escape a string at compile-time.)
*/
//TODO: Look into using tango.core.Traits.isCharType()
char[] multiTypeString(char[] name, char[] data, char[] access="public")
{
	return 
	access~" T[] "~name~"(T)()"~
	"{"~
	"		 static if(is(T ==  char)) { return \""~data~"\"c; }"~
	"	else static if(is(T == wchar)) { return \""~data~"\"w; }"~
	"	else static if(is(T == dchar)) { return \""~data~"\"d; }"~
	"	else static assert(\"T must be char, wchar, or dchar\");"~
	"}";
}

// Note: Almost useless. The compiler doesn't report the file/line where the
//       template function that called this was instantiated.
//       (TODO: Maybe I could fix that with templates...?)
private char[] ensureCharType(char[] typeName, char[] msg="")
{
	return "static assert(is("~typeName~" == char) || is("~typeName~" == wchar) || is("~typeName~" == dchar), \""~msg~"\");";
}

mixin(multiTypeString("whitespaceChars", r" \n\r\t\v\f"));
mixin(multiTypeString("emptyString", r""));
mixin(multiTypeString("lowerLetterA", r"a"));
mixin(multiTypeString("lowerLetterZ", r"z"));
mixin(multiTypeString("upperLetterA", r"A"));
mixin(multiTypeString("upperLetterZ", r"Z"));
mixin(multiTypeString("digit0", r"0"));
mixin(multiTypeString("digit9", r"9"));

T[] lowercaseLetters(T)()
{
	static T[] cache = emptyString!(T)();
	
	if(cache == emptyString!(T)())
	{
		T currChar;
		for(currChar  = lowerLetterA!(T)()[0];
			currChar <= lowerLetterZ!(T)()[0];
			currChar++)
		{
			cache ~= currChar;
		}
	}

	return cache;
}

T[] uppercaseLetters(T)()
{
	static T[] cache = emptyString!(T)();
	
	if(cache == emptyString!(T)())
	{
		T currChar;
		for(currChar  = upperLetterA!(T)()[0];
			currChar <= upperLetterZ!(T)()[0];
			currChar++)
		{
			cache ~= currChar;
		}
	}

	return cache;
}

T[] digitChars(T)()
{
	static T[] cache = emptyString!(T)();
	
	if(cache == emptyString!(T)())
	{
		T currChar;
		for(currChar  = digit0!(T)()[0];
			currChar <= digit9!(T)()[0];
			currChar++)
		{
			cache ~= currChar;
		}
	}

	return cache;
}

/// Returns true iff [0-9]
bool isDigit(T:char)(T chr)  {return _isDigit(chr);}
bool isDigit(T:wchar)(T chr) {return _isDigit(chr);}
bool isDigit(T:dchar)(T chr) {return _isDigit(chr);}
private bool _isDigit(T)(T chr)
{
	uint uintChr = cast(uint)chr;
	return (uintChr >= cast(uint)'0' && uintChr <= cast(uint)'9');
}

/// Note: Currently only supports [a-zA-Z]
bool isAlpha(T:char)(T chr)  {return _isAlpha(chr);}
bool isAlpha(T:wchar)(T chr) {return _isAlpha(chr);}
bool isAlpha(T:dchar)(T chr) {return _isAlpha(chr);}
private bool _isAlpha(T)(T chr)
{
	uint uintChr = cast(uint)chr;
	return (uintChr >= cast(uint)'a' && uintChr <= cast(uint)'z') ||
		   (uintChr >= cast(uint)'A' && uintChr <= cast(uint)'Z');
}

bool isAlphaNumeric(T:char)(T chr)  {return _isAlphaNumeric(chr);}
bool isAlphaNumeric(T:wchar)(T chr) {return _isAlphaNumeric(chr);}
bool isAlphaNumeric(T:dchar)(T chr) {return _isAlphaNumeric(chr);}
private bool _isAlphaNumeric(T)(T chr)
{
	return isDigit(chr) || isAlpha(chr);
}

bool isWhitespace(T:char)(T chr)  {return _isWhitespace(chr);}
bool isWhitespace(T:wchar)(T chr) {return _isWhitespace(chr);}
bool isWhitespace(T:dchar)(T chr) {return _isWhitespace(chr);}
private bool _isWhitespace(T)(T chr)
{
	return contains(whitespaceChars!(T)(), chr);
}


/**
If you have a class MyClass(T), then nameof!(MyClass) will return "MyClass".

One benefit of this is that you can do things like:
	mixin("auto obj = new "~nameof!(MyClass)~"!(int)()");
and the "MyClass" will be checked by the compiler, alerting you immediately
if the class name changes, helping you keep such strings up-to-date.
*/

template nameof(alias T)
{
	const char[] nameof = T.stringof[0..ctfe_find(T.stringof, '(')];
}

/// tango.text.Util.locate() and tango.core.Array.find() don't work at compile-time.
size_t ctfe_find(T)(T[] collection, T elem, size_t start=0)
{
	for(size_t i=start; i<collection.length; i++)
	{
		if(collection[i] == elem)
			return i;
	}
	return collection.length;
}

//TODO: Is this the same as tango.core.Array.findIf()?
size_t find(T)(T[] collection, bool delegate(T[], size_t) isFound, size_t start=0)
{
	for(size_t i=start; i<collection.length; i++)
	{
		if(isFound(collection, i))
			return i;
	}
	
	return collection.length;
}

size_t findPrior(T)(T[] collection, bool delegate(T[], size_t) isFound, size_t start=(size_t).max)
{
	if(start == (size_t).max)
		start = collection.length-1;
		
	for(size_t i=start; i >= 0; i--)
	{
		if(isFound(collection, i))
			return i;
	}

	return collection.length;
}

mixin(multiTypeString("winEOL",  r"\r\n"));
mixin(multiTypeString("macEOL",  r"\r"));
mixin(multiTypeString("unixEOL", r"\n"));
mixin(multiTypeString("tabChar", r"\t"));

version(Windows)   char[] nativeEOL = "\r\n";
version(Macintosh) char[] nativeEOL = "\r";   // This version string probably isn't right
version(Linux)     char[] nativeEOL = "\n";   // Not sure if this version string is right

static this()
{
	assert(unixEOL!(char)() == "\n"c,  "unixEOL() is incorrent");
	assert(tabChar!(char)() == "\t"c,  "tabChar() is incorrent");
	assert( winEOL!(char)() == "\r\n"c, "winEOL() is incorrent");
	assert( macEOL!(char)() == "\r"c,   "macEOL() is incorrent");
}

/// Unix EOL: "\n"
void toUnixEOL(T)(ref T[] str)
{
	str = substitute(str, winEOL!(T)(), unixEOL!(T)()); // Win -> Unix
	str = substitute(str, macEOL!(T)(), unixEOL!(T)()); // Mac -> Unix
}

/// Mac EOL: "\r"
void toMacEOL(T)(ref T[] str)
{
	str = substitute(str, winEOL!(T)(),  macEOL!(T)()); // Win  -> Mac
	str = substitute(str, unixEOL!(T)(), macEOL!(T)()); // Unix -> Mac
}

/// Win EOL: "\r\n"
void toWinEOL(T)(ref T[] str)
{
	toUnixEOL(str); // All -> Unix
	str = substitute(str, unixEOL!(T)(), winEOL!(T)()); // Unix -> Win
}

T[] toNativeEOL(T)(T[] str)
{
	version(Windows)   toWinEOL(str);
	version(Macintosh) toMacEOL(str);  // This version string probably isn't right
	version(Linux)     toUnixEOL(str); // Not sure if this version string is right
	return str;
}

T[] toNativeEOLFromUnix(T)(T[] str)
{
	version(Windows)   return str.toNativeEOL();
	version(Macintosh) return str.toNativeEOL();  // This version string probably isn't right
	return str;
}

T[] toNativeEOLFromWin(T)(T[] str)
{
	version(Macintosh) return str.toNativeEOL();  // This version string probably isn't right
	version(Linux)     return str.toNativeEOL();  // Not sure if this version string is right
	return str;
}

T[] toNativeEOLFromMac(T)(T[] str)
{
	version(Windows)   return str.toNativeEOL();
	version(Linux)     return str.toNativeEOL();  // Not sure if this is right
	return str;
}

enum EscapeSequence
{
	SemiTwist
}

T[] unescape(T:char) (EscapeSequence type, T[] str) {return _unescape(type, str);}
T[] unescape(T:wchar)(EscapeSequence type, T[] str) {return _unescape(type, str);}
T[] unescape(T:dchar)(EscapeSequence type, T[] str) {return _unescape(type, str);}
private T[] _unescape(T)(EscapeSequence type, T[] str)
{
	T[] ret;
	
	switch(type)
	{
	case EscapeSequence.SemiTwist:
		ret = unescapeSemiTwist(str);
		break;
		
	default:
		throw new Exception("Unknown EscapeSequence");
	}
	
	return ret;
}

T[] unescapeChar(T:char) (T[] str, T[] escapeSequence) {return _unescapeChar(str, escapeSequence);}
T[] unescapeChar(T:wchar)(T[] str, T[] escapeSequence) {return _unescapeChar(str, escapeSequence);}
T[] unescapeChar(T:dchar)(T[] str, T[] escapeSequence) {return _unescapeChar(str, escapeSequence);}
private T[] _unescapeChar(T)(T[] str, T[] escapeSequence)
{
	T[] ret = str;
	ret = substitute(ret, escapeSequence, escapeSequence[$-1..$]);
	return ret;
}

mixin(multiTypeString("escSequence_SemiTwist_Digit",                r"\\d"));
mixin(multiTypeString("escSequence_SemiTwist_UppercaseAlpha",       r"\\u"));
mixin(multiTypeString("escSequence_SemiTwist_LowercaseAlpha",       r"\\l"));
mixin(multiTypeString("escSequence_SemiTwist_Whitespace",           r"\\s"));
mixin(multiTypeString("escSequence_SemiTwist_Backslash",            r"\\\\"));
mixin(multiTypeString("escSequence_SemiTwist_OpeningSquareBracket", r"\\["));
mixin(multiTypeString("escSequence_SemiTwist_ClosingSquareBracket", r"\\]"));
mixin(multiTypeString("escSequence_SemiTwist_Caret",                r"\\^"));
mixin(multiTypeString("escSequence_SemiTwist_Asterisk",             r"\\*"));
mixin(multiTypeString("escSequence_SemiTwist_Plus",                 r"\\+"));

T[] unescapeSemiTwist(T:char) (T[] str) {return _unescapeSemiTwist(str);}
T[] unescapeSemiTwist(T:wchar)(T[] str) {return _unescapeSemiTwist(str);}
T[] unescapeSemiTwist(T:dchar)(T[] str) {return _unescapeSemiTwist(str);}
private T[] _unescapeSemiTwist(T)(T[] str)
{
	T[] ret = str;
	
	ret = substitute(ret, escSequence_SemiTwist_Digit!(T)(),          digitChars!(T)());
	ret = substitute(ret, escSequence_SemiTwist_UppercaseAlpha!(T)(), uppercaseLetters!(T)());
	ret = substitute(ret, escSequence_SemiTwist_LowercaseAlpha!(T)(), lowercaseLetters!(T)());
	ret = substitute(ret, escSequence_SemiTwist_Whitespace!(T)(),     whitespaceChars!(T)());
	
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Backslash!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_OpeningSquareBracket!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_ClosingSquareBracket!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Caret!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Asterisk!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Plus!(T)());
	
	return ret;
}

/// Suggested usage:
///   "Hello {}!".stformat("World");
Layout!(char)  stformat;
Layout!(wchar) stformatw;
Layout!(dchar) stformatd;
static this()
{
	stformat  = new Layout!( char)();
	stformatw = new Layout!(wchar)();
	stformatd = new Layout!(dchar)();
}

/*
// Simon Kjaeraas
import std.stdio;
import std.traits;

template _debug(alias f, int line = __LINE__, string file = __FILE__)
{
	ReturnType!(f) _debug(ParameterTypeTuple!(f) u)
	{
		writefln("%s(%d) executed.", file, line);
		return f(u);
	}
}


Usage:

_debug(function)(parameters);
*/

/**
Sounds like a contradiction of terms, but this is just
intended to allow unittests to output ALL failures instead
of only outputting the first one and then stopping.
*/
//Automatic __LINE__ and __FILE__ don't work
//template NonFatalAssert(int line = __LINE__, char[] file = __FILE__)
template NonFatalAssert(int line, char[] file)
{
	bool NonFatalAssert(bool cond, char[] msg="")
	{
		if(!cond)
		{
			nonFatalAssertCount++;
			Stdout.formatln("{}({}): Assert Failure{}", //"{}({}): Assert Failure ({}){}",
			                file, line,
//						    cond.stringof,
						    msg=="" ? "" : ": " ~ msg);
		}
		
		return cond;
	}
}
private uint nonFatalAssertCount=0;
uint getNonFatalAssertCount()
{
	return nonFatalAssertCount;
}
void resetNonFatalAssertCount()
{
	nonFatalAssertCount = 0;
}

char[] readNullTerminatedString(Reader reader)
{
	ubyte[] str;
	ubyte inByte;
	
	do
	{
		reader(inByte);
		str ~= inByte;
	} while(inByte != 0);

	return cast(char[])str[0..$-1];

/*	bool done = false;
	while(!done)
	{
		reader(inByte);
		if(inByte == 0)
			done = true;
		else
			str ~= inByte;
	}
	return cast(char[])str;
*/
}

wchar[] readNullTerminatedWString(Reader reader)
{
	wchar[] str;
	wchar c;
	
	do
	{
		reader(c);
		str ~= c;
	} while(c != 0);

	return str[0..$-1];
}

wchar[] readNullTerminatedWString(DataInput reader)
{
	wchar[] str;
	wchar c;
	
	do
	{
		c = reader.getShort();
		str ~= c;
	} while(c != 0);

	return str[0..$-1];
}
