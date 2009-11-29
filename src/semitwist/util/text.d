// SemiTwist Library
// Written in the D programming language.

module semitwist.util.text;

import tango.core.Array;
import tango.io.Stdout;
import tango.text.Unicode;
import tango.text.Util;
import tango.text.convert.Layout;

import semitwist.util.ctfe;
import semitwist.util.mixins;

/**
Notes:
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

mixin(multiTypeString!("whitespaceChars", r" \n\r\t\v\f"));

bool startsWith(T)(T[] source, T[] match)
{
	return (source.locatePattern(match) == 0);
}

//TODO: test this
bool endsWith(T)(T[] source, T[] match)
{
	return (source.locatePatternPrior(match) == source.length - match.length);
}

/// Unix EOL: "\n"
void toUnixEOL(T)(ref T[] str)
{
	str = substitute(str, winEOL!(T)(),  unixEOL!(T)()); // Win  -> Unix
	str = substitute(str, mac9EOL!(T)(), unixEOL!(T)()); // Mac9 -> Unix
}

/// Mac9 EOL: "\r"
void toMac9EOL(T)(ref T[] str)
{
	str = substitute(str, winEOL!(T)(),  mac9EOL!(T)()); // Win  -> Mac9
	str = substitute(str, unixEOL!(T)(), mac9EOL!(T)()); // Unix -> Mac9
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
	version(OSX)     toUnixEOL(str);
	version(linux)   toUnixEOL(str);
	return str;
}

T[] toNativeEOLFromUnix(T)(T[] str)
{
	     version(Windows) return str.toNativeEOL();
	else return str;
}

T[] toNativeEOLFromWin(T)(T[] str)
{
	     version(OSX)   return str.toNativeEOL();
	else version(linux) return str.toNativeEOL();
	else return str;
}

T[] toNativeEOLFromMac9(T)(T[] str)
{
	return str.toNativeEOL();
}

enum EscapeSequence
{
	DDQS, // D Double Quote String, ex: `"foo\t"` <--> `foo	`
	
	//TODO: Implement these
	//HTML, // ex: `&amp;` <--> `&`
	//URI,  // ex: `%20` <--> ` `
	//SQL,  //TODO: Include different types of SQL escaping (SQL's about as standardized as BASIC)
}

/++
Note:
For the escape and unescape functions, chaining one with the other
(ex: "unescape(escape(str))") will result in a string that is
semantically equivalent to the original, but it is *not* necessarily
guaranteed to be exactly identical to the original string.

For example:
  char[] str;
  str = `"\x41\t"`;        // 0x41 is ASCII and UTF-8 for A
  str = unescapeDDQS(str); // == `A	` (That's an actual tab character)
  str = escapeDDQS(str);   // == `"A\t"c`

  Note that "\x41\t" and "A\t"c are equivalent, but not identical.
+/
T[] escape(T)(T[] str, EscapeSequence type)
{
	mixin(ensureCharType!("T"));

	T[] ret;
	
	switch(type)
	{
	case EscapeSequence.DDQS:
		ret = escapeDDQS(str);
		break;
		
	default:
		throw new Exception("Unsupported EscapeSequence");
	}
	
	return ret;
}

T[] unescape(T)(T[] str, EscapeSequence type)
{
	mixin(ensureCharType!("T"));

	T[] ret;
	
	switch(type)
	{
	case EscapeSequence.DDQS:
		ret = unescapeDDQS(str);
		break;
		
	default:
		throw new Exception("Unsupported EscapeSequence");
	}
	
	return ret;
}

T[] unescapeChar(T)(T[] str, T[] escapeSequence)
{
	mixin(ensureCharType!("T"));

	T[] ret = str.dup;
	ret = substitute(ret, escapeSequence, escapeSequence[$-1..$]);
	return ret;
}

/// Warning: This doesn't unescape all escape sequences yet.
T[] unescapeDDQS(T)(T[] str)
{
	mixin(ensureCharType!("T"));
	const char[] errStr = "str doesn't contain a valid D Double Quote String";

	if(str.length < 2)
		throw new Exception(errStr);
		
	T[] ret = str.dup;
	
	//TODO: Do this better
	ret = ctfe_substitute!(T)(ret, `\\`, `\`);
	ret = ctfe_substitute!(T)(ret, `\"`, `"`);
	ret = ctfe_substitute!(T)(ret, `\'`, `'`);

	ret = ctfe_substitute!(T)(ret, `\r`, "\r");
	ret = ctfe_substitute!(T)(ret, `\n`, "\n");
	ret = ctfe_substitute!(T)(ret, `\t`, "\t");

	ret = ctfe_substitute!(T)(ret, `\?`, "\?");
	ret = ctfe_substitute!(T)(ret, `\a`, "\a");
	ret = ctfe_substitute!(T)(ret, `\b`, "\b");
	ret = ctfe_substitute!(T)(ret, `\f`, "\f");
	ret = ctfe_substitute!(T)(ret, `\v`, "\v");
	//TODO: All the others

	if(ret[0..1] != `"`)
		throw new Exception(errStr);
	
	auto last = ret[$-1..$];
	auto secondLast = ret[$-2..$-1];
	
	if(last != `"`)
	{
		if(secondLast != `"`)
			throw new Exception(errStr);
		else if(secondLast != "c" && secondLast != "w" && secondLast != "d")
			throw new Exception(errStr);
		else
			return ret[1..$-2];
	}
	
	return ret[1..$-1];
}

T[] escapeDDQS(T)(T[] str)
{
	mixin(ensureCharType!("T"));
		
	T[] ret = str.dup;
	
	ret = ctfe_substitute!(T)(ret, `\`, `\\`);
	ret = ctfe_substitute!(T)(ret, `"`, `\"`);
	ret = ctfe_substitute!(T)(ret, "\r", `\r`); // To prevent accidential conversions to platform-specific EOL
	ret = ctfe_substitute!(T)(ret, "\n", `\n`); // To prevent accidential conversions to platform-specific EOL
	ret = ctfe_substitute!(T)(ret, "\t", `\t`); // To prevent possible problems with automatic tab->space conversion
	// The rest don't need to be escaped
	
	//TODO? Use this suffix
	/+
	static if(is(T==char))
		const T[] suffix = "c";
	else static if(is(T==wchar))
		const T[] suffix = "w";
	else static if(is(T==dchar))
		const T[] suffix = "d";
		
	return `"`~ret~`"`~suffix;
	+/
	
	return `"`~ret~`"`;
}

/+
const char[] doubleQuoteTestStr = `"They said \"10 \\ 5 = 2\""`;

pragma(msg, "orig:        "~doubleQuoteTestStr);
pragma(msg, "unesc:       "~unescapeDDQS(doubleQuoteTestStr));
pragma(msg, "esc:         "~escapeDDQS(doubleQuoteTestStr));
pragma(msg, "esc(unesc):  "~escapeDDQS(unescapeDDQS(doubleQuoteTestStr)));
pragma(msg, "unesc(esc):  "~unescapeDDQS(escapeDDQS(doubleQuoteTestStr)));

pragma(msg, "unesc:       "~unescape(doubleQuoteTestStr, EscapeSequence.DDQS));
pragma(msg, "unesc:       "~doubleQuoteTestStr.unescape(EscapeSequence.DDQS));

unittest
{
	const wchar[] ctEscW = escapeDDQS(`"They said \"10 \\ 5 = 2\""`w);
	const dchar[] ctEscD = escapeDDQS(`"They said \"10 \\ 5 = 2\""`d);
	const wchar[] ctUnescW = unescapeDDQS(`"They said \"10 \\ 5 = 2\""`w);
	const dchar[] ctUnescD = unescapeDDQS(`"They said \"10 \\ 5 = 2\""`d);
	Stdout.formatln("{}{}", "ctEscW:      ", ctEscW);
	Stdout.formatln("{}{}", "ctEscD:      ", ctEscD);
	Stdout.formatln("{}{}", "ctUnescW:    ", ctUnescW);
	Stdout.formatln("{}{}", "ctUnescD:    ", ctUnescD);

	Stdout.formatln("{}{}", "unesc wchar: ", unescapeDDQS(`"They said \"10 \\ 5 = 2\""`w));
	Stdout.formatln("{}{}", "unesc dchar: ", unescapeDDQS(`"They said \"10 \\ 5 = 2\""`d));
	Stdout.formatln("{}{}", "esc wchar:   ", escapeDDQS(`"They said \"10 \\ 5 = 2\""`w));
	Stdout.formatln("{}{}", "esc dchar:   ", escapeDDQS(`"They said \"10 \\ 5 = 2\""`d));
//	Stdout.formatln("{}{}", "int:         ", unescapeDDQS([cast(int)1,2,3]));

	Stdout.formatln("{}{}", "orig:        ", doubleQuoteTestStr);
	Stdout.formatln("{}{}", "unesc:       ", unescapeDDQS(doubleQuoteTestStr));
	Stdout.formatln("{}{}", "esc:         ", escapeDDQS(doubleQuoteTestStr));
	Stdout.formatln("{}{}", "esc(unesc):  ", escapeDDQS(unescapeDDQS(doubleQuoteTestStr)));
	Stdout.formatln("{}{}", "unesc(esc):  ", unescapeDDQS(escapeDDQS(doubleQuoteTestStr)));
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
	mixin(ensureCharType!("T"));

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
