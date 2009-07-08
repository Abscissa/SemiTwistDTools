// SemiTwist D Tools: Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.os;

import semitwist.util.all;

//TODO: Move this to semitwist.util
private char[] genEnum(char[] name, char[][] values)
{
	return
		"enum "~name~" {"~values.ctfe_join(", ")~"}\n"~
		"const uint "~name~"_length = "~ctfe_i2a(values.length)~";\n"~
		_genEnumToString(name, values);
}

//TODO: Move this to semitwist.util
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

mixin(genEnum("OS", ["Windows"[], "Unix"]));
version(Windows) const OS os = OS.Windows;
version(linux)   const OS os = OS.Unix;

mixin(genOSParam("objExt",  [ ".obj"[], ".o" ]));
mixin(genOSParam("libExt",  [ ".lib"[], ".a" ]));
mixin(genOSParam("exeExt",  [ ".exe"[], ""   ]));
mixin(genOSParam("pathSep", [ "\\"  [], "/"  ]));
