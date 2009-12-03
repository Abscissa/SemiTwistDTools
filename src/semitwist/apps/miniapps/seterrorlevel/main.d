// SemiTwist D Tools
// MiniApps: Set Error Level
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.043 / Tango 0.99.8 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / xfBuild 0.4
+/

module semitwist.apps.miniapps.seterrorlevel.main;

import tango.util.Convert;

int main(char[][] args)
{
	if(args.length < 2)
		return 0;
	
	return to!(int)(args[1], 0);
}
