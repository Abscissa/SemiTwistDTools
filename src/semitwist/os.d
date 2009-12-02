// SemiTwist D Tools: Library
// Written in the D programming language.

//TODO: Move this whole module into the semitwist.util package.

module semitwist.os;

import semitwist.util.all;

private char[] genOSParam(char[] name, char[][] values)
{
	assert(values.length == OS_length, "Wrong number of OSes provided for OS param '"~name~"'");
	
	char[] str = "";
	foreach(int i, char[] value; values)
	{
		char[] osStr = enumToString(cast(OS)i);

		str ~=
			"const char[] "~name~"_"~osStr~" = "~escapeDDQS(value)~";\n"~
			"static if(os == OS."~osStr~")\n"~
			"    const char[] "~name~" = "~name~"_"~osStr~";\n";
	}
	return str;
}

mixin(genEnum("OS", ["Windows"[], "Linux", "BSD"]));
version(Windows) const OS os = OS.Windows;
version(linux)   const OS os = OS.Linux;
version(freebsd) const OS os = OS.BSD;

mixin(genOSParam("objExt",  [ ".obj" [], ".o", ".o" ]));
mixin(genOSParam("libExt",  [ ".lib" [], ".a", ".a" ]));
mixin(genOSParam("exeExt",  [ ".exe" [], "",   ""   ]));
mixin(genOSParam("pathSep", [ "\\"   [], "/",  "/"  ]));
mixin(genOSParam("nlStr",   [ "\r\n" [], "\n", "\n" ]));
const char[] nlStr_Mac9 = "\r";

mixin(genOSParam("selfExeLink", [ ""[], "/proc/self/exe", "/proc/curproc/file" ]));
