// SemiTwist D Tools
// Run Unittests
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This runs the SemiTwist D Tools unit tests.

This has been tested to work with DMD 2.058 through 2.060
+/

module semitwist.apps.tests.unittests.main;

import semitwist.cmd.all;

version(unittest) {} else import std.stdio;

void main()
{
	flushAsserts();
	
	version(unittest) {}
	else
	{
		writeln("This is the release build of the SemiTwistDTools unittests.");
		writeln("Naturally, it doesn't do anything.");
		writeln();
		writeln("Run 'semitwist-unittests-debug' instead.");
	}
}
