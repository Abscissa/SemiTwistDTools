// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.array;

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
