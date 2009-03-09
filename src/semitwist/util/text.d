// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.text;

import tango.io.Stdout;
import tango.text.Util;
import tango.text.convert.Layout;

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
template multiTypeString(char[] name, char[] data, char[] access="public")
{
	const char[] multiTypeString = 
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

mixin(multiTypeString!("whitespaceChars", r" \n\r\t\v\f"));
mixin(multiTypeString!("emptyString", r""));
mixin(multiTypeString!("lowerLetterA", r"a"));
mixin(multiTypeString!("lowerLetterZ", r"z"));
mixin(multiTypeString!("upperLetterA", r"A"));
mixin(multiTypeString!("upperLetterZ", r"Z"));
mixin(multiTypeString!("digit0", r"0"));
mixin(multiTypeString!("digit9", r"9"));

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

bool startsWith(T)(T[] source, T[] match)
{
	return (source.locatePattern(match) == 0);
}

//TODO: test this
bool endsWith(T)(T[] source, T[] match)
{
	return (source.locatePatternPrior(match) == source.length - match.length);
}

mixin(multiTypeString!("winEOL",  r"\r\n"));
mixin(multiTypeString!("macEOL",  r"\r"));
mixin(multiTypeString!("unixEOL", r"\n"));
mixin(multiTypeString!("tabChar", r"\t"));

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
	else version(Macintosh) return str.toNativeEOL();  // This version string probably isn't right
	else return str;
}

T[] toNativeEOLFromWin(T)(T[] str)
{
	     version(Macintosh) return str.toNativeEOL();  // This version string probably isn't right
	else version(Linux)     return str.toNativeEOL();  // Not sure if this version string is right
	else return str;
}

T[] toNativeEOLFromMac(T)(T[] str)
{
	     version(Windows) return str.toNativeEOL();
	else version(Linux)   return str.toNativeEOL();  // Not sure if this is right
	else return str;
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

mixin(multiTypeString!("escSequence_SemiTwist_Digit",                r"\\d"));
mixin(multiTypeString!("escSequence_SemiTwist_UppercaseAlpha",       r"\\u"));
mixin(multiTypeString!("escSequence_SemiTwist_LowercaseAlpha",       r"\\l"));
mixin(multiTypeString!("escSequence_SemiTwist_Whitespace",           r"\\s"));
mixin(multiTypeString!("escSequence_SemiTwist_Backslash",            r"\\\\"));
mixin(multiTypeString!("escSequence_SemiTwist_OpeningSquareBracket", r"\\["));
mixin(multiTypeString!("escSequence_SemiTwist_ClosingSquareBracket", r"\\]"));
mixin(multiTypeString!("escSequence_SemiTwist_Caret",                r"\\^"));
mixin(multiTypeString!("escSequence_SemiTwist_Asterisk",             r"\\*"));
mixin(multiTypeString!("escSequence_SemiTwist_Plus",                 r"\\+"));

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

