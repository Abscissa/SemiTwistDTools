// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.util.nonFatalAssert;

import tango.io.Stdout;

/**
Sounds like a contradiction of terms, but this is just
intended to allow unittests to output ALL failures instead
of only outputting the first one and then stopping.
*/
//Automatic __LINE__ and __FILE__ don't work
//template NonFatalAssert(int line = __LINE__, char[] file = __FILE__)
template NonFatalAssert(int line, char[] file)
{
	bool NonFatalAssert(bool cond, char[] msg="")
	{
		if(!cond)
		{
			nonFatalAssertCount++;
			Stdout.formatln("{}({}): Assert Failure{}", //"{}({}): Assert Failure ({}){}",
			                file, line,
//						    cond.stringof,
						    msg=="" ? "" : ": " ~ msg);
		}
		
		return cond;
	}
}
private uint nonFatalAssertCount=0;
uint getNonFatalAssertCount()
{
	return nonFatalAssertCount;
}
void resetNonFatalAssertCount()
{
	nonFatalAssertCount = 0;
}
