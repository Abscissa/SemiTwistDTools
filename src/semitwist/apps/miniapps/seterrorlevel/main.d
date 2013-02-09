// SemiTwist D Tools
// MiniApps: Set Error Level
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Sets the errorlevel to any value. Could be useful in Windows batch scripts.

Calling 'seterrorlevel' by itself will set the errorlevel to 0.
Calling 'seterrorlevel' with an invalid value will result in an error message
and set the errorlevel to 1.

This has been tested to work with DMD 2.058 through 2.062
+/

module semitwist.apps.miniapps.seterrorlevel.main;

import std.conv;

int main(string[] args)
{
	if(args.length < 2)
		return 0;
	
	return to!int(args[1]);
}
