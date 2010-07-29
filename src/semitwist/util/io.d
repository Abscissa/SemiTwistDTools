// SemiTwist Library
// Written in the D programming language.

module semitwist.util.io;

import std.traits;//tango.core.Traits;
import std.path;//tango.io.FilePath;
//import tango.io.device.File;
//import tango.io.stream.Data;
//import tango.stdc.stringz;
//import tango.text.Util;
//import tango.text.convert.UnicodeBom;
//import tango.util.Convert;
import std.conv;

import semitwist.util.all;
import semitwist.util.compat.all;

version(Win32)
	import std.c.windows.windows;
else version(OSX)
	private extern(C) int _NSGetExecutablePath(char* buf, uint* bufsize);
else
	import std.c.linux.linux;

/++
Reads any type of Unicode/UTF text file (UTF-8, UTF-16, UTF-32, big or little
endian), and automatically converts it to native endianness and whatever
codepoint size specified in TOut:
	char or char[]:   UTF-8, native endianness
	wchar or wchar[]: UTF-16, native endianness
	dchar or dchar[]: UTF-32, native endianness
	
Examples:
	char[]  utf8  = readUnicodeFile!(char   )( "ANY_unicode_file.txt" );
	char[]  utf8  = readUnicodeFile!(char[] )( "ANY_unicode_file.txt" );
	wchar[] utf16 = readUnicodeFile!(wchar  )( "ANY_unicode_file.txt" );
	wchar[] utf16 = readUnicodeFile!(wchar[])( "ANY_unicode_file.txt" );
	dchar[] utf32 = readUnicodeFile!(dchar  )( "ANY_unicode_file.txt" );
	dchar[] utf32 = readUnicodeFile!(dchar[])( "ANY_unicode_file.txt" );
+/
EnsureArray!(TOut) readUnicodeFile(TOut, TFilename)(TFilename filename)
{
	static assert(isStringType!(TFilename), "'filename' must be a string type");
	
	static if(isCharType!(TOut))
		alias TOut TChar;
	else static if(isStringType!(TOut))
		alias ElementTypeOfArray!(TOut) TChar;
	else
		static assert(false, "TOut must be a character or string type");

	auto bom = new UnicodeBom!(TChar)(Encoding.Unknown);
	return bom.decode(File.get( to!(string)(filename) ));
}

T[] readStringz(T)(DataInput reader)
{
	mixin(ensureCharType!("T"));
	
	T[] str;
	T c;
	
	do
	{
		static if(is(T == char))
			c = cast(T)reader.getByte();
		else static if(is(T == wchar))
			c = cast(T)reader.getShort();
		else
			c = cast(T)reader.getInt();
			
		str ~= c;
	} while(c != 0);

	return str[0..$-1];
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

	//auto fp = new FilePath(file[0..filenameLength]);
	return to!string(file[0..filenameLength]);
//	return getExecFilePath().toString().trim();
}

/// Like getExec, but doesn't include the path.
string getExecName()
{
	return getExec().basename();
//	return getExecFilePath().file().trim();
}

/// Like getExec, but only returns the path (including trailing path separator).
string getExecPath()
{
	return getExec().dirname();
	//return getExecFilePath().path().trim();
}
