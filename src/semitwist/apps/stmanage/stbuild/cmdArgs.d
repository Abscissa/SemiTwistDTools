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
		mixin(initMember("header"));
		init();
		shouldExit = !parse(args);
	}
	
	enum sampleUsageMsg = "Usage: stbuild [options] target [mode] [options]";
	enum defaultMode = Conf.modeRelease;
	
	// Cmd line params
	bool help = false;
	bool moreHelp = false;

	string confFile = "stbuild.conf";
	string[] targetMode;
	bool cleanOnly = false;
	bool quiet = false;
	bool showCmd = false;
	string buildToolStr = "rdmd";
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
		auto modes = conf.getModes();
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
		cmd.echo("Copyright (c) 2009-2011 Nick Sabalausky");
		cmd.echo("See LICENSE.txt for license info");
		cmd.echo("Site: http://www.dsource.org/projects/semitwist");
		cmd.echo();
	}

	void showHelpHowTo()
	{
		cmd.echo("For help and usage information, use '%s --help'".format(getExecName()));
	}
	
	// Returns: Should processing proceed? If false, the program should exit.
	private bool parse(string[] args)
	{
		cmdLine.parse(args);

		if(moreHelp)
		{
			showHeader();
			stdout.flush();
			auto confErr = "";
			try
				conf = new Conf(confFile);
			catch(STBuildConfException e)
				confErr = e.msg;
			cmd.echo(sampleUsageMsg);
			cmd.echo;
			showTargets();
			showModes();
			cmd.echo(cmdLine.getDetailedUsage());
			if(confErr != "")
				cmd.echo(confErr);
			write(cmdLine.errorMsg);
			return false;
		}
		if(!cmdLine.success || help)
		{
			showHeader();
			auto confErr = "";
			try
				conf = new Conf(confFile);
			catch(STBuildConfException e)
				confErr = e.msg;
			showUsage();
			if(confErr != "")
				cmd.echo(confErr);
			write(cmdLine.errorMsg);
			return false;
		}
		
		try
			conf = new Conf(confFile);
		catch(STBuildConfException e)
		{
			showHeader();
			showUsage();
			cmd.echo(e.msg);
			write(cmdLine.errorMsg);
			return false;
		}

		switch(targetMode.length)
		{
		case 2:
			mode = targetMode[1];
			goto case;
		case 1:
			target = targetMode[0];
			break;
		case 0:
			showHeader();
			showUsage();
			cmd.echo("Target not specified");
			return false;
		default:
			showHeader();
			showUsage();
			cmd.echo("Unexpected extra params:", targetMode[2..$]);
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
		
		extraArgs = std.string.join(extraArgList, " ");
		
		// Move to CmdLine
		if(find(conf.targets, target) == [])
		{
			showTargets();
			cmd.echo("Target '%s' not defined".format(target));
			cmd.echo;
			showHelpHowTo();
			return false;
		}
		if(find(conf.getModes(), mode) == [])
		{
			showModes();
			cmd.echo("Mode '%s' not supported".format(mode));
			cmd.echo;
			showHelpHowTo();
			return false;
		}

		return true;
	}
}
