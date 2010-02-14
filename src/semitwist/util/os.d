// SemiTwist D Tools: Library
// Written in the D programming language.

module semitwist.util.os;

import semitwist.util.all;
import semitwist.util.compat.all;

private string genOSParam(string name, string[] values)
{
	assert(values.length == OS_length, "Wrong number of OSes provided for OS param '"~name~"'");
	
	string str = "";
	foreach(int i, string value; values)
	{
		string osStr = enumToString(cast(OS)i);

		str ~=
			"const string "~name~"_"~osStr~" = "~escapeDDQS(value)~";\n"~
			"static if(os == OS."~osStr~")\n"~
			"    const string "~name~" = "~name~"_"~osStr~";\n";
	}
	return str;
}

mixin(genEnum("OS", ["Windows"[], "Linux", "BSD", "OSX"]));
version(Windows) const OS os = OS.Windows;
version(linux)   const OS os = OS.Linux;
version(freebsd) const OS os = OS.BSD;
version(OSX)     const OS os = OS.OSX;

mixin(genOSParam("objExt",  [ ".obj" [], ".o", ".o", ".o" ]));
mixin(genOSParam("libExt",  [ ".lib" [], ".a", ".a", ".a" ]));
mixin(genOSParam("exeExt",  [ ".exe" [], "",   "",   ""   ]));
mixin(genOSParam("pathSep", [ "\\"   [], "/",  "/",  "/"  ]));
mixin(genOSParam("nlStr",   [ "\r\n" [], "\n", "\n", "\n" ]));
const string nlStr_Mac9 = "\r";

mixin(genOSParam("selfExeLink", [ ""[], "/proc/self/exe", "/proc/curproc/file", "/proc/curproc/file" ]));
