// SemiTwist Library: Command Line Parser Test
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module cmdparsertest.main;

import tango.io.Stdout;

import semitwist.util;
import semitwist.cmdlineparser;

void main(char[][] args)
{
	bool help;
	bool detailhelp;
	bool myBool;
	bool myFlag;
	bool myFlagX=true;
	char[] myStr;
	char[] myStrX="default";
	bool _odd98_name;
	
	int myInt;
	char[] required="hni";
	char[][] switchless;
	
	char[] myEnum;
	
	auto cmd = new CmdLineParser();
	mixin(defineArg!(cmd, "help",        help,        ArgFlag.Optional,   "Displays a help summary and exits" ));
	mixin(defineArg!(cmd, "detail",      detailhelp,  ArgFlag.Optional,   "Displays a detailed help message and exits" ));
	mixin(defineArg!(cmd, "myBool",      myBool,      ArgFlag.Optional,   "My Boolean" ));
	mixin(defineArg!(cmd, "myFlag",      myFlag,      ArgFlag.Optional,   "My Flag"    ));
	mixin(defineArg!(cmd, "myFlagX",     myFlagX,     ArgFlag.Optional,   "My Flag X"  ));
	mixin(defineArg!(cmd, "myStr",       myStr,       ArgFlag.Optional,   "My String"  ));
	mixin(defineArg!(cmd, "myStrX",      myStrX,      ArgFlag.Optional|ArgFlag.ToLower, "My Case-Insensitive String X"));
	mixin(defineArg!(cmd, "_odd98_name", _odd98_name, ArgFlag.Optional,   "Odd name"   ));
	mixin(defineArg!(cmd, "myInt",       myInt,       ArgFlag.Optional,   "My Int"));
	mixin(defineArg!(cmd, "r",           required,    ArgFlag.Required,   "This is required, and internal name differs"));
	mixin(defineArg!(cmd, "switchless",  switchless,  ArgFlag.Switchless, "Switchless Multiple" ));
	mixin(defineArg!(cmd, "myEnum",      myEnum,      ArgFlag.Optional,   `My Enum ("tea" or "coffee")` ));
	
	char[][] allowableEnum;
	allowableEnum ~= "tea";
	allowableEnum ~= "coffee";
	_cmdarg_myEnum.setAllowableValues(allowableEnum);
	
	if((!cmd.parse(args) && !detailhelp) || help)
	{
		Stdout.formatln("");
		Stdout.format(cmd.getUsage(18));
		return;
	}
	if(detailhelp)
	{
		Stdout.formatln("");
		Stdout.format(cmd.getDetailedUsage());
		return;
	}
	Stdout.formatln("");
	
	mixin(traceVal!(
		"myBool ",
		"myFlag ",
		"myFlagX",
		"myStr  ",
		"myStrX ",
		"_odd98_name",
		"myInt      ",
		"required   ",
		"switchless ",
		"myEnum"
	));
}
