// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.io;

import tango.io.FilePath;
//import tango.io.protocol.Reader;
import tango.io.stream.Data;

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

// Modified from: http://www.dsource.org/projects/tango/forums/topic/595
char[] getExec()
{
	char[] thisFile = new char[1024];

	version (Win32)
		GetModuleFileNameA(null,thisFile.ptr,1023);
	else
        thisFile = thisFile[0..(readlink(toStringz("/proc/self/exe"),thisFile.ptr,1023))];

	auto fp = new FilePath(thisFile);
	fp.native();
	return fp.toString();
}

version(Win32)
	const char[] pathSeparator = "\\";
else
	const char[] pathSeparator = "/";
