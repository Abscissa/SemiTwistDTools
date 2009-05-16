// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.text;

import tango.core.Array;
import tango.io.Stdout;
import tango.text.Unicode;
import tango.text.Util;
import tango.text.convert.Layout;

import semitwist.util.ctfe;
import semitwist.util.mixins;

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
//       (TODO: Maybe I could fix that with templates...? No, I can't.)
/*private char[] ensureCharType(char[] typeName, char[] msg="")
{
	return "static assert(is("~typeName~" == char) || is("~typeName~" == wchar) || is("~typeName~" == dchar), \""~msg~"\");";
}
*/
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

version(Windows) char[] nativeEOL = "\r\n";
version(OSX)     char[] nativeEOL = "\r";
version(linux)   char[] nativeEOL = "\n";

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
	version(Windows) toWinEOL(str);
	version(OSX)     toMacEOL(str);
	version(linux)   toUnixEOL(str);
	return str;
}

T[] toNativeEOLFromUnix(T)(T[] str)
{
	     version(Windows) return str.toNativeEOL();
	else version(OSX)     return str.toNativeEOL();
	else return str;
}

T[] toNativeEOLFromWin(T)(T[] str)
{
	     version(OSX)   return str.toNativeEOL();
	else version(linux) return str.toNativeEOL();
	else return str;
}

T[] toNativeEOLFromMac(T)(T[] str)
{
	     version(Windows) return str.toNativeEOL();
	else version(linux)   return str.toNativeEOL();
	else return str;
}

enum EscapeSequence
{
	SemiTwist,
	DoubleQuoteString
}

T[] escape(T)(T[] str, EscapeSequence type)
{
	mixin(ensureCharType!("T", "escape"));

	T[] ret;
	
	switch(type)
	{
	case EscapeSequence.DoubleQuoteString:
		ret = escapeDoubleQuoteString(str);
		break;
		
	default:
		throw new Exception("Unsupported EscapeSequence");
	}
	
	return ret;
}

T[] unescape(T)(T[] str, EscapeSequence type)
{
	mixin(ensureCharType!("T", "unescape"));

	T[] ret;
	
	switch(type)
	{
	case EscapeSequence.SemiTwist:
		ret = unescapeSemiTwist(str);
		break;
		
	case EscapeSequence.DoubleQuoteString:
		ret = unescapeDoubleQuoteString(str);
		break;
		
	default:
		throw new Exception("Unsupported EscapeSequence");
	}
	
	return ret;
}

T[] unescapeChar(T)(T[] str, T[] escapeSequence)
{
	mixin(ensureCharType!("T", "unescapeChar"));

	T[] ret = str.dup;
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

T[] unescapeSemiTwist(T)(T[] str)
{
	mixin(ensureCharType!("T", "unescapeSemiTwist"));

	T[] ret = str.dup;
	
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

/+
// This stuff (substitute/unescapeChar) won't work at compile-time
mixin(multiTypeString!("escSequence_DoubleQuoteString_Quote", r"\\\""));
mixin(multiTypeString!("escSequence_DoubleQuoteString_Backslash", r"\\\\"));

T[] unescapeDoubleQuoteString(T)(T[] str)
{
	mixin(ensureCharType!("T", "unescapeDoubleQuoteString"));

	T[] ret = str.dup;
	
/*	ret = substitute(ret, escSequence_SemiTwist_Digit!(T)(),          digitChars!(T)());
	ret = substitute(ret, escSequence_SemiTwist_UppercaseAlpha!(T)(), uppercaseLetters!(T)());
	ret = substitute(ret, escSequence_SemiTwist_LowercaseAlpha!(T)(), lowercaseLetters!(T)());
	ret = substitute(ret, escSequence_SemiTwist_Whitespace!(T)(),     whitespaceChars!(T)());
*/	
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Backslash!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_OpeningSquareBracket!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_ClosingSquareBracket!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Caret!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Asterisk!(T)());
	ret = unescapeChar!(T)(ret, escSequence_SemiTwist_Plus!(T)());
	
	return ret;
}
+/

T[] unescapeDoubleQuoteString(T)(T[] str)
{
	mixin(ensureCharType!("T", "unescapeDoubleQuoteString"));

	T[] ret = str.dup;
	
	ret = ctfe_substitute(ret, cast(T[])`\\`, cast(T[])`\`);
	ret = ctfe_substitute(ret, cast(T[])`\"`, cast(T[])`"`);

	return ret[1..$-1];
}

T[] escapeDoubleQuoteString(T)(T[] str)
{
	mixin(ensureCharType!("T", "escapeDoubleQuoteString"));
		
	T[] ret = str.dup;
	
	ret = ctfe_substitute!(T)(ret, cast(T[])`\`, cast(T[])`\\`);
	ret = ctfe_substitute!(T)(ret, cast(T[])`"`, cast(T[])`\"`);

	return `"`~ret~`"`;
}

/+
const char[] doubleQuoteTestStr = `"They said \"10 \\ 5 = 2\""`;

pragma(msg, "orig:        "~doubleQuoteTestStr);
pragma(msg, "unesc:       "~unescapeDoubleQuoteString(doubleQuoteTestStr));
pragma(msg, "esc:         "~escapeDoubleQuoteString(doubleQuoteTestStr));
pragma(msg, "esc(unesc):  "~escapeDoubleQuoteString(unescapeDoubleQuoteString(doubleQuoteTestStr)));
pragma(msg, "unesc(esc):  "~unescapeDoubleQuoteString(escapeDoubleQuoteString(doubleQuoteTestStr)));

pragma(msg, "unesc:       "~unescape(doubleQuoteTestStr, EscapeSequence.DoubleQuoteString));
pragma(msg, "unesc:       "~doubleQuoteTestStr.unescape(EscapeSequence.DoubleQuoteString));

unittest
{
	Stdout.formatln("{}{}", "wchar:       ", unescapeDoubleQuoteString(`"They said \"10 \\ 5 = 2\""`w));
	Stdout.formatln("{}{}", "dchar:       ", unescapeDoubleQuoteString(`"They said \"10 \\ 5 = 2\""`d));
//	Stdout.formatln("{}{}", "int:         ", unescapeDoubleQuoteString([cast(int)1,2,3]));

	Stdout.formatln("{}{}", "orig:        ", doubleQuoteTestStr);
	Stdout.formatln("{}{}", "unesc:       ", unescapeDoubleQuoteString(doubleQuoteTestStr));
	Stdout.formatln("{}{}", "esc:         ", escapeDoubleQuoteString(doubleQuoteTestStr));
	Stdout.formatln("{}{}", "esc(unesc):  ", escapeDoubleQuoteString(unescapeDoubleQuoteString(doubleQuoteTestStr)));
	Stdout.formatln("{}{}", "unesc(esc):  ", unescapeDoubleQuoteString(escapeDoubleQuoteString(doubleQuoteTestStr)));
}
+/

private Layout!(char)  _sformatc;
private Layout!(wchar) _sformatw;
private Layout!(dchar) _sformatd;
static this()
{
	_sformatc = new Layout!( char)();
	_sformatw = new Layout!(wchar)();
	_sformatd = new Layout!(dchar)();
}

private T[] _sformat(T)(TypeInfo[] arguments, ArgList args, T[] formatStr)
{
	mixin(ensureCharType!("T", "_sformat"));

	static if(is(T==char))
		return _sformatc(arguments, args, formatStr);
	else static if(is(T==wchar))
		return _sformatw(arguments, args, formatStr);
	else
		return _sformatd(arguments, args, formatStr);
}

/// Suggested usage:
///   "Hello {}!".sformat("World");
T[] sformat(T)(T[] formatStr, ...)
{
	return _sformat!(T)(_arguments, _argptr, formatStr);
}

T[] sformatln(T)(T[] formatStr, ...)
{
	return _sformat!(T)(_arguments, _argptr, formatStr)~"\n";
}

T[] stripNonPrintable(T)(T[] str)
{
	T[] ret = str.dup;
	auto numRemaining = ret.removeIf( (T c){return !isPrintable(c);} );
	return ret[0..numRemaining];
}
