// SemiTwist Library
// Written in the D programming language.

module semitwist.util.reflect;

import std.conv;
import std.demangle;
import std.iterator;
import std.traits;

import semitwist.util.all;

/++
If you have a class MyClass(T), then nameof!(MyClass) will return "MyClass".

One benefit of this is that you can do things like:
	mixin("auto obj = new "~nameof!(MyClass)~"!(int)()");
or
	throw new Exception("Something's wrong with a "~nameof!(MyClass)~" object!";
and the "MyClass" will be checked by the compiler, alerting you immediately
if the class name changes, helping you keep such strings up-to-date.
+/
template nameof(alias T)
{
	enum string nameof = T.stringof[0..ctfe_find(to!(char[])(T.stringof), '(')];
}

template isAnyArray(T)
{
	enum bool isAnyArray =
		isArray!(T) ||
		isAssociativeArray!(T);
}

// isStringType has been submitted for inclusion in Tango (ticket #1864),
// so define it only if it doesn't already exist.
static if(!is(typeof( isStringType!(char[]) )))
{
	/// Evaluates to true if T is char[], wchar[], or dchar[].
	template isStringType(T)
	{
		enum bool isStringType =
			is( T : char[]  ) ||
			is( T : wchar[] ) ||
			is( T : dchar[] );
	}
}

/// If T is a static array, it's changed to a dynamic array, otherwise just returns T.
template PreventStaticArray(T)
{
	static if(isArray!(T))
		private alias ElementType!(T)[] PreventStaticArray;
	else
		private alias T PreventStaticArray;
}

/// If T isn't an array, returns T[], otherwise returns T as-is.
template EnsureArray(T)
{
	static if(isArray!(T))
		alias T EnsureArray;
	else
		alias T[] EnsureArray;
}

template callableExists(T)
{
	static if(is(T) && isCallable(typeof(T)))
		enum bool callableExists = true;
	else
		enum bool callableExists = false;
}

template ExprTypeOf(T)
{
    static if(isCallable!(T))
        alias ReturnType!(T) ExprTypeOf;
    else
        alias T ExprTypeOf;
}

string qualifiedName(alias ident)()
{
	string mangled = mangledName!ident;
	
	// Work around DMD Issue #5718: Can't demangle symbol defined inside unittest block
	int startIndex = ctfe_find(mangled, "_D");
	if(startIndex == mangled.length)
		startIndex = 0;
	
	return demangle(mangled[startIndex..$]);
}

/++
Calls .stringof on each argument then returns
the results in an array of strings.

(NOTE: Not actually intended as a mixin itself.)

Example:

----
int i;
void func1(){}
// void func2(int x){} // This one doesn't work ATM due to DMD Bug #2867

enum string[] foo = templateArgsToStrings!(i, func1);
assert(foo == ["i"[], "func1"]);
----

+/
/+template templateArgsToStrings(args...)
{
	static if(args.length == 0)
		enum string[] templateArgsToStrings = [];
	else
		enum string[] templateArgsToStrings =
			(	// Ugly hack for DMD Bug #2867
				(args[0].stringof.length>2 && args[0].stringof[$-2..$]=="()")?
					args[0].stringof[0..$-2] :
					args[0].stringof[] 
			)
			~ templateArgsToStrings!(args[1..$]);
}

unittest
{
	int i;
	void func1(){}
	//void func2(int x){} // This one doesn't work ATM due to DMD Bug #2867

	enum string[] templateArgsToStrings_test = templateArgsToStrings!(i, func1);
	mixin(deferEnsure!(`templateArgsToStrings_test`, `_ == ["i", "func1"]`));
}+/
