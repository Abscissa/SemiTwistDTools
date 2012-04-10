// SemiTwist Library
// Written in the D programming language.

module semitwist.util.io;

import std.traits;
import std.path;
import std.conv;
import std.file;
import std.stdio;
import std.stream;
import std.string;
import std.system;

import semitwist.util.all;

version(Win32)
	import std.c.windows.windows;
else version(OSX)
	private extern(C) int _NSGetExecutablePath(char* buf, uint* bufsize);
else
	import std.c.linux.linux;

/++
Reads any type of Unicode/UTF text file (UTF-8, UTF-16, UTF-32, big or little
endian), detects BOM, and automatically converts it to native endianness and
whatever string type is specified in TOut.
	
Examples:
	string  utf8  = readUTFFile!string ( "ANY_unicode_file.txt" );
	wstring utf16 = readUTFFile!wstring( "ANY_unicode_file.txt" );
	dstring utf32 = readUTFFile!dstring( "ANY_unicode_file.txt" );
+/
TOut readUTFFile(TOut, TFilename)(TFilename filename)
	if(isSomeString!TOut && isSomeString!TFilename)
{
	auto data = cast(immutable(ubyte)[])read(filename);
	return utfConvert!TOut(data);
}

/++
Converts any type of Unicode/UTF string with or without a BOM (UTF-8, UTF-16,
UTF-32, big or little endian), strips the BOM (if it exists), and automatically
converts it to native endianness and whatever string type is specified in TOut.

If there is no BOM, then UTF-8 is assumed.
	
Examples:
	string  utf8  = utfConvert!string ( anyUTFDataWithBOM );
	wstring utf16 = utfConvert!wstring( anyUTFDataWithBOM );
	dstring utf32 = utfConvert!dstring( anyUTFDataWithBOM );
+/
TOut utfConvert(TOut, TInChar)(immutable(TInChar)[] data)
	if( isSomeString!TOut && (isSomeString!(immutable(TInChar)[]) || is(TInChar==ubyte)) )
{
	auto bom = bomOf(cast(immutable(ubyte)[])data);
	auto bomCode = bomCodeOf(bom);
	
	// Strip BOM if it exists
	if(data.length >= bomCode.length && data[0..bomCode.length] == bomCode)
		data = data[bomCode.length..$];
	
	if(isNonNativeEndian(bom))
	{
		auto tempData = data.dup;
		if(is16Bit(bom))
			byteSwap16(tempData);
		else if(is32Bit(bom))
			byteSwap32(tempData);
		
		return to!TOut(tempData);
	}

	// No references to 'data' are maintained
	if(is8Bit(bom))
		return to!TOut(cast(string)data);
	else if(is16Bit(bom))
		return to!TOut(cast(wstring)data);
	else if(is32Bit(bom))
		return to!TOut(cast(dstring)data);
	else
		throw new Exception("Unhandled BOM type '%s'".format(bom));
}

ushort byteSwapVal16(ushort value)
{
	return cast(ushort)( (value >> 8) | ((value & 0x00FF) << 8) );
}

uint byteSwapVal32(uint value)
{
	return
		(value >> 24) |
		((value & 0x00FF_0000) >>  8) |
		((value & 0x0000_FF00) <<  8) |
		((value & 0x0000_00FF) << 24);
}

private T byteSwap(T)(T value) if(is(T==ushort) || is(T==uint))
{
	static if(is(T==ushort))
		return byteSwapVal16(value);
	else static if(is(T==uint))
		return byteSwapVal32(value);
	else
		static assert(0, "T=='"+T.stringof+"' not handled");
}

void byteSwapInPlace(T)(T[] data) if(is(T==ushort) || is(T==uint))
{
	foreach(ref value; data)
		value = byteSwap(value);
}

private immutable(T)[] byteSwap(T)(immutable(T)[] data) if(is(T==ushort) || is(T==uint))
{
	T[] mutableData = data.dup;
	byteSwapInPlace(mutableData);
	
	// Neither this nor byteSwapInPlace squirrels away a copy
	return cast(immutable(T)[])mutableData;
}

immutable(T)[] byteSwap16(T)(const(T)[] data)
{
	return cast(immutable(T)[])byteSwap(cast(immutable(ushort)[])data);
}

immutable(T)[] byteSwap32(T)(const(T)[] data)
{
	return cast(immutable(T)[])byteSwap(cast(immutable(uint)[])data);
}

T readStringz(T)(std.stream.File reader) if(isSomeString!T)
{
	Unqual!T str;
	static if(is(T==string))
		alias char TElem;
	else static if(is(T==wstring))
		alias wchar TElem;
	else static if(is(T==dstring))
		alias dchar TElem;
	else
		static assert("'"~T.stringof~"' not allowed.");
		
	TElem c;
	
	do
	{
		reader.read(c);
		str ~= c;
	} while(c != 0);

	// No references saved, nothing can change it.
	return cast(T)(str[0..$-1]);
}

//TODO*: Unittest this
// This assumes that data is already in native endianness
T toEndian(T)(T data, Endian en) if(is(T==ushort) || is(T==uint))
{
	if(en == endian)
		return data;
	else
		return byteSwap(data);
}

/// Gets the full path to the currently running executable,
/// regardless of working directory or PATH env var or anything else.
/// Note that this is far more accurate and reliable than using args[0].
/+FilePath getExecFilePath()
{
	string file = new char[4*1024];
	int filenameLength;
	version (Win32)
		filenameLength = GetModuleFileNameA(null, file.ptr, file.length-1);
	else version(OSX)
	{
		filenameLength = file.length-1;
		_NSGetExecutablePath(file.ptr, &filenameLength);
	}
	else
        filenameLength = readlink(toStringz(selfExeLink), file.ptr, file.length-1);

	auto fp = new FilePath(file[0..filenameLength]);
	fp.native();
	return fp;
}+/
/// ditto
string getExec()
{
	auto file = new char[4*1024];
	size_t filenameLength;
	version (Win32)
		filenameLength = GetModuleFileNameA(null, file.ptr, file.length-1);
	else version(OSX)
	{
		filenameLength = file.length-1;
		_NSGetExecutablePath(file.ptr, &filenameLength);
	}
	else
        filenameLength = readlink(toStringz(selfExeLink), file.ptr, file.length-1);

	//auto fp = new FilePath(file[0..filenameLength]);
	return to!string(file[0..filenameLength]);
//	return getExecFilePath().toString().trim();
}

/// Like getExec, but doesn't include the path.
string getExecName()
{
	return getExec().baseName();
//	return getExecFilePath().file().trim();
}

/// Like getExec, but only returns the path (including trailing path separator).
string getExecPath()
{
	return getExec().dirName() ~ dirSep;
	//return getExecFilePath().path().trim();
}

mixin(unittestSemiTwistDLib(q{
	// byteSwap
	mixin(deferEnsure!(q{ byteSwapVal16(0x1234     ) }, q{ _ == 0x3412      }));
	mixin(deferEnsure!(q{ byteSwapVal32(0x1234_5678) }, q{ _ == 0x7856_3412 }));

	mixin(deferEnsure!(q{ byteSwap16(cast(immutable(ushort)[])[0x1234, 0x5678, 0x9ABC, 0xDEF0]) }, q{ _ == cast(ushort[])[0x3412, 0x7856, 0xBC9A, 0xF0DE] }));
	mixin(deferEnsure!(q{ byteSwap32(cast(immutable(uint)[]  )[0x1234____5678, 0x9ABC____DEF0]) }, q{ _ == cast(uint[]  )[0x7856_3412, 0xF0DE_BC9A]       }));
	
	// utfConvert
	mixin(deferEnsure!(q{ utfConvert!string(cast(string)bomCodeOf(semitwist.util.text.BOM.UTF8)~("AB\nCD"~"\r"~"\nEF")) }, q{ _== ("AB\nCD"~"\r"~"\nEF") }));
	mixin(deferEnsure!(q{ utfConvert!string ("ABCDEF") }, q{ _== ("ABCDEF" ) }));
	mixin(deferEnsure!(q{ utfConvert!dstring("ABCDEF") }, q{ _== ("ABCDEF"d) }));
	//TODO: Check into the weird disappearing \r:
	//mixin(traceVal!(q{ ("AB\nCD"~"\r"~"\nEF").escapeDDQS() }));
	//mixin(traceVal!(q{ ("AB\nCD"~"\r"~"\nEF").length }));
	//mixin(traceVal!(q{ utfConvert!string(cast(string)bomCodeOf(semitwist.util.text.BOM.UTF8)~("AB\nCD"~"\r"~"\nEF")).escapeDDQS() }));
}));
