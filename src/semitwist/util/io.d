// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.io;

import tango.io.protocol.Reader;
import tango.io.stream.DataStream;

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
		c = cast(wchar)reader.getShort();
		str ~= c;
	} while(c != 0);

	return str[0..$-1];
}
