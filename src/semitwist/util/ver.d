// SemiTwist D Tools: Library
// Written in the D programming language.

module semitwist.util.ver;

import std.stdio;
import std.math;
import std.conv;
import std.string;

import semitwist.util.all;

//TODO: Support versions that have different semantics
//TODO: Document ordering semantics of this
//TODO: This should all work at compile-time
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
		
		if(this.ver.length > v.ver.length)
			return 1;
		else if(this.ver.length < v.ver.length)
			return -1;
		
		return 0;
	}
	
	const bool opEquals(ref const(Ver) v)
	{
		return this.opCmp(v) == 0;
	}
	
	static if(useNoThrowSafeToHash)
	{
		const nothrow @trusted hash_t toHash()
		{
			string str;
			try
				str = toString();
			catch(Exception e)
				{} // Yes, that's right, I actually have to pull a Java
				// and squelch exceptions for the time being. *$^@&!#
			return typeid(string).getHash(&str);
		}
	}
	else
	{
		const hash_t toHash()
		{
			auto str = toString();
			return typeid(string).getHash(&str);
		}
	}

	const string toString()
	{
		return join(to!(string[])(ver), ".");
	}
}

Ver toVer(string str)
{
	auto strParts = str.ctfe_split(".");
	uint[] verParts;
	verParts.length = strParts.length;
	
	foreach(i, strPart; strParts)
		verParts[i] = ctfe_to!uint(strPart);
		
	return Ver(verParts);
}

mixin(unittestSemiTwistDLib(q{
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
}));
