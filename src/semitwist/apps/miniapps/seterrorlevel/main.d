// SemiTwist D Tools
// MiniApps: Set Error Level
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with DMD 2.049/2.050
+/

module semitwist.apps.miniapps.seterrorlevel.main;

import std.conv;

int main(string[] args)
{
	if(args.length < 2)
		return 0;
	
	try
		return to!int(args[1]);
	catch(Throwable e)
		return 0;
}
