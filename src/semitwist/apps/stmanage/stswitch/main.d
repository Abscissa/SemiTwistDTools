// SemiTwist D Tools
// STManage: STSwitch
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

IGNORE THIS APP FOR NOW, IT IS NOT USABLE YET

This has been tested to work with:
  - DMD 1.043 / Tango 0.99.8 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / Rebuild 0.76
*/

module semitwist.apps.stmanage.stswitch.main;

import tango.io.Stdout;
import semitwist.util.all;
import semitwist.cmd.all;

int main(char[][] args)
{
	flushAsserts();

	mixin(traceVal!(
		"enumToString(os)",
		"objExt", "libExt", "exeExt", "pathSep"
	));

	return 0;
}
