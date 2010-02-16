// SemiTwist D Tools
// MiniApps: My Echo
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This was created to help test the "exec" part of semitwist.cmd.CommandLine
from semitwistlib. Windows "echo" is built into the commandline and isn't
an actual executable, so tango.sys.Process, and therefore
semitwist.cmd.CommandLine, can't launch it.

This has been tested to work with:
  - DMD 1.056 / Tango 0.99.9 / Rebuild 0.76
  - DMD 1.056 / Tango 0.99.9 / xfBuild 0.4
+/

module semitwist.apps.miniapps.myecho.main;

import tango.io.Stdout;
import tango.text.Util;
import semitwist.util.compat.all;

void main(string[] args)
{
	Stdout( args[1..$].join(" ") ).newline;
}
