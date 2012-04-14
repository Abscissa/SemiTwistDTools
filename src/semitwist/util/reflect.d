// SemiTwist Library
// Written in the D programming language.

module semitwist.util.reflect;

import std.compiler;
import std.conv;
import std.demangle;
import std.functional;
import std.traits;
import std.typetuple;

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
	auto startIndex = ctfe_find(mangled, "_D");
	if(startIndex == mangled.length)
		startIndex = 0;
	
	return demangle(mangled[startIndex..$]);
}

/// Checks if value 'a' is, or is implicitly castable to, or is derived from type T.
template isType(T)
{
	bool isType(Ta)(Ta a)
	{
		static if(is(Ta : T))
			return true;

		else static if(!is(Ta : Object) || !is(T : Object))
			return false;

		else static if(!__traits(compiles, cast(T)a))
			return false;

		else
			return cast(T)a !is null;
	}
}

mixin(unittestSemiTwistDLib("isType", q{

	class Foo {}
	class Bar {}
	auto f = new Foo();

	mixin(deferAssert!(q{ isType!int(3)     }));
	mixin(deferAssert!(q{ isType!double(3)  }));
	mixin(deferAssert!(q{ !isType!string(3) }));
	mixin(deferAssert!(q{ !isType!Foo(3)    }));
	
	mixin(deferAssert!(q{ isType!Foo(f)               }));
	mixin(deferAssert!(q{ isType!Object(f)            }));
	mixin(deferAssert!(q{ isType!Foo( cast(Object)f ) }));
	mixin(deferAssert!(q{ !isType!Bar(f)              }));
	mixin(deferAssert!(q{ !isType!int(f)              }));

}));

/// Checks if value 'a' is, or is implicitly castable to, or is derived from any of the TList types.
/// Example: assert( isAnyType!(Foo, Bar, Baz)(foo) );
template isAnyType(TList...)
{
	bool isAnyType(T)(T val)
	{
		foreach(TTest; TList)
		if(isType!TTest(val))
			return true;
		
		return false;
	}
}

/// Checks if value 'a' is, or is implicitly castable to, or is derived from all of the TList types.
/// Example: assert( isAllTypes!(Foo, Bar, Baz)(foo) );
template isAllTypes(TList...)
{
	bool isAllTypes(T)(T val)
	{
		foreach(TTest; TList)
		if(!isType!TTest(val))
			return false;
		
		return true;
	}
}

mixin(unittestSemiTwistDLib("isAnyType / isAllTypes", q{

	class Foo {}
	class Bar {}
	auto f = new Foo();

	mixin(deferAssert!(q{  isAnyType !(int, double)(3) }));
	mixin(deferAssert!(q{  isAllTypes!(int, double)(3) }));
	mixin(deferAssert!(q{  isAnyType !(int, Foo)(3)    }));
	mixin(deferAssert!(q{ !isAllTypes!(int, Foo)(3)    }));
	mixin(deferAssert!(q{ !isAnyType !(Foo, Object)(3) }));

	mixin(deferAssert!(q{  isAnyType !(Foo, Object)(f) }));
	mixin(deferAssert!(q{  isAllTypes!(Foo, Object)(f) }));
	mixin(deferAssert!(q{  isAnyType !(int, Foo)(f)    }));
	mixin(deferAssert!(q{ !isAllTypes!(int, Foo)(f)    }));
	mixin(deferAssert!(q{  isAnyType !(Bar, Foo)(f)    }));
	mixin(deferAssert!(q{ !isAllTypes!(Bar, Foo)(f)    }));
	mixin(deferAssert!(q{ !isAnyType !(int, Bar)(f)    }));

}));

/++
Calls .stringof on each argument then returns
the results in an array of strings.

(NOTE: Not actually intended as a mixin itself.)

Example:

----
int i;
void func1(){}
// void func2(int x){} // This one doesn't work ATM due to DMD Bug #2867

immutable string[] foo = templateArgsToStrings!(i, func1);
assert(foo == ["i"[], "func1"]);
----

+/
/+template templateArgsToStrings(args...)
{
	static if(args.length == 0)
		immutable string[] templateArgsToStrings = [];
	else
		immutable string[] templateArgsToStrings =
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

	immutable string[] templateArgsToStrings_test = templateArgsToStrings!(i, func1);
	mixin(deferEnsure!(`templateArgsToStrings_test`, `_ == ["i", "func1"]`));
}+/

/// So you can tell whether to define toHash as "nothrow @safe".
static if(vendor == Vendor.digitalMars && version_minor <= 58)
	enum useNoThrowSafeToHash = false; // Old compiler: DMD 2.058 and below
else
	enum useNoThrowSafeToHash = true; // New compiler: DMD 2.059 and up
