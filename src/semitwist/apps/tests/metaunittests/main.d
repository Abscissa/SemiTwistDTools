// SemiTwist D Tools
// Run Meta-Unittests
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This runs the unittests for things that SemiTwist D Tools's
regular unittests rely on. This could be useful if a bug causes
the regular unittests to not even compile.

This has been tested to work with DMD 2.052
+/

module semitwist.apps.tests.metaunittests.main;

import semitwist.cmd.all;

version(unittest) {} else import std.stdio;

void main()
{
	version(unittest) {}
	else
	{
		writeln("This is the release build of the SemiTwistDTools Meta-Unittests.");
		writeln("Naturally, it doesn't do anything.");
		writeln();
		writeln("Run 'semitwist-metaunittests-debug' instead.");
	}
}
