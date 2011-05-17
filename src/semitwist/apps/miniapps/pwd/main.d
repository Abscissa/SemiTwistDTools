// SemiTwist D Tools
// MiniApps: pwd (Print Working Directory)
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

AFAIK, Windows doesn't have a 'pwd' command.
So this might occasionally be useful.

This has been tested to work with DMD 2.052 and 2.053
+/

module semitwist.apps.miniapps.pwd.main;

import std.path;
import std.stdio;

void main()
{
	writeln(rel2abs("."));
}
