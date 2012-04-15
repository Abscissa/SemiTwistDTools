// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

module semitwist.apps.stmanage.stbuild.cmdArgs;

import getopt = std.getopt;
import semitwist.cmd.all;

import semitwist.apps.stmanage.stbuild.conf;

enum appName = "STBuild";
enum appVerStr = "0.4.2";
enum Ver appVer = appVerStr.toVer();

struct Options
{
	bool     help;
	bool     cleanOnly;
	string   confFile = "stbuild.conf";
	string   buildToolStr = "rdmd";
	bool     quiet;
	bool     showCmd;
	string[] extraArgList;
	string[] targetMode;

	// Indirectly determined by cmd line params
	string target;
	string mode = defaultMode;
	Conf conf;
	BuildTool buildTool;
	string extraArgs;

	string infoHeader;
	string helpScreen;

	enum seeHelpMsg = "Run with --help to see usage.";
	enum defaultMode = Conf.modeRelease;

	// Returns errorlevel program should exit immediately with.
	// If returns -1, everything is OK and program should continue without exiting.
	int process(string[] args)
	{
		infoHeader = (`
				`~appName~` v`~appVerStr~`
				Copyright (c) 2009-2012 Nick Sabalausky
				See LICENSE.txt for license info
				Site: http://www.dsource.org/projects/semitwist
			`).normalize();
		
		helpScreen = `
				Usage: stbuild [options] target [mode] [options]

				--help              Displays this help screen and exits
				--clean             Clean, don't build
				--conf <filename>   Configuration file to use (default: "stbuild.conf")
				--tool <tool>       Build tool ["rdmd", "re" or "xf"] (default: "rdmd")
				-q, --quiet         Quiet, ie. don't show progress messages
				--cmd               Show commands
				-x <arg>            Pass extra argument to build tool
			`.normalize();

		if(args.length == 1)
			return showHelpScreen();

		getopt.endOfOptions = "";
		try getopt.getopt(
			args,
			getopt.config.caseSensitive,
			"help",     &help,
			"clean",    &cleanOnly,
			"conf",     &confFile,
			"tool",     &buildToolStr,
			"q|quiet",  &quiet,
			"cmd",      &showCmd,
			"x",        &extraArgList
		);
		catch(Exception e)
		{
			writeln(e.msg);
			writeln(seeHelpMsg);
			return 1;
		}
		
		targetMode = args[1..$];

		if(help || args.contains("/?"))
			return showHelpScreen();

		try
			conf = new Conf(confFile);
		catch(STBuildConfException e)
		{
			stderr.writeln(e.msg);
			stderr.writeln(seeHelpMsg);
			return false;
		}

		switch(targetMode.length)
		{
		case 1:
			target = targetMode[0];
			break;
		case 2:
			target = targetMode[0];
			mode   = targetMode[1];
			break;
		case 0:
			stderr.writeln("Must specify a target.");
			stderr.writeln(seeHelpMsg);
			return 1;
		default:
			stderr.writeln("Unexpected extra params: ", targetMode[2..$]);
			stderr.writeln(seeHelpMsg);
			return 1;
		}
		
		switch(buildToolStr)
		{
		case "rdmd":
			buildTool = BuildTool.rdmd;
			break;
		case "re", "rebuild":
			buildTool = BuildTool.rebuild;
			break;
		case "xf", "xfbuild":
			buildTool = BuildTool.xfbuild;
			break;
		default:
			stderr.writeln("Unknown build tool: '", buildToolStr, "'");
			stderr.writeln(seeHelpMsg);
			return 1;
		}
		
		extraArgs = std.string.join(extraArgList, " ");
		
		// Move to CmdLine
		if(find(conf.targets, target) == [])
		{
			stderr.writeln("Unknown target: '", target, "'");
			showTargets();
			stderr.writeln(seeHelpMsg);
			return 1;
		}
		if(find(conf.getModes(), mode) == [])
		{
			stderr.writeln("Unknown mode: '", mode, "'");
			showModes();
			stderr.writeln(seeHelpMsg);
			return 1;
		}
		
		return -1; // All ok
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
		cmd.echo();
	}
	
	private void showModes()
	{
		string[] modes;
		if(conf)
			modes = conf.getModes();

		if(modes.length > 0)
		{
			modes.sort();

			cmd.echo("Modes:", modes);
			cmd.echo("Default Mode:", defaultMode);
		}
		else
			cmd.echo("No Modes Available");
		cmd.echo();
	}

	private void showUsage()
	{
		showTargets();
		showModes();
		writeln(helpScreen);
	}

	private void showHeader()
	{
		writeln(infoHeader);
		writeln();
	}

	private int showHelpScreen()
	{
		if(!conf)
		{
			try
				conf = new Conf(confFile);
			catch(STBuildConfException e)
			{
				stderr.writeln(e.msg);
				stderr.writeln(seeHelpMsg);
				return 1;
			}
		}

		showHeader();
		showUsage();
		return 0;
	}
}
