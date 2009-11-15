// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

module semitwist.apps.stmanage.stbuild.cmdArgs;

import semitwist.cmd.all;
import semitwist.cmdlineparser;

import semitwist.apps.stmanage.stbuild.conf;

//TODO: Make validation into delegates passed into CmdLineParser
//TODO: Move some of the automatic messages into CmdLineParser
//TODO: Make CmdLineParser auto exit instead of using shouldExit
class CmdArgs
{
	mixin(getter!(bool, "shouldExit"));

	char[] header;
	public this(char[][] args, char[] header)
	{
		mixin(initMember!(header));
		init();
		shouldExit = !parse(args);
	}
	
	const char[] sampleUsageMsg = "Usage: stbuild [options] target [mode] [options]";
	const char[] defaultMode = Conf.modeRelease;
	
	// Cmd line params
	bool help = false;
	bool moreHelp = false;

	char[] confFile = "stbuild.conf";
	char[][] targetMode;
	bool cleanOnly = false;
	bool quiet = false;
	bool showCmd = false;
	
	// Indirectly determined by cmd line params
	char[] target;
	char[] mode = defaultMode;
	Conf conf;

	private CmdLineParser cmdLine;
	private void init()
	{
		//TODO? Allow multiple switchless in CmdLineParser
		//TODO? Create a "don't show in usage" ArgFlag setting.
		cmdLine = new CmdLineParser();
		mixin(defineArg!(cmdLine, "help",     help,       ArgFlag.Optional, "Displays a help summary and exits" ));
		mixin(defineArg!(cmdLine, "morehelp", moreHelp,   ArgFlag.Optional, "Displays a detailed help message and exits" ));
		mixin(defineArg!(cmdLine, "tm",       targetMode, ArgFlag.Optional|ArgFlag.Switchless, "First is target, second is optional mode" ));
		mixin(defineArg!(cmdLine, "clean",    cleanOnly,  ArgFlag.Optional, "Clean, don't build" ));
		mixin(defineArg!(cmdLine, "conf",     confFile,   ArgFlag.Optional, "Configuration file to use" ));
		mixin(defineArg!(cmdLine, "q",        quiet,      ArgFlag.Optional, "Quiet, ie. don't show progress messages" ));
		mixin(defineArg!(cmdLine, "cmd",      showCmd,    ArgFlag.Optional, "Show commands" ));
	}
	
	private void showTargets()
	{
		if(conf && conf.targets.length > conf.predefTargets.length)
		{
			//TODO: Create array.moveIndex(index, newIndex)
			//TODO: Create array.moveElement(elem, newIndex)
			//TODO: Make "all" always first
			auto targets = conf.targets.dup;
			targets.sort();

			cmd.echo("Targets Available:", targets);
		}
		else
			cmd.echo("No Targets Available");
	}
	
	private void showModes()
	{
		auto modes = Conf.modes;
		modes.sort();

		cmd.echo("Modes:", modes);
		cmd.echo;
		cmd.echo("Default Mode:", defaultMode);
	}
	
	private void showUsage()
	{
		cmd.echo(sampleUsageMsg);
		cmd.echo;
		showTargets();
		showModes();
		cmd.echo(cmdLine.getUsage(16));
	}

	private void showHeader()
	{
		cmd.echo(header);
	}

	void showHelpHowTo()
	{
		//TODO: Figure out why I'm getting an extra space on getExecName even with trim (Is it a null?)
		cmd.echo("For help and usage information, use '{} --help'".sformat(getExecName()));
	}
	
	// Returns: Should processing proceed? If false, the program should exit.
	private bool parse(char[][] args)
	{
		cmdLine.parse(args);

		try
			conf = new Conf(confFile);
		catch(STBuildConfException e)
		{
			cmd.echo(e.msg);
			cmd.echo;
			showHelpHowTo();
			return false;
		}

		if(moreHelp)
		{
			cmd.echo(header);
			cmd.echo(cmdLine.errorMsg);
			cmd.echo(sampleUsageMsg);
			cmd.echo(cmdLine.getDetailedUsage());
			return false;
		}
		if(!cmdLine.success || help)
		{
			cmd.echo(header);
			cmd.echo(cmdLine.errorMsg);
			showUsage();
			return false;
		}
		
		switch(targetMode.length)
		{
		case 2:
			mode = targetMode[1];
			//fallthrough
		case 1:
			target = targetMode[0];
			break;
		case 0:
			cmd.echo("Target not specified");
			cmd.echo;
			showTargets();
			cmd.echo;
			showHelpHowTo();
			return false;
		default:
			cmd.echo("Unexpected extra params:", targetMode[2..$]);
			cmd.echo;
			showHelpHowTo();
			return false;
		}
		
		// Move to CmdLine
		if(!conf.targets.contains(target))
		{
			cmd.echo("Target '{}' not defined".sformat(target));
			cmd.echo;
			showTargets();
			showHelpHowTo();
			return 1;
		}
		if(!conf.modes.contains(mode))
		{
			cmd.echo("Mode '{}' not supported".sformat(mode));
			cmd.echo;
			showModes();
			showHelpHowTo();
			return 1;
		}

		return true;
	}
}
