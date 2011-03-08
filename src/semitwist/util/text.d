// SemiTwist Library
// Written in the D programming language.

module semitwist.util.text;

import std.algorithm;
import std.array;
import std.conv;
import std.md5;
import std.stdio;
import std.traits;
import std.stream;
import std.string;
import std.system;
import std.utf;

public import std.stream: BOM;

import semitwist.util.all;

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

/// Unix EOL: "\n"
void toUnixEOL(T)(ref T[] str)
{
	str = replace(str, to!(T[])(nlStr_Windows), to!(T[])(nlStr_Linux)); // Win  -> Unix
	str = replace(str, to!(T[])(nlStr_Mac9),    to!(T[])(nlStr_Linux)); // Mac9 -> Unix
}

/// Mac9 EOL: "\r"
void toMac9EOL(T)(ref T[] str)
{
	str = replace(str, to!(T[])(nlStr_Windows), to!(T[])(nlStr_Mac9)); // Win  -> Mac9
	str = replace(str, to!(T[])(nlStr_Linux),   to!(T[])(nlStr_Mac9)); // Unix -> Mac9
}

/// Win EOL: "\r\n"
void toWinEOL(T)(ref T[] str)
{
	toUnixEOL(str); // All -> Unix
	str = replace(str, to!(T[])(nlStr_Linux), to!(T[])(nlStr_Windows)); // Unix -> Win
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

mixin(unittestSemiTwistDLib("Outputting some things", q{
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
}));
+/

/// Like std.string.indexOf, but with an optional 'start' parameter,
/// and returns s.length when not found (instead of -1).
//TODO*: Unittest these
int locate(Char)(in Char[] s, dchar c, int start=0, CaseSensitive cs = CaseSensitive.yes)
{
	auto index = std.string.indexOf(s[start..$], c, cs);
	return (index == -1)? s.length : index + start;
}

/// ditto
int locatePrior(Char)(in Char[] s, dchar c, int start=int.max, CaseSensitive cs = CaseSensitive.yes)
{
	if(start > s.length)
		start = s.length;
		
	auto index = std.string.lastIndexOf(s[0..start], c, cs);
	return (index == -1)? s.length : index;
}

/// ditto
int locate(Char1, Char2)(in Char1[] s, in Char2[] sub, int start=0, CaseSensitive cs = CaseSensitive.yes)
{
	auto index = std.string.indexOf(s[start..$], sub, cs);
	return (index == -1)? s.length : index + start;
}

/// ditto
int locatePrior(Char1, Char2)(in Char1[] s, in Char2[] sub, int start=int.max, CaseSensitive cs = CaseSensitive.yes)
{
	if(start > s.length)
		start = s.length;
		
	auto index = std.string.lastIndexOf(s[0..start], sub, cs);
	return (index == -1)? s.length : index;
}

/// Suggested usage:
///   "Hello %s!".formatln("World");
string formatln(T...)(T args)
{
	return format(args)~"\n";
}

//TODO*: Fix stripNonPrintable
T stripNonPrintable(T)(T str) if(isSomeString!T)
{
	//T ret = str.dup;
	//auto numRemaining = ret.removeIf( (T c){return !isPrintable(c);} );
	//return ret[0..numRemaining];
	return str;
}

/// Return value is number of code units
uint nextCodePointSize(T)(T str) if(is(T==string) || is(T==wstring))
{
	uint ret;
	str.decode(ret);
	return ret;
}

/// Indents every line with indentStr
T indent(T)(T str, T indentStr="\t") if(isSomeString!T)
{
	if(str == "")
		return indentStr;
		
	return
		indentStr ~
		str[0..$-1].replace("\n", "\n"~indentStr) ~
		str[$-1];
}

/// ditto
T[] indent(T)(T[] lines, T indentStr="\t") if(isSomeString!T)
{
	// foreach(ref) doesn't work right at compile time: DMD Issue #3835
	foreach(i, line; lines)
		lines[i] = indentStr ~ line;
		
	return lines;
}

/// Unindents the lines of text as much as possible while preserving
/// all relative indentation.
///
/// Inconsistent indentation (on like that contain non-whitespace) is an error
/// and throws an exception at runtime, or asserts when executed at compile-time.
T unindent(T)(T str) if(isSomeString!T)
{
	if(str == "")
		return "";
		
	T[] lines;
	if(__ctfe)
		lines = str.ctfe_split("\n");
	else
		lines = str.split("\n");
	
	lines = unindentImpl(lines, str);
	
	if(__ctfe)
		return lines.ctfe_join("\n");
	else
		return lines.join("\n");
}

/// ditto
T[] unindent(T)(T[] lines) if(isSomeString!T)
{
	return unindentImpl(lines);
}

private T[] unindentImpl(T)(T[] lines, T origStr=null) if(isSomeString!T)
{
	if(lines == [])
		return [];
		
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
	{
		if(origStr == null)
			return stripLinesLeft(lines);
		else
			return [origStr.stripl()];
	}
		
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
	
	return lines;
}

T stripLinesTop(T)(T str) if(isSomeString!T)
{
	return stripLinesBox_StrImpl!(T, true, false, false, false)(str);
}
T stripLinesBottom(T)(T str) if(isSomeString!T)
{
	return stripLinesBox_StrImpl!(T, false, true, false, false)(str);
}
T stripLinesTopBottom(T)(T str) if(isSomeString!T)
{
	return stripLinesBox_StrImpl!(T, true, true, false, false)(str);
}

T stripLinesLeft(T)(T str) if(isSomeString!T)
{
	return stripLinesBox_StrImpl!(T, false, false, true, false)(str);
}
T stripLinesRight(T)(T str) if(isSomeString!T)
{
	return stripLinesBox_StrImpl!(T, false, false, false, true)(str);
}
T stripLinesLeftRight(T)(T str) if(isSomeString!T)
{
	return stripLinesBox_StrImpl!(T, false, false, true, true)(str);
}

T stripLinesBox(T)(T str) if(isSomeString!T)
{
	return stripLinesBox_StrImpl!(T, true, true, true, true)(str);
}

private T stripLinesBox_StrImpl
	(T, bool stripTop, bool stripBottom, bool stripLeft, bool stripRight)
	(T str)
	if(isSomeString!T)
{
	if(str == "")
		return "";
		
	T[] lines;
	if(__ctfe)
		lines = str.ctfe_split("\n");
	else
		lines = str.split("\n");

	lines = stripLinesBox_LineImpl!(T, stripTop, stripBottom, stripLeft, stripRight)(lines);
	
	if(__ctfe)
		return lines.ctfe_join("\n");
	else
		return lines.join("\n");
}

private T[] stripLinesBox_LineImpl
	(T, bool stripTop, bool stripBottom, bool stripLeft, bool stripRight)
	(T[] lines)
	if(isSomeString!T)
{
	static if(stripTop)    lines = stripLinesTop(lines);
	static if(stripBottom) lines = stripLinesBottom(lines);
	
	static if(stripLeft && stripRight)
	{
		lines = stripLinesLeftRight(lines);
	}
	else
	{
		static if(stripLeft)  lines = stripLinesLeft(lines);
		static if(stripRight) lines = stripLinesRight(lines);
	}
	
	return lines;
}

T[] stripLinesBox(T)(T[] str) if(isSomeString!T)
{
	return stripLinesBox_LineImpl!(T, true, true, true, true)(str);
}

T[] stripLinesTop(T)(T[] lines) if(isSomeString!T)
{
	int firstLine = lines.length-1;

	foreach(i, line; lines)
	if(line.strip() != "")
	{
		firstLine = i;
		break;
	}

	return lines[firstLine..$];
}

T[] stripLinesBottom(T)(T[] lines) if(isSomeString!T)
{
	int lastLine = 0;

	foreach_reverse(i, line; lines)
	if(line.strip() != "")
	{
		lastLine = i;
		break;
	}

	return lines[0..lastLine+1];
}

T[] stripLinesTopBottom(T)(T[] lines) if(isSomeString!T)
{
	lines = stripLinesTop(lines);
	lines = stripLinesBottom(lines);
	return lines;
}

T[] stripLinesLeft(T)(T[] lines) if(isSomeString!T)
{
	// foreach(ref) doesn't work right at compile time: DMD Issue #3835
	foreach(i, line; lines)
		lines[i] = line.stripl();
		
	return lines;
}

T[] stripLinesRight(T)(T[] lines) if(isSomeString!T)
{
	// foreach(ref) doesn't work right at compile time: DMD Issue #3835
	foreach(i, line; lines)
		lines[i] = line.stripr();
		
	return lines;
}

T[] stripLinesLeftRight(T)(T[] lines) if(isSomeString!T)
{
	// foreach(ref) doesn't work right at compile time: DMD Issue #3835
	foreach(i, line; lines)
		lines[i] = line.strip();
	
	return lines;
}

//TODO*: Unittest this
bool contains(T1,T2)(T1 haystack, T2 needle)
{
	return std.algorithm.find(haystack, needle) != [];
}

/++
Unindents, strips whitespace-only lines from top and bottom,
and strips trailing whitespace from eash line.
(Also converts Windows "\r\n" line endings to Unix "\n" line endings.)

See also the documentation for unindent().

Good for making easily-readable multi-line string literals without
leaving extra indents and whitespace in the resulting string:

Do this:
--------------------
void foo()
{
	enum codeStr = q{
		// Written in the D Programming Langauge
		// by John Doe

		int main()
		{
			return 0;
		}
	}.normalize();
}
--------------------

Instead of this:
--------------------
void foo()
{
	enum codeStr = 
q{// Written in the D Programming Langauge
// by John Doe

int main()
{
	return 0;
}};
}
--------------------

The resulting string is exactly the same.
+/
T normalize(T)(T str) if(isSomeString!T)
{
	if(str == "")
		return "";
		
	T[] lines;
	if(__ctfe)
		lines = str.ctfe_split("\n");
	else
		lines = str.split("\n");

	lines = normalize(lines);
	
	if(__ctfe)
		return lines.ctfe_join("\n");
	else
		return lines.join("\n");
}

/// ditto
T[] normalize(T)(T[] lines) if(isSomeString!T)
{
	lines = stripLinesTopBottom(lines);
	lines = unindent(lines);
	lines = stripLinesRight(lines);
	return lines;
}

string md5(string data)
{
	MD5_CTX context;
	context.start();
	context.update(data);
	ubyte digest[16];
	context.finish(digest);
	
	return digestToString(digest);
}

immutable(ubyte)[] bomCodeOf(BOM bom)
{
	final switch(bom)
	{
	case BOM.UTF8:    return cast(immutable(ubyte)[])x"EF BB BF";
	case BOM.UTF16LE: return cast(immutable(ubyte)[])x"FF FE";
	case BOM.UTF16BE: return cast(immutable(ubyte)[])x"FE FF";
	case BOM.UTF32LE: return cast(immutable(ubyte)[])x"FF FE 00 00";
	case BOM.UTF32BE: return cast(immutable(ubyte)[])x"00 00 FE FF";
	}
}

BOM bomOf(const(ubyte)[] str)
{
	if(str.startsWith(bomCodeOf(BOM.UTF8   ))) return BOM.UTF8;
	if(str.startsWith(bomCodeOf(BOM.UTF16LE))) return BOM.UTF16LE;
	if(str.startsWith(bomCodeOf(BOM.UTF16BE))) return BOM.UTF16BE;
	if(str.startsWith(bomCodeOf(BOM.UTF32LE))) return BOM.UTF32LE;
	if(str.startsWith(bomCodeOf(BOM.UTF32BE))) return BOM.UTF32BE;
	
	return BOM.UTF8;
}

version(LittleEndian)
{
	enum BOM native16BitBOM    = BOM.UTF16LE;
	enum BOM native32BitBOM    = BOM.UTF32LE;
	enum BOM nonNative16BitBOM = BOM.UTF16BE;
	enum BOM nonNative32BitBOM = BOM.UTF32BE;
}
else
{
	enum BOM native16BitBOM    = BOM.UTF16BE;
	enum BOM native32BitBOM    = BOM.UTF32BE;
	enum BOM nonNative16BitBOM = BOM.UTF16LE;
	enum BOM nonNative32BitBOM = BOM.UTF32LE;
}

bool isNativeEndian(BOM bom)
{
	return bom == native16BitBOM || bom == native32BitBOM || bom == BOM.UTF8;
}

bool isNonNativeEndian(BOM bom)
{
	return !isNativeEndian(bom);
}

bool is8Bit(BOM bom)
{
	return bom == BOM.UTF8;
}

bool is16Bit(BOM bom)
{
	return bom == native16BitBOM || bom == nonNative16BitBOM;
}

bool is32Bit(BOM bom)
{
	return bom == native32BitBOM || bom == nonNative32BitBOM;
}

Endian endianOf(BOM bom)
{
	final switch(bom)
	{
	case BOM.UTF8: return endian;
	case BOM.UTF16LE, BOM.UTF32LE: return Endian.LittleEndian;
	case BOM.UTF16BE, BOM.UTF32BE: return Endian.BigEndian;
	}
}

template isInsensitive(T)
{
	enum isInsensitive =
		is(T==InsensitiveT!string ) ||
		is(T==InsensitiveT!wstring) ||
		is(T==InsensitiveT!dstring);
}
static assert(isInsensitive!Insensitive);
static assert(isInsensitive!WInsensitive);
static assert(isInsensitive!DInsensitive);
static assert(!isInsensitive!string);

struct InsensitiveT(T) if(isSomeString!T)
{
	private T str;
	private T foldingCase;
	
	this(T newStr)
	{
		str = newStr;
		updateFoldingCase();
	}
	
	T toString()
	{
		return str;
	}
	
	private void updateFoldingCase()
	{
		// Phobos doesn't actually have a tofolding() yet
		foldingCase = tolower(str);
	}
	
	const hash_t toHash()
	{
		return typeid(string).getHash(&foldingCase);
	}
	
	void opAssign(T2)(T2 b) if(isInsensitive!T2 || isSomeString!T2)
	{
		static if(is(isInsensitive!T == T2))
		{
			str = b.str;
			foldingCase = newStr.foldingCase;
		}
		else static if(isInsensitive!T2)
		{
			str = to!T(b.str);
			updateFoldingCase();
		}
		else
		{
			str = b;
			updateFoldingCase();
		}
	}
	
	InsensitiveT!T opBinary(string op)(InsensitiveT!T b) if(op=="~")
	{
		return InsensitiveT!T(str ~ b.str);
	}
	
	InsensitiveT!T opOpAssign(string op)(ref InsensitiveT!T b) if(op=="~")
	{
		str ~= b.str;
		foldingCase ~= b.foldingCase;
		return this;
	}
	
	const bool opEquals(ref const InsensitiveT!T b)
	{
		/+if (str is b.str) return true;
		if (str is null || b.str is null) return false;
		return foldingCase == b.foldingCase;+/
		return this.opCmp(b) == 0;
	}
	
	const int opCmp(ref const InsensitiveT!T b)
	{
		if (str   is b.str) return 0;
		if (str   is null ) return -1;
		if (b.str is null ) return 1;
		return std.string.cmp(foldingCase, b.foldingCase);
	}
	
    InsensitiveT!T opSlice()
	{
		return this;
	}

    auto opSlice(size_t x)
	{
		return str[x];
	}

    InsensitiveT!T opSlice(size_t x, size_t y)
	{
		return InsensitiveT!T(str[x..y]);
	}
}

alias InsensitiveT!string  Insensitive;
alias InsensitiveT!wstring WInsensitive;
alias InsensitiveT!dstring DInsensitive;

mixin(unittestSemiTwistDLib(q{

	// Insensitive
	mixin(deferAssert!(q{ Insensitive("TEST") == Insensitive("Test") }));
	mixin(deferAssert!(q{ Insensitive("TEST") == Insensitive("TEST") }));
	mixin(deferAssert!(q{ Insensitive("TEST") != Insensitive("ABCD") }));
	mixin(deferAssert!(q{ Insensitive("TEST") != Insensitive(null)   }));
	mixin(deferAssert!(q{ Insensitive(null)   == Insensitive(null)   }));
	mixin(deferAssert!(q{ Insensitive("Test") == Insensitive("TEST") }));
	mixin(deferAssert!(q{ Insensitive("ABCD") != Insensitive("TEST") }));
	mixin(deferAssert!(q{ Insensitive(null)   != Insensitive("TEST") }));

	mixin(deferAssert!(q{ Insensitive("TEST")[1..3] == Insensitive("ES") }));
	mixin(deferAssert!(q{ Insensitive("TEST")[1..3] == Insensitive("es") }));
	mixin(deferAssert!(q{ Insensitive("TEST")[1..3] != Insensitive("AB") }));

	mixin(deferAssert!(q{ Insensitive("TE")~Insensitive("ST") == Insensitive("TesT") }));
	
	Insensitive ins;
	ins = Insensitive("TEST");
	ins = "ab";
	ins ~= Insensitive("cd");

	mixin(deferAssert!(q{ ins == Insensitive("AbcD") }));
	
	int[Insensitive] ins_aa = [Insensitive("ABC"):1, Insensitive("DEF"):2, Insensitive("Xyz"):3];
	mixin(deferAssert!(q{ Insensitive("ABC") in ins_aa }));
	mixin(deferAssert!(q{ Insensitive("DEF") in ins_aa }));
	mixin(deferAssert!(q{ Insensitive("Xyz") in ins_aa }));
	mixin(deferAssert!(q{ Insensitive("aBc") in ins_aa }));
	mixin(deferAssert!(q{ Insensitive("dEf") in ins_aa }));
	mixin(deferAssert!(q{ Insensitive("xYZ") in ins_aa }));
	mixin(deferAssert!(q{ Insensitive("HI") !in ins_aa }));
	
	mixin(deferAssert!(q{ ins_aa[Insensitive("aBc")] == 1 }));
	mixin(deferAssert!(q{ ins_aa[Insensitive("dEf")] == 2 }));
	mixin(deferAssert!(q{ ins_aa[Insensitive("xYZ")] == 3 }));

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
	
	// contains
	mixin(deferEnsure!(q{ contains!char("abcde", 'a') }, q{ _==true  }));
	mixin(deferEnsure!(q{ contains!char("abcde", 'c') }, q{ _==true  }));
	mixin(deferEnsure!(q{ contains!char("abcde", 'e') }, q{ _==true  }));
	mixin(deferEnsure!(q{ contains!char("abcde", 'x') }, q{ _==false }));

	// stripLines: Top and Bottom
	mixin(deferEnsure!(q{ " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesTop()       }, q{ _ == " ABC \n \n DEF \n \t \n\t \n" }));
	mixin(deferEnsure!(q{ " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesBottom()    }, q{ _ == " \t \n\t \n ABC \n \n DEF "   }));
	mixin(deferEnsure!(q{ " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesTopBottom() }, q{ _ == " ABC \n \n DEF "              }));

	mixin(deferEnsure!(q{ "\nABC\n ".stripLinesTop()       }, q{ _ == "ABC\n " }));
	mixin(deferEnsure!(q{ "\nABC\n ".stripLinesBottom()    }, q{ _ == "\nABC"  }));
	mixin(deferEnsure!(q{ "\nABC\n ".stripLinesTopBottom() }, q{ _ == "ABC"    }));

	mixin(deferEnsure!(q{ "\n".stripLinesTop()       }, q{ _ == "" }));
	mixin(deferEnsure!(q{ "\n".stripLinesBottom()    }, q{ _ == "" }));
	mixin(deferEnsure!(q{ "\n".stripLinesTopBottom() }, q{ _ == "" }));

	mixin(deferEnsure!(q{ "ABC".stripLinesTopBottom()      }, q{ _ == "ABC" }));
	mixin(deferEnsure!(q{ "".stripLinesTopBottom()         }, q{ _ == ""    }));

	// stripLines: Left and Right
	mixin(deferEnsure!(q{ " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesLeft()      }, q{ _ == "\n\nABC \n\nDEF \n\n\n" }));
	mixin(deferEnsure!(q{ " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesRight()     }, q{ _ == "\n\n ABC\n\n DEF\n\n\n" }));
	mixin(deferEnsure!(q{ " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesLeftRight() }, q{ _ == "\n\nABC\n\nDEF\n\n\n"   }));

	mixin(deferEnsure!(q{ "\nABC\n ".stripLinesLeft()      }, q{ _ == "\nABC\n" }));
	mixin(deferEnsure!(q{ "\nABC\n ".stripLinesRight()     }, q{ _ == "\nABC\n" }));
	mixin(deferEnsure!(q{ "\nABC\n ".stripLinesLeftRight() }, q{ _ == "\nABC\n" }));

	mixin(deferEnsure!(q{ "\n".stripLinesLeft()      }, q{ _ == "\n" }));
	mixin(deferEnsure!(q{ "\n".stripLinesRight()     }, q{ _ == "\n" }));
	mixin(deferEnsure!(q{ "\n".stripLinesLeftRight() }, q{ _ == "\n" }));

	mixin(deferEnsure!(q{ "ABC".stripLinesLeftRight() }, q{ _ == "ABC" }));
	mixin(deferEnsure!(q{ "".stripLinesLeftRight()    }, q{ _ == ""    }));

	// stripLinesBox
	mixin(deferEnsure!(q{ " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesBox() }, q{ _ == "ABC\n\nDEF" }));
	mixin(deferEnsure!(q{ "\nABC\n ".stripLinesBox() }, q{ _ == "ABC" }));
	mixin(deferEnsure!(q{ "\n".stripLinesBox()       }, q{ _ == ""    }));
	mixin(deferEnsure!(q{ "ABC".stripLinesBox()      }, q{ _ == "ABC" }));
	mixin(deferEnsure!(q{ "".stripLinesBox()         }, q{ _ == ""    }));
	
	// stripLines at compile-time
	enum ctfe_stripLinesBox_dummy1 = " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesBox();
	enum ctfe_stripLinesBox_dummy2 = " \t \n\t \n ABC \n \n DEF \n \t \n\t \n".stripLinesLeftRight();
	enum ctfe_stripLinesBox_dummy3 = "".stripLinesBox();

	mixin(deferEnsure!(q{ ctfe_stripLinesBox_dummy1 }, q{ _ == "ABC\n\nDEF" }));
	mixin(deferEnsure!(q{ ctfe_stripLinesBox_dummy2 }, q{ _ == "\n\nABC\n\nDEF\n\n\n" }));
	mixin(deferEnsure!(q{ ctfe_stripLinesBox_dummy3 }, q{ _ == "" }));

	// normalize
	mixin(deferEnsure!(q{
				q{
			// test 
			void foo() {  
				int x = 2;
			}
	}.normalize()
	}, q{ _ == "// test\nvoid foo() {\n\tint x = 2;\n}" }));

	enum ctfe_normalize_dummy1 = q{
			// test 
			void foo() {  
				int x = 2;
			}
	}.normalize();
	mixin(deferEnsure!(q{ ctfe_normalize_dummy1 }, q{ _ == "// test\nvoid foo() {\n\tint x = 2;\n}" }));
}));
