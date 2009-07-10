// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.array;

import tango.core.Array;

size_t maxLength(T)(T[][] arrays)
{
	size_t maxLen=0;
	foreach(T[] array; arrays)
		maxLen = max(maxLen, array.length);
	return maxLen;
}

size_t indexOfMin(T)(T[] array)
{
	T best = T.max;
	size_t bestIndex;
	foreach(size_t i, T elem; array)
	{
		if(elem < best)
		{
			best = elem;
			bestIndex = i;
		}
	}
	return bestIndex;
}

size_t indexOfMax(T)(T[] array)
{
	T best = T.min;
	size_t bestIndex;
	foreach(size_t i, T elem; array)
	{
		if(elem > best)
		{
			best = elem;
			bestIndex = i;
		}
	}
	return bestIndex;
}

//TODO: eliminate name collision with tango.text.Util
//TODO: Is this the same as tango.core.Array.findIf()?
size_t find(T)(T[] collection, bool delegate(T[], size_t) isFound, size_t start=0)
{
	for(size_t i=start; i<collection.length; i++)
	{
		if(isFound(collection, i))
			return i;
	}
	
	return collection.length;
}

size_t findPrior(T)(T[] collection, bool delegate(T[], size_t) isFound, size_t start=(size_t).max)
{
	if(start == (size_t).max)
		start = collection.length-1;
		
	for(size_t i=start; i >= 0; i--)
	{
		if(isFound(collection, i))
			return i;
	}

	return collection.length;
}

// Returns everything in 'from' minus the values in 'except'.
// Note: using ref didn't work when params were (const char[][] here).dup
T[] allExcept(T)(T[] from, T[] except)
{
	T[] f = from.dup;
	T[] e = except.dup;
	f.sort();
	e.sort();
	return f.missingFrom(e);
}
T[] allExcept(T)(T[] from, T except)
{
	return allExcept(from, [except]);
}
