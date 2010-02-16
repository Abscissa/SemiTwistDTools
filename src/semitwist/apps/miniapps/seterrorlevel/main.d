// SemiTwist D Tools
// MiniApps: Set Error Level
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.056 / Tango 0.99.9 / Rebuild 0.76
  - DMD 1.056 / Tango 0.99.9 / xfBuild 0.4
+/

module semitwist.apps.miniapps.seterrorlevel.main;

import tango.util.Convert;
import semitwist.util.compat.all;

int main(string[] args)
{
	if(args.length < 2)
		return 0;
	
	return to!(int)(args[1], 0);
}
