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
//TODO: Clean this up
class CmdArgs
{
	mixin(getter!(bool, "shouldExit"));

	string header;
	public this(string[] args, string header)
	{
		mixin(initMember!(header));
		init();
		shouldExit = !parse(args);
	}
	
	const string sampleUsageMsg = "Usage: stbuild [options] target [mode] [options]";
	const string defaultMode = Conf.modeRelease;
	
	// Cmd line params
	bool help = false;
	bool moreHelp = false;

	string confFile = "stbuild.conf";
	string[] targetMode;
	bool cleanOnly = false;
	bool quiet = false;
	bool showCmd = false;
	string buildToolStr = "xf";
	string[] extraArgList;
	
	// Indirectly determined by cmd line params
	string target;
	string mode = defaultMode;
	Conf conf;
	BuildTool buildTool;
	string extraArgs;

	private CmdLineParser cmdLine;
	private void init()
	{
		cmdLine = new CmdLineParser();
		mixin(defineArg!(cmdLine, "help",     help,         ArgFlag.Optional, "Displays a help summary and exits" ));
		mixin(defineArg!(cmdLine, "morehelp", moreHelp,     ArgFlag.Optional, "Displays a detailed help message and exits" ));
		mixin(defineArg!(cmdLine, "",         targetMode,   ArgFlag.Optional, "First is target, second is optional mode" ));
		mixin(defineArg!(cmdLine, "clean",    cleanOnly,    ArgFlag.Optional, "Clean, don't build" ));
		mixin(defineArg!(cmdLine, "conf",     confFile,     ArgFlag.Optional, "Configuration file to use" ));
		mixin(defineArg!(cmdLine, "tool",     buildToolStr, ArgFlag.Optional, "Build tool [\"rdmd\", \"re\" or \"xf\"]" ));
		mixin(defineArg!(cmdLine, "q",        quiet,        ArgFlag.Optional, "Quiet, ie. don't show progress messages" ));
		mixin(defineArg!(cmdLine, "cmd",      showCmd,      ArgFlag.Optional, "Show commands" ));
		mixin(defineArg!(cmdLine, "x",        extraArgList, ArgFlag.Optional, "Pass extra argument to build tool" ));

		mixin(setArgAllowableValues!("tool", "rdmd", "re", "xf"));
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
		cmd.echo;
	}
	
	private void showModes()
	{
		auto modes = Conf.modes;
		modes.sort();

		cmd.echo("Modes:", modes);
		cmd.echo("Default Mode:", defaultMode);
		cmd.echo;
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
		cmd.echo("Copyright (c) 2009-2010 Nick Sabalausky");
		cmd.echo("See LICENSE.txt for license info");
		cmd.echo("Site: http://www.dsource.org/projects/semitwist");
	}

	void showHelpHowTo()
	{
		cmd.echo("For help and usage information, use '{} --help'".sformat(getExecName()));
	}
	
	// Returns: Should processing proceed? If false, the program should exit.
	private bool parse(string[] args)
	{
		cmdLine.parse(args);

		if(moreHelp)
		{
			showHeader();
			cmd.echo(cmdLine.errorMsg);
			try
				conf = new Conf(confFile);
			catch(STBuildConfException e)
			{
				cmd.echo(e.msg);
				cmd.echo;
			}
			cmd.echo(sampleUsageMsg);
			cmd.echo;
			showTargets();
			showModes();
			cmd.echo(cmdLine.getDetailedUsage());
			return false;
		}
		if(!cmdLine.success || help)
		{
			showHeader();
			cmd.echo(cmdLine.errorMsg);
			try
				conf = new Conf(confFile);
			catch(STBuildConfException e)
			{
				cmd.echo(e.msg);
				cmd.echo;
			}
			showUsage();
			return false;
		}
		
		try
			conf = new Conf(confFile);
		catch(STBuildConfException e)
		{
			showHeader();
			cmd.echo(cmdLine.errorMsg);

			cmd.echo(e.msg);
			cmd.echo;
			
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
			showHeader();
			cmd.echo;
			cmd.echo("Target not specified");
			cmd.echo;
			showUsage();
			return false;
		default:
			showHeader();
			cmd.echo;
			cmd.echo("Unexpected extra params:", targetMode[2..$]);
			cmd.echo;
			showUsage();
			return false;
		}
		
		switch(buildToolStr)
		{
		case "rdmd":
			buildTool = BuildTool.rdmd;
			break;
		case "re":
			buildTool = BuildTool.rebuild;
			break;
		case "xf":
			buildTool = BuildTool.xfbuild;
			break;
		default:
			throw new Exception("Internal Error: Unexpected Build Tool Str: "~buildToolStr);
		}
		
		extraArgs = extraArgList.join(" ");
		
		// Move to CmdLine
		if(!conf.targets.contains(target))
		{
			cmd.echo("Target '{}' not defined".sformat(target));
			cmd.echo;
			showTargets();
			showHelpHowTo();
			return false;
		}
		if(!conf.modes.contains(mode))
		{
			cmd.echo("Mode '{}' not supported".sformat(mode));
			cmd.echo;
			showModes();
			showHelpHowTo();
			return false;
		}

		return true;
	}
}
