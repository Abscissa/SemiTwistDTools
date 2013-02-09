// SemiTwist D Tools
// MiniApps: pwd (Print Working Directory)
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Windows doesn't have a 'pwd' command per se. Instead, it just has:
	echo %CD%
But this 'pwd' may be easier to remember. (Well, actually it's
'semitwist-pwd', but you can rename the executable however you wish.)

This has been tested to work with DMD 2.058 through 2.062
+/

module semitwist.apps.miniapps.pwd.main;

import std.path;
import std.stdio;

void main()
{
	writeln(absolutePath("."));
}
