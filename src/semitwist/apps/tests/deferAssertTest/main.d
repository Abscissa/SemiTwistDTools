// SemiTwist D Tools
// Tests: Defer Assert Test
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.043 / Tango 0.99.8 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / xfBuild 0.4
+/

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

/++
Program output:

src\semitwist\apps\tests\deferAssertTest\main.d(37): Assert Failed (foo == 3 || foo > 5): foo is bad
src\semitwist\apps\tests\deferAssertTest\main.d(39): Assert Failed (false)
src\semitwist\apps\tests\deferAssertTest\main.d(40): Assert Threw (throwsException()): Exceptions are handled:
Threw: object.Exception: Some exception
src\semitwist\apps\tests\deferAssertTest\main.d(42): Ensure Failed: ensure foo failed
Expression 'foo':
Expected: _ == 3 || _ > 5
Actual: 2
src\semitwist\apps\tests\deferAssertTest\main.d(44): Ensure Failed
Expression 'bar':
Expected: _ == "hola"
Actual: hello
src\semitwist\apps\tests\deferAssertTest\main.d(46): Ensure Threw: Exceptions are handled:
Expression 'throwsException()':
Expected: !_
Threw: object.Exception: Some exception
src\semitwist\apps\tests\deferAssertTest\main.d(47): Ensure Threw: Exceptions are handled:
Expression 'false':
Expected: _ == throwsException()
Threw: object.Exception: Some exception
src\semitwist\apps\tests\deferAssertTest\main.d(50): Ensure Throw Failed: Wrong type thrown!
Statement 'throw new Object();':
Expected: object.Exception
Actual:   object.Object: object.Object
src\semitwist\apps\tests\deferAssertTest\main.d(51): Ensure Throw Failed: Wrong type thrown!
Statement 'throw new Exception("Hello");':
Expected: object.Object
Actual:   object.Exception: Hello
tango.core.Exception.AssertException@src\semitwist\util\deferAssert.d(170): 9 Assert Failures

+/
