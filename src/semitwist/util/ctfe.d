// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.ctfe;

// Intended for CTFE, but tends to cause Out Of Memory error
private char[] pad(char[] str, uint length, char padChar=' ')
{
	return pad(str, length, true, padChar);
}
private char[] pad(char[] str, uint length, bool padLeft=true, char padChar=' ')
{
	if(str.length < length)
	{
		auto padding = _repeat(padChar, str.length - length);
		
		if(padLeft)
			str = padding ~ str;
		else
			str = str ~ padding;
	}
	
	return str;
}

// Intended for CTFE, but tends to cause Out Of Memory error
private char[] _repeat(char chr, uint count)
{
	return _repeat("" ~ chr, count);
}
private char[] _repeat(char[] str, uint count)
{
	if(count == 0)
		return "";
		
	for(int i=0; i<count-1; i++)
		str ~= str;
		
	return str;
}

/// tango.text.Util.locate() and tango.core.Array.find() don't work at compile-time.
size_t ctfe_find(T)(T[] collection, T elem, size_t start=0)
{
	for(size_t i=start; i<collection.length; i++)
	{
		if(collection[i] == elem)
			return i;
	}
	return collection.length;
}
