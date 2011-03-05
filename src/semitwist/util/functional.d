// SemiTwist Library
// Written in the D programming language.

module semitwist.util.functional;

/+version(Unittest)+/ import std.stdio;

import semitwist.util.all;


//TODO: Think about new naming scheme. Take a look at how tango does it.
template makeDg2To1(string str, T)
{
	const string makeDg2To1 = "("~T.stringof~" a, "~T.stringof~" b){ return ("~str~"); }";
	//pragma(msg, "makeDg2To1: "~makeDg2To1);
}
template makeDg2To1(string str, T1, T2)
{
	const string makeDg2To1 = "("~T1.stringof~" a, "~T2.stringof~" b){ return ("~str~"); }";
	//pragma(msg, "makeDg2To1: "~makeDg2To1);
}

template makeDg1To1(string str, T)
{
	const string makeDg1To1 = "("~T.stringof~" a){ return ("~str~"); }";
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

TOut reduceTo(TOut, TIn)(TIn[] list, TOut delegate(TOut a, TIn b) dg)
{
	return list.length==0? TOut.init :
	                       list.reduceTo(TOut.init, dg);
}

TOut reduceTo(TOut, TIn)(TIn[] list, TOut init, TOut delegate(TOut a, TIn b) dg)
{
	TOut result = init;
	foreach(TIn elem; list)
		result = dg(result, elem);
	
	return result;
}

T reduce(string dgstr, T)(T[] list)
{
	return reduce(list, mixin(makeDg2To1!(dgstr, T)));
}

T reduce(string dgstr, T)(T[] list, T init)
{
	return reduce(list, init, mixin(makeDg2To1!(dgstr, T)));
}

TOut reduceTo(TOut, string dgstr, TIn)(TIn[] list)
{
	return reduceTo(list, mixin(makeDg2To1!(dgstr, TOut, TIn)));
}

TOut reduceTo(TOut, string dgstr, TIn)(TIn[] list, TOut init)
{
	return reduceTo(list, init, mixin(makeDg2To1!(dgstr, TOut, TIn)));
}

TOut[] map(TOut, TIn)(TIn[] list, TOut delegate(TIn a) dg)
{
	TOut[] result;
	result.length = list.length;
	foreach(size_t i, TIn elem; list)
		result[i] = dg(elem);
	
	return result;
}

TOut[TKey] map(TOut, TIn, TKey)(TIn[TKey] list, TOut delegate(TIn a, TKey b) dg)
{
	TOut[TKey] result;
	foreach(TKey key, TIn elem; list)
		result[key] = dg(elem, key);
	
	return result;
}

T[] mapAAtoA(T, TKey)(T[TKey] list, T delegate(T a, TKey b) dg)
{
	return mapAAtoATo(list, dg);
}

TOut[] mapAAtoATo(TOut, TIn, TKey)(TIn[TKey] list, TOut delegate(TIn a, TKey b) dg)
{
	size_t i=0;
	TOut[] result;
	result.length = list.length;
	foreach(TKey key, TIn elem; list)
	{
		result[i] = dg(elem, key);
		i++;
	}
	
	return result;
}

T[] map(string dgstr, T)(T[] list)
{
	return map(list, mixin(makeDg1To1!(dgstr, T)));
}

T[TKey] map(string dgstr, T, TKey)(T[TKey] list)
{
	return map(list, mixin(makeDg2To1!(dgstr, T, TKey)));
}

TOut[] mapTo(TOut, string dgstr, TIn)(TIn[] list)
{
	return map(list, mixin(makeDg1To1!(dgstr, TIn)));
}

TOut[TKey] mapTo(TOut, string dgstr, TIn, TKey)(TIn[TKey] list)
{
	return map(list, mixin(makeDg2To1!(dgstr, TIn, TKey)));
}

T[] mapAAtoA(string dgstr, T, TKey)(T[TKey] list)
{
	return mapAAtoA(list, mixin(makeDg2To1!(dgstr, T, TKey)));
}

TOut[] mapAAtoATo(TOut, string dgstr, TIn, TKey)(TIn[TKey] list)
{
	return mapAAtoATo(list, mixin(makeDg2To1!(dgstr, TIn, TKey)));
}

/+T[] filter(T)(T[] list, bool delegate(T a) dg)
{
	T[] result = list.dup;
	auto numRemaining = result.removeIf((T a){return !dg(a);});
	return result[0..numRemaining];
}

T[] filter(string dgstr, T)(T[] list)
{
	return filter(list, mixin(makeDg1To1!(dgstr, T)));
}+/

//TODO: Make foreachWhile
//TODO: Make variant that also provides an index to the delegate
//TODO: Make variant for AA
/// Like foreach, except the body has a return value,
/// and the loop bails whenever that value != whileVal
TRet foreachWhileVal(TRet, TElem)(TElem[] coll, TRet whileVal, TRet delegate(TElem) dg)
{
	foreach(TElem elem; coll)
	{
		auto ret = dg(elem);
		if(ret != whileVal)
			return ret;
	}
	return whileVal;
}

mixin(unittestSemiTwistDLib(q{
	int[string] aa = ["a":1, "b":2, "c":3];
	int[string] expected;
	int[string] result;

	mixin(deferEnsure!(`aa.keys`,   `_ == ["a","b","c"]`));

	// Map
	int[] array = [1, 2, 3, 4, 5];
	mixin(deferEnsure!(`map(array, (int a){return a*10;})`, `_ == [10,20,30,40,50]`));
	mixin(deferEnsure!(`map!("a*10")(array)`, `_ == [10,20,30,40,50]`));

	// Map assoc array using dg literal
	result = map(aa, (int a, string b){return a*10;});
	// Workaround for DMD Bug #1671
	//mixin(deferEnsure!(`result`, `_ == ['a':10,'b':20,'c':30]`));
	mixin(deferEnsure!(`result.length`, `_ == 3`));
	mixin(deferEnsure!(`result.keys`,   `_ == ["a","b","c"]`));
	//mixin(traceVal!("result.keys", "result.keys.length"));
	//mixin(traceVal!("result.keys[0]", "result.keys[1]", `result.keys[2]~""`));
	mixin(deferEnsure!(`result.values`, `_ == [10,20,30]`));

	// Map assoc array using dg string
	result = map!(`a*10`)(aa);
	mixin(deferEnsure!(`result.length`, `_ == 3`));
	mixin(deferEnsure!(`result.keys`,   `_ == ["a","b","c"]`));
	mixin(deferEnsure!(`result.values`, `_ == [10,20,30]`));

	// mapAAtoA
	mixin(deferEnsure!(`mapAAtoA(aa, (int a, string b){return a*10;})`, `_ == [10,20,30]`));
	mixin(deferEnsure!(`mapAAtoA!("a*10")(aa)`, `_ == [10,20,30]`));

	// mapAAtoA To
	mixin(deferEnsure!(`mapAAtoATo(aa, (int a, string b){return a*10+0.5;})`, `_ == [10.5,20.5,30.5]`));
	mixin(deferEnsure!(`mapAAtoATo!(double, "a*10+0.5")(aa)`, `_ == [10.5,20.5,30.5]`));
		
	// Reduce
	mixin(deferEnsure!(`reduce(array, (int a, int b){return a*b;})`, `_ == (1*2*3*4*5)`));
	mixin(deferEnsure!(`reduce!("a*b")(array)`, `_ == (1*2*3*4*5)`));
	
	// Reduce To
	mixin(deferEnsure!(`reduceTo(array, (int[] a, int b){return a~(b*10);})`, `_ == [10,20,30,40,50]`));
	mixin(deferEnsure!(`reduceTo!(int[], "a~(b*10)")(array)`, `_ == [10,20,30,40,50]`));
	
	// Reduce using initial value
	mixin(deferEnsure!(`reduce(array, 10, (int a, int b){return a*b;})`, `_ == (10*1*2*3*4*5)`));
	mixin(deferEnsure!(`reduce!("a*b")(array, 10)`, `_ == (10*1*2*3*4*5)`));
	
	// Reduce empty array
	mixin(deferEnsure!(`reduce(cast(int[])[], (int a, int b){return a*b;})`, `_ == 0`));
	mixin(deferEnsure!(`reduce!("a*b")(cast(int[])[])`, `_ == 0`));

	//TODO: Reduce assoc array
	
	// Filter
/+	mixin(deferEnsure!(`filter(array, (int a){return (a%2)==0;})`, `_ == [2,4]`));
	mixin(deferEnsure!(`filter!("(a%2)==0")(array)`, `_ == [2,4]`));
+/
	//TODO: Filter assoc array
	
}));
