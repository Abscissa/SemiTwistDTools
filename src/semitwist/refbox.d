// SemiTwist Library
// Written in the D programming language.

module semitwist.refbox;

import std.stdio;
import std.math;
import std.string;
import std.algorithm : find;

import semitwist.util.all;

//TODO: Does phobos's Variant make this obsolete?
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
	
	const bool opEquals(ref const(RefBox!(T)) val)
	{
		return *this.val == *val.val;
	}
	
	const bool opEquals(ref const(T) val)
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

string getRefBoxTypeName(Object o)
{
	string head = RefBox.stringof[0..$-3]~"!(";
	string unknown = "{unknown}";
	string typeName = o.classinfo.name;
	
	//TODO?: Replace this with a regex search (if possible) and handle nested ()'s
	
	auto start = locatePrior(typeName, head);
	if(start == typeName.length)
		return unknown;
	start += head.length;
		
	auto end = locate(typeName[start..$], ')')+start;
	if(end == typeName.length)
		return unknown;
	
	// Nested () inside "RefBox!(...)" is not currently supported
	if(std.algorithm.find(typeName[start..end], '(') != [])
		return unknown;
		
	return typeName[start..end];
}

/// Helpful templates
template unbox(alias obj, string name)
{
	enum unbox =
		unboxToTypeAndArray!(obj, name~"AsInt",  int   )~
		unboxToTypeAndArray!(obj, name~"AsBool", bool  )~
		unboxToTypeAndArray!(obj, name~"AsStr",  string);
	//pragma(msg, "unbox:\n" ~ unbox);
}

private template unboxToTypeAndArray(alias obj, string name, type)
{
	enum unboxToTypeAndArray =
		unboxTo!(obj, name,     type.stringof     )~
		unboxTo!(obj, name~"s", type.stringof~"[]");
}

private template unboxTo(alias obj, string name, string type)
{
	enum unboxTo = "auto "~name~" = cast(RefBox!("~type~"))"~obj.stringof~";\n";
}


template dupRefBox(alias from, string tempName, alias to)
{
	enum dupRefBox =
		unbox!(from, tempName)~
		"if(false) {}\n"~
		dupRefBoxTypeAndArray!(from, tempName~"AsInt",  int   , to)~
		dupRefBoxTypeAndArray!(from, tempName~"AsBool", bool  , to)~
		dupRefBoxTypeAndArray!(from, tempName~"AsStr",  string, to)~
		"else "~to.stringof~" = null;\n";
	//pragma(msg, "dupRefBox:\n" ~ dupRefBox);
}

private template dupRefBoxTypeAndArray(alias from, string tempName, type, alias to)
{
	enum dupRefBoxTypeAndArray =
		dupRefBoxFrom!(from, tempName,     type.stringof     , to)~
		dupRefBoxFrom!(from, tempName~"s", type.stringof~"[]", to);
}

private template dupRefBoxFrom(alias from, string tempName, string type, alias to)
{
	enum dupRefBoxFrom = "else if("~tempName~") "~to.stringof~" = "~tempName~".dup();\n";
}


template isKnownRefBox(alias obj)
{
	enum isKnownRefBox =
		isKnownRefBoxTypeAndArray!(obj, int   )~
		isKnownRefBoxTypeAndArray!(obj, bool  )~
		isKnownRefBoxTypeAndArray!(obj, string)~
		"false ";
	//pragma(msg, "isKnownRefBox:\n" ~ isKnownRefBox);
}

private template isKnownRefBoxTypeAndArray(alias obj, type)
{
	enum isKnownRefBoxTypeAndArray =
		isKnownRefBoxOf!(obj, type.stringof     )~
		isKnownRefBoxOf!(obj, type.stringof~"[]");
}

private template isKnownRefBoxOf(alias obj, string type)
{
	enum isKnownRefBoxOf = "cast(RefBox!("~type~"))"~obj.stringof~" ||\n";
}
