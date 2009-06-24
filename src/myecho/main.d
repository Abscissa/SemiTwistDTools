// SemiTwist Library: My Echo
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This is just used to help test the "exec" part of semitwist.cmd.CommandLine.
Windows "echo" is built into the commandline and isn't an actual executable,
so tango.sys.Process, and therefore semitwist.cmd.CommandLine, can't
launch it.

Uses:
- DMD 1.043
- Tango 0.99.8
*/

//TODO: Move this and seterrlevel into their own miniapps project group/repo
module myecho.main;

import tango.io.Stdout;
import tango.text.Util;

void main(char[][] args)
{
	Stdout( args[1..$].join(" ") ).newline;
}
