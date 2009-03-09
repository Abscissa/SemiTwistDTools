// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.reflect;

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
