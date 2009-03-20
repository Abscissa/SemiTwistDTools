module nonFatalAssertTest.main;

import semitwist.util.nonFatalAssert;

void main()
{
	FatalizeAsserts();
	// Main program code here
}

unittest
{
	int foo = 2;
	
	// *REALLY* need a way for a template to automatically get
	// the file/line of instantiation.
    // Improvement to mixin syntax would also be nice
	// Also, my editor doesn't know that backticks indicate a string,
	// so it's still properly highlighted as code :)
	mixin(NonFatalAssert!(__LINE__, __FILE__, `foo == 3 || foo > 5`, "foo is bad"));
	mixin(NonFatalAssert!(__LINE__, __FILE__, `2 + 2 == 4`, "Basic arithmetic"));
	mixin(NonFatalAssert!(__LINE__, __FILE__, `false`));
}
