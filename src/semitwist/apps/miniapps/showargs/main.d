// SemiTwist D Tools
// MiniApps: Show Args
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.043 / Tango 0.99.8 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / xfBuild 0.4
*/

module semitwist.apps.miniapps.showargs.main;

import tango.io.Stdout;

void main(char[][] args)
{
	Stdout.formatln("args.length: {}", args.length);
	foreach(int i, char[] arg; args)
		Stdout.formatln("args[{}]: {}", i, arg);
}
