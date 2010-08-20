// SemiTwist D Tools
// MiniApps: My Echo
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This was created to help test the "exec" part of semitwist.cmd.CommandLine
from semitwistlib. Windows "echo" is built into the commandline and isn't
an actual executable, so std.process, and therefore
semitwist.cmd.CommandLine, can't launch it.

This has been tested to work with DMD 2.048
+/

module semitwist.apps.miniapps.myecho.main;

import std.stdio;
import std.string;

void main(string[] args)
{
	writeln( args[1..$].join(" ") );
}
