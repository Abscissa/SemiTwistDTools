// SemiTwist D Tools
// MiniApps: Set Error Level
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Uses:
- DMD 1.043
- Tango 0.99.8
*/

module miniapps.seterrorlevel.main;

import tango.util.Convert;

int main(char[][] args)
{
	if(args.length < 2)
		return 0;
	
	return to!(int)(args[1], 0);
}
