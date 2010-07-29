// SemiTwist D Tools
// Tests: Command Line Parser Test
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.056 / Tango 0.99.9 / Rebuild 0.76
  - DMD 1.056 / Tango 0.99.9 / xfBuild 0.4
+/

module semitwist.apps.tests.cmdparsertest.main;

import tango.io.Stdout;

import semitwist.util.all;
import semitwist.cmdlineparser;
import semitwist.util.compat.all;

void main(string[] args)
{
	bool help;
	bool detailHelp;
	bool myBool;
	bool myFlag;
	bool myFlagX=true;
	string myStr;
	string myStrX="default";
	bool _odd98_name;
	
	int myInt;
	string required="hni";
	string[] switchless;
	
	string myEnum;
	
	auto cmd = new CmdLineParser();
	mixin(defineArg!(cmd, "help",        help,        ArgFlag.Optional,   "Displays a help summary and exits" ));
	mixin(defineArg!(cmd, "detail",      detailHelp,  ArgFlag.Optional,   "Displays a detailed help message and exits" ));
	mixin(defineArg!(cmd, "myBool",      myBool,      ArgFlag.Optional,   "My Boolean" ));
	mixin(defineArg!(cmd, "myFlag",      myFlag,      ArgFlag.Optional,   "My Flag"    ));
	mixin(defineArg!(cmd, "myFlagX",     myFlagX,     ArgFlag.Optional,   "My Flag X"  ));
	mixin(defineArg!(cmd, "myStr",       myStr,       ArgFlag.Optional,   "My String"  ));
	mixin(defineArg!(cmd, "myStrX",      myStrX,      ArgFlag.Optional|ArgFlag.ToLower, "My Case-Insensitive String X"));
	mixin(defineArg!(cmd, "_odd98_name", _odd98_name, ArgFlag.Optional,   "Odd name"   ));
	mixin(defineArg!(cmd, "myInt",       myInt,       ArgFlag.Optional,   "My Int"));
	mixin(defineArg!(cmd, "r",           required,    ArgFlag.Required,   "This is required, and internal name differs"));
	mixin(defineArg!(cmd, "",            switchless,  ArgFlag.Optional,   "Switchless Multiple" ));
	mixin(defineArg!(cmd, "myEnum",      myEnum,      ArgFlag.Optional,   `My Enum ("tea" or "coffee")` ));
	
	mixin(setArgAllowableValues!("myEnum", "tea", "coffee"));
	//mixin(setArgAllowableValues!("myInt", 3, 7));

	cmd.parse(args);
	if(detailHelp)
	{
		writeln(cmd.errorMsg);
		write(cmd.getDetailedUsage());
		return;
	}
	if(!cmd.success || help)
	{
		writeln(cmd.errorMsg);
		write(cmd.getUsage(18));
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
		"myEnum     "
	));
}
