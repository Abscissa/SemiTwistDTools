// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.ctfe;

import tango.io.Stdout;

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

//TODO: Test on wchar/dchar
T[] ctfe_join(T)(T[][] strs, T[] delim)
{
	T[] value = "";
	
	foreach(T[] str; strs)
		value ~= (value.length==0?"":delim) ~ str;
	
	return value;
}

//TODO: Is this just a failed experiment piece of scrap code to be removed?
template my_traceVal(values...)
{
	static if(values.length == 0)
		const char[] my_traceVal = "";
	else
	{
		const char[] my_traceVal =
			"Stdout.formatln(\"{}: {}\", \""~values[0].stringof[1..$-1]~"\", "~values[0].stringof[1..$-1]~");"
			~ my_traceVal!(values[1..$]);

/*
		pragma(msg, "values[0].stringof: "~values[0].stringof);
		pragma(msg, "traceVal: "~traceVal);
*/	}
}

T[] ctfe_substitute(T)(T[] str, T[] match, T[] replace)
{
	T[] value = "";
	
	if(str.length < match.length)
		return str.dup;
	
	int i;
	for(i=0; i<=str.length-match.length; i++)
	{
		if(str[i..i+match.length] == match)
		{
			value ~= replace;
			i += match.length-1;
		}
		else
			value ~= str[i];
	}
	value ~= str[i..$];
	return value;
}

/// --- These ctfe_i2a functions have been copied directly from Tango trunk ---
/// --- because they are useful, but not in the 0.99.8 release ---

/// compile time integer to string
char [] ctfe_i2a(int i){
    char[] digit="0123456789";
    char[] res="";
    if (i==0){
        return "0";
    }
    bool neg=false;
    if (i<0){
        neg=true;
        i=-i;
    }
    while (i>0) {
        res=digit[i%10]~res;
        i/=10;
    }
    if (neg)
        return '-'~res;
    else
        return res;
}
/// ditto
char [] ctfe_i2a(long i){
    char[] digit="0123456789";
    char[] res="";
    if (i==0){
        return "0";
    }
    bool neg=false;
    if (i<0){
        neg=true;
        i=-i;
    }
    while (i>0) {
        res=digit[cast(size_t)(i%10)]~res;
        i/=10;
    }
    if (neg)
        return '-'~res;
    else
        return res;
}
/// ditto
char [] ctfe_i2a(uint i){
    char[] digit="0123456789";
    char[] res="";
    if (i==0){
        return "0";
    }
    bool neg=false;
    while (i>0) {
        res=digit[i%10]~res;
        i/=10;
    }
    return res;
}
/// ditto
char [] ctfe_i2a(ulong i){
    char[] digit="0123456789";
    char[] res="";
    if (i==0){
        return "0";
    }
    bool neg=false;
    while (i>0) {
        res=digit[cast(size_t)(i%10)]~res;
        i/=10;
    }
    return res;
}