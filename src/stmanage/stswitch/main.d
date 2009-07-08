// SemiTwist D Tools
// STManage: STSwitch
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Prerequisites for Building:
- [Required]    DMD 1.043 (LDC untested)
- [Required]    Tango 0.99.8
- [Recommended] Rebuild 0.76
DMD 1.044+ with Tango Trunk might work, but is untested.
Rebuild 0.78 might work, but is quirky and not recommended.
*/

module stmanage.stswitch.main;

import tango.io.Stdout;
import semitwist.util.all;
import semitwist.cmd.all;
import semitwist.os; // TODO: Include this in cmd.all
import semitwist.ver; // TODO: Include this in cmd.all

int main(char[][] args)
{
	flushAsserts();

	mixin(traceVal!(
		"enumToString(os)",
		"objExt", "libExt", "exeExt", "pathSep"
	));

	return 0;
}
