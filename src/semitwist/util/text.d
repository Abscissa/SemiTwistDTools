// SemiTwist Library
// Written in the D programming language.

module semitwist.util.text;

import std.algorithm;
import std.array;
//import tango.core.Array;
import std.stdio;//tango.io.Stdout;
//import tango.text.Unicode;
//import tango.text.Util;
//import tango.text.convert.Layout;
//import tango.text.convert.Utf;
//import tango.util.Convert;
import std.traits;
import std.string;

import semitwist.util.all;
import semitwist.util.compat.all;

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
template multiTypeString(string name, string data, string access="public")
{
	const string multiTypeString = 
	access~" T[] "~name~"(T)()"~
	"{"~
	"		 static if(is(T ==  char)) { return \""~data~"\"c; }"~
	"	else static if(is(T == wchar)) { return \""~data~"\"w; }"~
	"	else static if(is(T == dchar)) { return \""~data~"\"d; }"~
	"	else static assert(\"T must be char, wchar, or dchar\");"~
	"}";
}

/// Warning: This is missing some unicode whitespace chars
mixin(multiTypeString!("whitespaceChars", r" \n\r\t\v\f"));

/+bool startsWith(T)(T[] source, T[] match)
{
	if(source.length == 0)
		return match.length == 0;
		
	return (source.locatePattern(match) == 0);
}

//TODO: test this
bool endsWith(T)(T[] source, T[] match)
{
	return (source.locatePatternPrior(match) == source.length - match.length);
}+/

/// Unix EOL: "\n"
void toUnixEOL(T)(ref T[] str)
{
	str = substitute(str, to!(T[])(nlStr_Windows), to!(T[])(nlStr_Linux)); // Win  -> Unix
	str = substitute(str, to!(T[])(nlStr_Mac9),    to!(T[])(nlStr_Linux)); // Mac9 -> Unix
}

/// Mac9 EOL: "\r"
void toMac9EOL(T)(ref T[] str)
{
	str = substitute(str, to!(T[])(nlStr_Windows), to!(T[])(nlStr_Mac9)); // Win  -> Mac9
	str = substitute(str, to!(T[])(nlStr_Linux),   to!(T[])(nlStr_Mac9)); // Unix -> Mac9
}

/// Win EOL: "\r\n"
void toWinEOL(T)(ref T[] str)
{
	toUnixEOL(str); // All -> Unix
	str = substitute(str, to!(T[])(nlStr_Linux), to!(T[])(nlStr_Windows)); // Unix -> Win
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
  string str;
  str = `"\x41\t"`;        // 0x41 is ASCII and UTF-8 for A
  str = unescapeDDQS(str); // == `A	` (That's an actual tab character)
  str = escapeDDQS(str);   // == `"A\t"c`

  Note that "\x41\t" and "A\t"c are equivalent, but not identical.
+/
T escape(T)(T str, EscapeSequence type) if(isSomeString!T)
{
	//mixin(ensureCharType!("T"));

	T ret;
	
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

T unescape(T)(T str, EscapeSequence type) if(isSomeString!T)
{
	//mixin(ensureCharType!("T"));

	T ret;
	
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

T unescapeChar(T)(T str, T escapeSequence) if(isSomeString!T)
{
	//mixin(ensureCharType!("T"));

	T ret = str.dup;
	ret = substitute(ret, escapeSequence, escapeSequence[$-1..$]);
	return ret;
}

/// Warning: This doesn't unescape all escape sequences yet.
T unescapeDDQS(T)(T str) if(isSomeString!T)
{
	//mixin(ensureCharType!("T"));
	const string errStr = "str doesn't contain a valid D Double Quote String";

	if(str.length < 2)
		throw new Exception(errStr);
		
	T ret = str;//.dup;
	
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

T escapeDDQS(T)(T str) if(isSomeString!T)
{
//	mixin(ensureCharType!("T"));
		
	T ret = str;
	
	ret = ctfe_substitute!(T)(ret, `\`, `\\`);
	ret = ctfe_substitute!(T)(ret, `"`, `\"`);
	ret = ctfe_substitute!(T)(ret, "\r", `\r`); // To prevent accidential conversions to platform-specific EOL
	ret = ctfe_substitute!(T)(ret, "\n", `\n`); // To prevent accidential conversions to platform-specific EOL
	ret = ctfe_substitute!(T)(ret, "\t", `\t`); // To prevent possible problems with automatic tab->space conversion
	// The rest don't need to be escaped
	
	return `"`~ret~`"`;
}

/+
const string doubleQuoteTestStr = `"They said \"10 \\ 5 = 2\""`;

pragma(msg, "orig:        "~doubleQuoteTestStr);
pragma(msg, "unesc:       "~unescapeDDQS(doubleQuoteTestStr));
pragma(msg, "esc:         "~escapeDDQS(doubleQuoteTestStr));
pragma(msg, "esc(unesc):  "~escapeDDQS(unescapeDDQS(doubleQuoteTestStr)));
pragma(msg, "unesc(esc):  "~unescapeDDQS(escapeDDQS(doubleQuoteTestStr)));

pragma(msg, "unesc:       "~unescape(doubleQuoteTestStr, EscapeSequence.DDQS));
pragma(msg, "unesc:       "~doubleQuoteTestStr.unescape(EscapeSequence.DDQS));

unittest
{
	const wstring ctEscW = escapeDDQS(`"They said \"10 \\ 5 = 2\""`w);
	const dstring ctEscD = escapeDDQS(`"They said \"10 \\ 5 = 2\""`d);
	const wstring ctUnescW = unescapeDDQS(`"They said \"10 \\ 5 = 2\""`w);
	const dstring ctUnescD = unescapeDDQS(`"They said \"10 \\ 5 = 2\""`d);
	writefln("%s%s", "ctEscW:      ", ctEscW);
	writefln("%s%s", "ctEscD:      ", ctEscD);
	writefln("%s%s", "ctUnescW:    ", ctUnescW);
	writefln("%s%s", "ctUnescD:    ", ctUnescD);

	writefln("%s%s", "unesc wchar: ", unescapeDDQS(`"They said \"10 \\ 5 = 2\""`w));
	writefln("%s%s", "unesc dchar: ", unescapeDDQS(`"They said \"10 \\ 5 = 2\""`d));
	writefln("%s%s", "esc wchar:   ", escapeDDQS(`"They said \"10 \\ 5 = 2\""`w));
	writefln("%s%s", "esc dchar:   ", escapeDDQS(`"They said \"10 \\ 5 = 2\""`d));
//	writefln("%s%s", "int:         ", unescapeDDQS([cast(int)1,2,3]));

	writefln("%s%s", "orig:        ", doubleQuoteTestStr);
	writefln("%s%s", "unesc:       ", unescapeDDQS(doubleQuoteTestStr));
	writefln("%s%s", "esc:         ", escapeDDQS(doubleQuoteTestStr));
	writefln("%s%s", "esc(unesc):  ", escapeDDQS(unescapeDDQS(doubleQuoteTestStr)));
	writefln("%s%s", "unesc(esc):  ", unescapeDDQS(escapeDDQS(doubleQuoteTestStr)));
}
+/

int locate(Char)(in Char[] s, dchar c, CaseSensitive cs = CaseSensitive.yes)
{
	auto result = indexOf(s, c, cs);
	return result == -1? s.length : result;
}

int locatePrior(in char[] s, dchar c, CaseSensitive cs = CaseSensitive.yes)
{
	auto result = lastIndexOf(s, c, cs);
	return result == -1? s.length : result;
}

int locate(Char1, Char2)(in Char1[] s, in Char2[] sub, CaseSensitive cs = CaseSensitive.yes)
{
	auto result = indexOf(s, sub, cs);
	return result == -1? s.length : result;
}

int locatePrior(in char[] s, in char[] sub, CaseSensitive cs = CaseSensitive.yes)
{
	auto result = lastIndexOf(s, sub, cs);
	return result == -1? s.length : result;
}

/// Suggested usage:
///   "Hello %s!".formatln("World");
string formatln(T...)(T args)
{
	return format(args)~"\n";
}

T stripNonPrintable(T)(T str) if(isSomeString!T)
{
	T ret = str.dup;
	auto numRemaining = ret.removeIf( (T c){return !isPrintable(c);} );
	return ret[0..numRemaining];
}

/// Return value is number of code units
uint nextCodePointSize(T)(T str) if(is(T==string) || is(T==wstring))
{
	uint ret;
	str.decode(ret);
	return ret;
}

T indent(T)(T str, T indentStr="\t") if(isSomeString!T)
{
	if(str == "")
		return indentStr;
		
	return
		indentStr ~
		str[0..$-1].replace("\n", "\n"~indentStr) ~
		str[$-1];
}

T unindent(T)(T str) if(isSomeString!T)
{
	if(str == "")
		return "";
		
	T[] lines;
	if(__ctfe)
		lines = str.ctfe_split("\n");
	else
		lines = str.split("\n");
	
	bool isNonWhite(dchar ch)
	{
		if(__ctfe)
			return !ctfe_iswhite(ch);
		else
			return !iswhite(ch);
	}
	T leadingWhiteOf(T str)
		{ return str[ 0 .. $-find!(isNonWhite)(str).length ]; }
	
	// Apply leadingWhiteOf, but emit null instead for whitespace-only lines
	T[] indents;
	if(__ctfe)
		indents = semitwist.util.functional.map( lines,
			(T str){ return str.strip()==""? null : leadingWhiteOf(str);}
		);
	else
		indents = array( std.algorithm.map!(
			(T str){ return str.strip()==""? null : leadingWhiteOf(str);}
			)(lines) );

	T shorterAndNonNull(T a, T b) {
		if(a is null) return b;
		if(b is null) return a;
		
		return (a.length < b.length)? a : b;
	};
	auto shortestIndent = std.algorithm.reduce!(shorterAndNonNull)(indents);
	
	if(shortestIndent is null || shortestIndent == "")
		return str.stripl();
		
	foreach(i; 0..lines.length)
	{
		if(indents[i] is null)
			lines[i] = "";
		else if(indents.startsWith(shortestIndent))
			lines[i] = lines[i][shortestIndent.length..$];
		else
		{
			if(__ctfe)
				assert(false, "Inconsistent indentation");
			else
				throw new Exception("Inconsistent indentation");
		}
	}
	
	if(__ctfe)
		return lines.ctfe_join("\n");
	else
		return lines.join("\n");
}

unittest
{
	// escapeDDQS, unescapeDDQS
	mixin(deferEnsure!(q{ `hello`.escapeDDQS()     }, q{ _ == `"hello"` }));
	mixin(deferEnsure!(q{ `"hello"`.unescapeDDQS() }, q{ _ == "hello"   }));
	mixin(deferEnsure!(q{ `"I"`.unescapeDDQS()     }, q{ _ == "I"       }));
	
	mixin(deferEnsure!(q{ (`And...`~"\n"~`sam\nick said "Hi!".`).escapeDDQS()  }, q{ _ == `"And...\nsam\\nick said \"Hi!\"."`  }));
	//TODO: Make this one pass
	//mixin(deferEnsure!(q{ `"And...\nsam\\nick said \"Hi!\"."`.unescapeDDQS() }, q{ _ == `And...`~"\n"~`sam\nick said "Hi!".` }));
	mixin(deferEnsureThrows!(q{ "hello".unescapeDDQS(); }, Exception));

	// indent
	mixin(deferEnsure!(q{ "A\n\tB\n\nC".indent("  ") }, q{ _ == "  A\n  \tB\n  \n  C" }));
	mixin(deferEnsure!(q{ "A\nB\n".indent("\t")      }, q{ _ == "\tA\n\tB\n"          }));
	mixin(deferEnsure!(q{ "".indent("\t")            }, q{ _ == "\t"                  }));
	mixin(deferEnsure!(q{ "A".indent("\t")           }, q{ _ == "\tA"                 }));
	mixin(deferEnsure!(q{ "A\n\tB\n\nC".indent("")   }, q{ _ == "A\n\tB\n\nC"         }));

	// unindent
	mixin(deferEnsure!(q{ " \t A\n \t \tB\n \t C\n  \t\n \t D".unindent() }, q{ _ == "A\n\tB\nC\n\nD" }));
	mixin(deferEnsure!(q{ " D\n".unindent()    }, q{ _ == "D\n" }));
	mixin(deferEnsure!(q{ " D\n ".unindent()   }, q{ _ == "D\n" }));
	mixin(deferEnsure!(q{ "D".unindent()       }, q{ _ == "D"   }));
	mixin(deferEnsure!(q{ "".unindent()        }, q{ _ == ""    }));
	mixin(deferEnsure!(q{ " ".unindent()       }, q{ _ == ""    }));
	mixin(deferEnsureThrows!(q{ " \tA\n\t B".unindent(); }, Exception));
	mixin(deferEnsureThrows!(q{ "  a\n \tb".unindent();    }, Exception));

	// unindent at compile-time
	enum ctfe_unindent_dummy1 = " \t A\n \t \tB\n \t C\n  \t\n \t D".unindent();
	enum ctfe_unindent_dummy2 = " D".unindent();
	enum ctfe_unindent_dummy3 = " D\n".unindent();
	enum ctfe_unindent_dummy4 = "".unindent();

	mixin(deferEnsure!(q{ ctfe_unindent_dummy1 }, q{ _ == "A\n\tB\nC\n\nD" }));
	mixin(deferEnsure!(q{ ctfe_unindent_dummy2 }, q{ _ == "D"   }));
	mixin(deferEnsure!(q{ ctfe_unindent_dummy3 }, q{ _ == "D\n" }));
	mixin(deferEnsure!(q{ ctfe_unindent_dummy4 }, q{ _ == ""    }));
	
	//enum ctfe_unindent_dummy5 = "  a\n \tb".unindent(); // Should fail to compile
}
