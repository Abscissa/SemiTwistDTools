// SemiTwist D Tools
// STManage: STSwitch
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

IGNORE THIS APP FOR NOW, IT IS NOT USABLE YET

This has been tested to work with DMD 2.049/2.050
+/

module semitwist.apps.stmanage.stswitch.main;

import std.stdio;
import semitwist.cmd.all;

int main(string[] args)
{
	flushAsserts();

	mixin(traceVal!(
		"enumOSToString(os)",
		"objExt", "libExt", "exeExt", "pathSep"
	));

	return 0;
}
