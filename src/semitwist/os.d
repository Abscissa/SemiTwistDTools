// SemiTwist D Tools: Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

//TODO: Move this whole module into the semitwist.util package.

module semitwist.os;

import semitwist.util.all;

//TODO: Move this function to a more appropriate semitwist.util module
private char[] genEnum(char[] name, char[][] values)
{
	return
		"enum "~name~" {"~values.ctfe_join(", ")~"}\n"~
		"const uint "~name~"_length = "~ctfe_i2a(values.length)~";\n"~
		_genEnumToString(name, values);
}

//TODO: Move this function to a more appropriate semitwist.util module
// The function this generates could probably be improved.
private char[] _genEnumToString(char[] enumName, char[][] enumValues)
{
	char[] value = "";
	
	foreach(char[] enumValue; enumValues)
		value ~= "    if(value=="~enumName~"."~enumValue~") return \""~enumValue~"\";\n";
	
	value =
		"char[] enumToString("~enumName~" value)\n"~
		"{\n"~
		value~
		`    throw new Exception("Internal Error: Unhandled value in `~enumName~`ToString");`~"\n"~
		"}\n";
	
	return value;
}

private char[] genOSParam(char[] name, char[][] values)
{
	assert(values.length == OS_length, "Wrong number of OSes provided for OS param '"~name~"'");
	
	char[] str = "";
	foreach(int i, char[] value; values)
	{
		char[] osStr = enumToString(cast(OS)i);

		//TODO: change `"~value~"` to "~toStringLiteral(value)~"
		str ~=
			"const char[] "~name~"_"~osStr~" = `"~value~"`;\n"~
			"static if(os == OS."~osStr~")\n"~
			"    const char[] "~name~" = "~name~"_"~osStr~";\n";
	}
	return str;
}

mixin(genEnum("OS", ["Windows"[], "Linux", "BSD"]));
version(Windows) const OS os = OS.Windows;
version(linux)   const OS os = OS.Linux;
version(freebsd) const OS os = OS.BSD;

mixin(genOSParam("objExt",  [ ".obj"[], ".o", ".o" ]));
mixin(genOSParam("libExt",  [ ".lib"[], ".a", ".a" ]));
mixin(genOSParam("exeExt",  [ ".exe"[], "",   ""   ]));
mixin(genOSParam("pathSep", [ "\\"  [], "/",  "/"  ]));

mixin(genOSParam("selfExeLink", [ ""[], "/proc/self/exe", "/proc/curproc/file" ]));
