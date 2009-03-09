// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.refbox;

import tango.core.Array;
import tango.io.Stdout;
import tango.math.Math;
import tango.text.Util;
import convInt = tango.text.convert.Integer;

import semitwist.util.all;

//TODO? convert to struct
/// A boxable wrapper useful for variables of primitive types.
class RefBox(T)
{
	private T* val;
	private T optionalValSrc;
	
	this()
	{
		this.val = &optionalValSrc;
	}
	
	this(T* val)
	{
		this.val = val;
	}
	
	T opCall()
	{
		return *val;
	}
	
	void opAssign(T val)
	{
		*this.val = val;
	}
	
	bool opEquals(RefBox!(T) val)
	{
		return *this.val == *val.val;
	}
	
	bool opEquals(T val)
	{
		return *this.val == val;
	}
	
	RefBox!(T) dup()
	{
		auto newBox = new RefBox!(T)();
		newBox.optionalValSrc = *this.val;
		return newBox;
	}
}

char[] getRefBoxTypeName(Object o)
{
	char[] head = RefBox.stringof[0..$-3]~"!(";
	char[] unknown = "{unknown}";
	char[] typeName = o.classinfo.name;
	
	//TODO?: Replace this with a regex search (if possible) and handle nested ()'s
	
	auto start = locatePatternPrior(typeName, head);
	if(start == typeName.length)
		return unknown;
	start += head.length;
		
	auto end = locate(typeName, ')', start);
	if(end == typeName.length)
		return unknown;
	
	// Nested () inside "RefBox!(...)" is not currently supported
	if(tango.text.Util.contains(typeName[start..end], '('))
		return unknown;
		
	return typeName[start..end];
}

/// Helpful templates
template unbox(alias obj, char[] name)
{
	const char[] unbox =
		unboxToTypeAndArray!(obj, name~"AsInt",  int   )~
		unboxToTypeAndArray!(obj, name~"AsBool", bool  )~
		unboxToTypeAndArray!(obj, name~"AsStr",  char[]);
	//pragma(msg, "unbox:\n" ~ unbox);
}

private template unboxToTypeAndArray(alias obj, char[] name, type)
{
	const char[] unboxToTypeAndArray =
		unboxTo!(obj, name,     type.stringof     )~
		unboxTo!(obj, name~"s", type.stringof~"[]");
}

private template unboxTo(alias obj, char[] name, char[] type)
{
	const char[] unboxTo = "auto "~name~" = cast(RefBox!("~type~"))"~obj.stringof~";\n";
}


template dupRefBox(alias from, char[] tempName, alias to)
{
	const char[] dupRefBox =
		unbox!(from, tempName)~
		"if(false) {}\n"~
		dupRefBoxTypeAndArray!(from, tempName~"AsInt",  int   , to)~
		dupRefBoxTypeAndArray!(from, tempName~"AsBool", bool  , to)~
		dupRefBoxTypeAndArray!(from, tempName~"AsStr",  char[], to)~
		"else "~to.stringof~" = null;\n";
	//pragma(msg, "dupRefBox:\n" ~ dupRefBox);
}

private template dupRefBoxTypeAndArray(alias from, char[] tempName, type, alias to)
{
	const char[] dupRefBoxTypeAndArray =
		dupRefBoxFrom!(from, tempName,     type.stringof     , to)~
		dupRefBoxFrom!(from, tempName~"s", type.stringof~"[]", to);
}

private template dupRefBoxFrom(alias from, char[] tempName, char[] type, alias to)
{
	const char[] dupRefBoxFrom = "else if("~tempName~") "~to.stringof~" = "~tempName~".dup();\n";
}


template isKnownRefBox(alias obj)
{
	const char[] isKnownRefBox =
		isKnownRefBoxTypeAndArray!(obj, int   )~
		isKnownRefBoxTypeAndArray!(obj, bool  )~
		isKnownRefBoxTypeAndArray!(obj, char[])~
		"false ";
	//pragma(msg, "isKnownRefBox:\n" ~ isKnownRefBox);
}

private template isKnownRefBoxTypeAndArray(alias obj, type)
{
	const char[] isKnownRefBoxTypeAndArray =
		isKnownRefBoxOf!(obj, type.stringof     )~
		isKnownRefBoxOf!(obj, type.stringof~"[]");
}

private template isKnownRefBoxOf(alias obj, char[] type)
{
	const char[] isKnownRefBoxOf = "cast(RefBox!("~type~"))"~obj.stringof~" ||\n";
}
