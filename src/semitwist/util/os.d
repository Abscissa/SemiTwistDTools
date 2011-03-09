// SemiTwist D Tools: Library
// Written in the D programming language.

module semitwist.util.os;

import semitwist.util.all;

private string genOSParam(string name, string[] values)
{
	assert(values.length == OS_length, "Wrong number of OSes provided for OS param '"~name~"'");
	
	string str = "";
	foreach(int i, string value; values)
	{
		string osStr = enumOSToString(cast(OS)i);

		str ~=
			"enum string "~name~"_"~osStr~" = "~escapeDDQS!string(value)~";\n"~
			"static if(os == OS."~osStr~")\n"~
			"    enum string "~name~" = "~name~"_"~osStr~";\n";
	}
	return str;
}

mixin(genEnum("OS", ["Windows"[], "Linux", "BSD", "OSX"]));
version(Windows) enum OS os = OS.Windows;
version(linux)   enum OS os = OS.Linux;
version(freebsd) enum OS os = OS.BSD;
version(OSX)     enum OS os = OS.OSX;

mixin(genOSParam("objExt",  [ ".obj" [], ".o", ".o", ".o" ]));
mixin(genOSParam("libExt",  [ ".lib" [], ".a", ".a", ".a" ]));
mixin(genOSParam("exeExt",  [ ".exe" [], "",   "",   ""   ]));
mixin(genOSParam("pathSep", [ "\\"   [], "/",  "/",  "/"  ]));
mixin(genOSParam("nlStr",   [ "\r\n" [], "\n", "\n", "\n" ]));
enum nlStr_Mac9 = "\r";

mixin(genOSParam("selfExeLink", [ ""[], "/proc/self/exe", "/proc/curproc/file", "/proc/curproc/file" ]));
