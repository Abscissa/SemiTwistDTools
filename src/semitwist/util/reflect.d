// SemiTwist Library
// Written in the D programming language.

module semitwist.util.reflect;

import tango.core.Traits;
import tango.core.Version;

import semitwist.util.all;
import semitwist.util.compat.all;

/**
If you have a class MyClass(T), then nameof!(MyClass) will return "MyClass".

One benefit of this is that you can do things like:
	mixin("auto obj = new "~nameof!(MyClass)~"!(int)()");
or
	throw new Exception("Something's wrong with a "~nameof!(MyClass)~" object!";
and the "MyClass" will be checked by the compiler, alerting you immediately
if the class name changes, helping you keep such strings up-to-date.
*/

template nameof(alias T)
{
	const string nameof = T.stringof[0..ctfe_find(T.stringof, '(')];
}

template isAnyArrayType(T)
{
	const bool isAnyArrayType =
		isArrayType!(T) ||
		isAssocArrayType!(T);
}

// If T is a static array, it's changed to a dynamic array, otherwise just returns T.
template PreventStaticArray(T)
{
	static if(isArrayType!(T))
		private alias ElementTypeOfArray!(T)[] PreventStaticArray;
	else
		private alias T PreventStaticArray;
}

template callableExists(T)
{
	static if(is(T) && isCallableType(typeof(T)))
		const bool callableExists = true;
	else
		const bool callableExists = false;
}

/// Returns the type that a T would evaluate to in an expression.
/// It's like ReturnTypeOf, except you can use it when
/// you neither know nor care whether T actually is callable.
/// Ie: If T is callable (such as a function or property),
///     then this returns T's return type,
///     otherwise, this just returns T's type.
template ExprTypeOf(T)
{
    static if(isCallableType!(T))
        alias ReturnTypeOf!(T) ExprTypeOf;
    else
        alias T ExprTypeOf;
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

const string[] foo = templateArgsToStrings!(i, func1);
assert(foo == ["i"[], "func1"]);
----

+/
template templateArgsToStrings(args...)
{
	static if(args.length == 0)
		const string[] templateArgsToStrings = [];
	else
		const string[] templateArgsToStrings =
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

	const string[] templateArgsToStrings_test = templateArgsToStrings!(i, func1);
	mixin(deferEnsure!(`templateArgsToStrings_test`, `_ == ["i"[], "func1"]`));
}
