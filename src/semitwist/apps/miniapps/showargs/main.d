// SemiTwist D Tools
// MiniApps: Show Args
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with DMD 2.052 through 2.055
+/

module semitwist.apps.miniapps.showargs.main;

import std.stdio;

void main(string[] args)
{
	writefln("args.length: %s", args.length);
	foreach(int i, string arg; args)
		writefln("args[%s]: %s", i, arg);
}
