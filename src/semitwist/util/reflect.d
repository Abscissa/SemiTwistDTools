// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.reflect;

import tango.core.Traits;

import semitwist.util.ctfe;

/**
If you have a class MyClass(T), then nameof!(MyClass) will return "MyClass".

One benefit of this is that you can do things like:
	mixin("auto obj = new "~nameof!(MyClass)~"!(int)()");
and the "MyClass" will be checked by the compiler, alerting you immediately
if the class name changes, helping you keep such strings up-to-date.
*/

template nameof(alias T)
{
	const char[] nameof = T.stringof[0..ctfe_find(T.stringof, '(')];
}

template isAnyArrayType(T)
{
	const bool isAnyArrayType =
		isArray!(T) ||
		isAssocArrayType!(T);
}

// From Tango trunk
template isArray(T)
{
	static if (is( T U : U[] ))
		const bool isArray=true;
	else
		const bool isArray=false;
}

// From Tango trunk
template KeyTypeOfAA(T){
	alias typeof(T.init.keys[0]) KeyTypeOfAA;
}

// From Tango trunk
template ValTypeOfAA(T){
	alias typeof(T.init.values[0]) ValTypeOfAA;
}

// If T is a static array, it's changed to a dynamic array, otherwise just returns T.
template PreventStaticArray(T)
{
	static if(isArray!(T))
		private alias ElementTypeOfArray!(T)[] PreventStaticArray;
	else
		private alias T PreventStaticArray;
}
