// SemiTwist D Tools
// Tests: Defer Assert Test
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Make sure to pass "-debug=deferAssertTest_unittest" to DMD.

This has been tested to work with DMD 2.052
+/

module semitwist.apps.tests.deferAssertTest.main;

import semitwist.util.all;

void main()
{
	flushAsserts();
	// Main program code here
}

alias unittestSection!"deferAssertTest_unittest" unittestDeferAssertTest;

mixin(unittestDeferAssertTest(q{

	int foo = 2;
	string bar = "hello";

	bool throwsException()
	{
		throw new Exception("Some exception");
	}
	
    // Improvement to mixin syntax would be nice.
	// Also, my editor doesn't know that backticks indicate a string,
	// so it's still properly highlighted as code :)
	//mixin(deferAssert!(`foo == 3 || foo > 5`, "foo is bad"));
	assertPred!("a == 3 || a > 5", "foo is bad")(foo);
	
	//mixin(deferAssert!(`2 + 2 == 4`, "Basic arithmetic"));
	//assertPred!(q{ 2 + 2 == a }, "Basic arithmetic")(4);
	assertPred!"+"(2, 2, 4, "Basic arithmetic");
	assertPred!"+"(2, 2, 5, "Bad arithmetic");
	
	//mixin(deferAssert!(`false`));
	assertPred!"a"(false);

	//mixin(deferAssert!(`throwsException()`, "Exceptions are handled"));
//	assertPred!q{ throwsException() }(null, "Exceptions are handled");
	//assertPred!(q{ a }, "Exceptions are handled")(throwsException());
	
	mixin(deferEnsure!(`foo`, `_ == 3 || _ > 5`, "ensure foo failed"));
	mixin(deferEnsure!(`foo`, `_ > 0`));
	mixin(deferEnsure!(`bar`, `_ == "hola"`));
	mixin(deferEnsure!(`2+2`, `_ == 4`));
	mixin(deferEnsure!(`throwsException()`, `!_`, "Exceptions are handled"));
	mixin(deferEnsure!(`false`, `_ == throwsException()`, "Exceptions are handled"));
	
	mixin(deferEnsureThrows!(`throw new Exception("Hello");`, Exception));
	//mixin(deferEnsureThrows!(`throw new Object();`, Exception, "Wrong type thrown!"));
	//mixin(deferEnsureThrows!(`throw new Exception("Hello");`, Object, "Wrong type thrown!"));

}));

/++
Program output:

src\semitwist\apps\tests\deferAssertTest\main.d(36): Assert Failed (foo == 3 || foo > 5): foo is bad
src\semitwist\apps\tests\deferAssertTest\main.d(38): Assert Failed (false)
src\semitwist\apps\tests\deferAssertTest\main.d(39): Assert Threw (throwsException()): Exceptions are handled:
Threw: object.Exception: Some exception
src\semitwist\apps\tests\deferAssertTest\main.d(41): Ensure Failed: ensure foo failed
Expression 'foo':
Expected: _ == 3 || _ > 5
Actual: 2
src\semitwist\apps\tests\deferAssertTest\main.d(43): Ensure Failed
Expression 'bar':
Expected: _ == "hola"
Actual: hello
src\semitwist\apps\tests\deferAssertTest\main.d(45): Ensure Threw: Exceptions are handled:
Expression 'throwsException()':
Expected: !_
Threw: object.Exception: Some exception
src\semitwist\apps\tests\deferAssertTest\main.d(46): Ensure Threw: Exceptions are handled:
Expression 'false':
Expected: _ == throwsException()
Threw: object.Exception: Some exception
src\semitwist\apps\tests\deferAssertTest\main.d(49): Ensure Throw Failed: Wrong type thrown!
Statement 'throw new Object();':
Expected: object.Exception
Actual:   object.Object: object.Object
src\semitwist\apps\tests\deferAssertTest\main.d(50): Ensure Throw Failed: Wrong type thrown!
Statement 'throw new Exception("Hello");':
Expected: object.Object
Actual:   object.Exception: Hello
core.exception.AssertError@src\semitwist\util\deferAssert.d(171): 9 Assert Failures

+/
