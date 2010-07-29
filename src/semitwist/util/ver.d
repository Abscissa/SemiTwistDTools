// SemiTwist D Tools: Library
// Written in the D programming language.

module semitwist.util.ver;

import std.stdio;//tango.io.Stdout;
import std.math;//tango.math.Math;
//import tango.text.Util;
//import tango.util.Convert;
import std.conv;
import std.string;

import semitwist.util.all;
import semitwist.util.compat.all;

//TODO: Support versions that have different semantics
//TODO: Document ordering semantics of this
struct Ver
{
	uint[] ver;
	
	const int opCmp(ref const(Ver) v)
	{
		for(int i=0; i < reduce!"a<b?a:b"([this.ver.length, v.ver.length]); i++)
		{
			if(this.ver[i] != v.ver[i])
				return this.ver[i] - v.ver[i];
		}
		
		if(this.ver.length != v.ver.length)
			return this.ver.length - v.ver.length;
		
		return 0;
	}
	
	const bool opEquals(ref const(Ver) v)
	{
		return this.opCmp(v) == 0;
	}
	
	string toString()
	{
		return join(to!(string[])(ver), ".");
	}
}

Ver toVer(string str)
{
	return Ver( to!(uint[])(str.split(".")) );
}

unittest
{
	mixin(deferAssert!(`Ver([5,5,5])  == Ver([5,5,5])`));
	mixin(deferAssert!(`Ver([5,5,0])  != Ver([5,5,5])`));
	mixin(deferAssert!(`Ver([5,5])    != Ver([5,5,5])`));
	mixin(deferAssert!(`Ver([2,10,3]) == Ver([2,10,3])`));

	mixin(deferAssert!(`Ver([5,5,5]) > Ver([5,5,1])`));
	mixin(deferAssert!(`Ver([5,5,5]) > Ver([5,1,5])`));
	mixin(deferAssert!(`Ver([5,5,5]) > Ver([1,5,5])`));

	mixin(deferAssert!(`Ver([5,5,0]) < Ver([5,5,5])`));

	mixin(deferAssert!(`Ver([5,5,0]) > Ver([5,5])`));
	mixin(deferAssert!(`Ver([5,5])   < Ver([5,5,0])`));

	mixin(deferAssert!(`Ver([1,10]) > Ver([1,1])`));

	mixin(deferEnsure!(`"2.10.3".toVer().ver`, `_ == [cast(uint)2,10,3]`));
	mixin(deferEnsure!(`"2.10.3".toVer()`, `_ == Ver([2,10,3])`));
	mixin(deferEnsure!(`Ver([2,10,3]).toString()`, `_ == "2.10.3"`));
}
