// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.functional;

template makeDg2To1(char[] str, T)
{
	const char[] makeDg2To1 = "("~T.stringof~" a, "~T.stringof~" b){ return ("~str~"); }";
	//pragma(msg, "makeDg2To1: "~makeDg2To1);
}

template makeDg1To1(char[] str, T)
{
	const char[] makeDg1To1 = "("~T.stringof~" a){ return ("~str~"); }";
	//pragma(msg, "makeDg1To1: "~makeDg1To1);
}

T reduce(T)(T[] list, T delegate(T a, T b) dg)
{
	return list.length==0? T.init  :
	       list.length==1? list[0] :
	                       list[1..$].reduce(list[0], dg);
}

T reduce(T)(T[] list, T init, T delegate(T a, T b) dg)
{
	T result = init;
	foreach(T elem; list)
		result = dg(result, elem);
	
	return result;
}

T reduce(char[] dgstr, T)(T[] list)
{
	return reduce(list, mixin(makeDg2To1!(dgstr, T)));
}

T reduce(char[] dgstr, T)(T[] list, T init)
{
	return reduce(list, init, mixin(makeDg2To1!(dgstr, T)));
}

TOut[] map(TOut, TIn)(TIn[] list, TOut delegate(TIn a) dg)
{
	TOut[] result;
	result.length = list.length;
	foreach(size_t i, TIn elem; list)
		result[i] = dg(elem);
	
	return result;
}

TOut[TKey] map(TOut, TIn, TKey)(TIn[TKey] list, TOut delegate(TKey a, TIn b) dg)
{
	TOut[TKey] result;
	foreach(TKey key, TIn elem; list)
		result[key] = dg(key, elem);
	
	return result;
}

TOut[] mapAAtoA(TOut, TIn, TKey)(TIn[TKey] list, TOut delegate(TKey a, TIn b) dg)
{
	size_t i=0;
	TOut[] result;
	result.length = list.length;
	foreach(TKey key, TIn elem; list)
	{
		result[i] = dg(key, elem);
		i++;
	}
	
	return result;
}

TOut[] map(char[] dgstr, TOut, TIn)(TIn[] list)
{
	return map(list, mixin(makeDg1To1!(dgstr, TIn)));
}

TOut[TKey] map(char[] dgstr, TOut, TIn, TKey)(TIn[TKey] list)
{
	return map(list, mixin(makeDg2To1!(dgstr, TKey, TIn)));
}
