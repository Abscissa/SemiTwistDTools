// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.io;

import tango.io.FilePath;
import tango.io.stream.Data;
import tango.text.Util;

version(Win32)
	import tango.sys.win32.UserGdi;
else
	import tango.stdc.posix.unistd;

wchar[] readNullTerminatedWString(DataInput reader)
{
	wchar[] str;
	wchar c;
	
	do
	{
		c = cast(wchar)reader.getShort();
		str ~= c;
	} while(c != 0);

	return str[0..$-1];
}

/// Gets the full path to the currently running executable,
/// regardless of working directory or PATH env var or anything else.
FilePath getExecFilePath()
{
	char[] file = new char[1024];
	int filenameLength;
	version (Win32)
		filenameLength = GetModuleFileNameA(null, file.ptr, file.length-1);
	else
        filenameLength = readlink(toStringz(selfExeLink), file.ptr, file.length-1);

	auto fp = new FilePath(file[0..filenameLength]);
	fp.native();
	return fp;
}
/// ditto
char[] getExec()
{
	return getExecFilePath().toString().trim();
}

/// Like getExec, but doesn't include the path.
char[] getExecName()
{
	return getExecFilePath().file().trim();
}

/// Like getExec, but only returns the path (including trailing path separator).
char[] getExecPath()
{
	return getExecFilePath().path().trim();
}


// Use semitwist.os.pathSep instead
/*
version(Win32)
	const char[] pathSeparator = "\\";
else
	const char[] pathSeparator = "/";
*/
