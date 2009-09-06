// SemiTwist D Tools
// Tests: Defer Assert Test
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Uses:
- DMD 1.043
- Tango 0.99.8
*/

module semitwist.apps.tests.deferAssertTest.main;

import semitwist.util.all;

void main()
{
	flushAsserts();
	// Main program code here
}

unittest
{
	int foo = 2;
	char[] bar = "hello";

	bool throwsException()
	{
		throw new Exception("Some exception");
	}
	
    // Improvement to mixin syntax would be nice.
	// Also, my editor doesn't know that backticks indicate a string,
	// so it's still properly highlighted as code :)
	mixin(deferAssert!(`foo == 3 || foo > 5`, "foo is bad"));
	mixin(deferAssert!(`2 + 2 == 4`, "Basic arithmetic"));
	mixin(deferAssert!(`false`));
	mixin(deferAssert!(`throwsException()`, "Exceptions are handled"));
	
	mixin(deferEnsure!(`foo`, `_ == 3 || _ > 5`, "ensure foo failed"));
	mixin(deferEnsure!(`foo`, `_ > 0`));
	mixin(deferEnsure!(`bar`, `_ == "hola"`));
	mixin(deferEnsure!(`2+2`, `_ == 4`));
	mixin(deferEnsure!(`throwsException()`, `!_`, "Exceptions are handled"));
	mixin(deferEnsure!(`false`, `_ == throwsException()`, "Exceptions are handled"));
	
	mixin(deferEnsureThrows!(`throw new Exception("Hello");`, Exception));
	mixin(deferEnsureThrows!(`throw new Object();`, Exception, "Wrong type thrown!"));
	mixin(deferEnsureThrows!(`throw new Exception("Hello");`, Object, "Wrong type thrown!"));
}
