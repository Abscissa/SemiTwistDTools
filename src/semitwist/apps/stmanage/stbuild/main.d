// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Prerequisites for Building:
- [Required]    DMD 1.043 (LDC untested)
- [Required]    Tango 0.99.8
- [Recommended] Rebuild 0.76
DMD 1.044+ with Tango Trunk might work, but is untested.
Rebuild 0.78 might work, but is quirky and not recommended.
*/

//TODO? Change "all all" to "alltargets allmodes"
//TODO* make obj subdirs "obj/target/mode"
//TODO: Automatically create/del obj subdirs
//TODO: Make clean an extra optional param
//TODO: Don't need to group modes together anymore, maybe clean up remnants of that
//TODO: Clean should only run once even though it's "all"
//TODO: Incorporate command line parser
//TODO: Handle non-existant combinations
//TODO: Handle DMD patched for -ww
//TODO: Disallow crazy characters in target names
//TODO: $(proj), $(mode), $(#), $proj, $#, $$, etc.
//TODO: Add built-in fix for rebuild #227
//      (Doesn't recompile untouched sources when passed different build paramaters)

module semitwist.apps.stmanage.stbuild.main;

import semitwist.cmd.all;
import semitwist.os; // TODO: Include this in cmd.all

import semitwist.apps.stmanage.stbuild.conf;

const char[] appName = "STBuild";
const char[] appVer = "v1.00(pre)";

Conf conf;
char[][] targetsInAll;
char[][] modesInAll;
bool echoCmd;

const char[] confPrefix = "-c:";
const char[] defaultConfFilename = "stbuild.conf";
const char[] defaultMode = Conf.modeRelease;
int function(char[])[char[]] modeMap;
static this()
{
	modeMap =
	[
		Conf.modeRelease: &buildModeRelease,
		Conf.modeDebug:   &buildModeDebug,
		Conf.modeAll:     &buildModeAll,
		Conf.modeClean:   &clean
	];
}

void moveMapFiles(char[] subDir=".")
{
	foreach(VfsFile mapFile; cmd.dir.self.catalog("*.map"))
		cmd.dir.folder("obj/"~subDir).open.file(mapFile.name).move(mapFile);
}

//TODO: Move this to semitwist.util
// Like foreach, except the body has a return value,
// and the loop bails whenever that value != whileVal
TRet forEachWhileVal(TRet, TElem)(TElem[] coll, TRet whileVal, TRet delegate(TElem) dg)
{
	foreach(TElem elem; coll)
	{
		auto ret = dg(elem);
		if(ret != whileVal)
			return ret;
	}
	return whileVal;
}

//TODO: Move this to semitwist.util
// Returns everything in 'from' minus the values in 'except'.
// Note: using ref didn't work when params were (const char[][] here).dup
T[] allExcept(T)(T[] from, T[] except)
{
	T[] f = from.dup;
	T[] e = except.dup;
	f.sort();
	e.sort();
	return f.missingFrom(e);
}

int build(char[] target, char[] mode, bool verbose)
{
	if(verbose)
	{
		cmd.echo(
			mode==conf.modeClean?
			"Cleaning..." :
			"Building {} {}...".sformat(target, mode)
		);
	}
	
	return
		target == conf.targetAll && mode != conf.modeAll?
		targetsInAll.forEachWhileVal(
			0,
			delegate int(char[] currTarget)
			{
				return build(currTarget, mode, true);
			}
		)
		: modeMap[mode](target);
}

int buildModeRelease(char[] target)
{
	int ret;
	auto cmdLine = "rebuild "~conf.getFlags(target, conf.modeRelease);
	
	if(echoCmd) cmd.echo(cmdLine);
	cmd.exec(cmdLine, ret);
	moveMapFiles(target~"/release");
	
	return ret;
}

int buildModeDebug(char[] target)
{
	int ret;
	auto cmdLine = "rebuild "~conf.getFlags(target, conf.modeDebug);
	
	if(echoCmd) cmd.echo(cmdLine);
	cmd.exec(cmdLine, ret);
	moveMapFiles(target~"/debug");
	
	return ret;
}

int clean(char[] target)
{
	auto objDir = cmd.dir.folder("obj").open.tree;
	
	foreach(VfsFile file; objDir.catalog("*.map"))
		file.remove();
	
	foreach(VfsFile file; objDir.catalog("*"~objExt))
		file.remove();
		
	return 0;
}

int buildModeAll(char[] target)
{
	return
		modesInAll.forEachWhileVal(
			0,
			delegate int(char[] mode)
			{
				return
					target != conf.targetAll?
					build(target, mode, true) :
					targetsInAll.forEachWhileVal(
						0,
						delegate int(char[] currTarget)
						{
							return build(currTarget, mode, true);
						}
					);
			}
		);
/*		
	foreach(char[] mode; modeMap.keys)
	{
		if([conf.modeAll, conf.modeClean].contains(mode))
			continue;
			
		cmd.echo("Building '{}' '{}'...".sformat(target, mode));
		auto errLevel = modeMap[mode](target);
		if(errLevel != 0)
			return errLevel;
	}
	return 0;
*/
}

/*int buildEachMode(int delegate(char[]) buildOneMode)
{
	foreach(char[] mode; modeMap.keys)
	{
		if([conf.modeAll, conf.modeClean].contains(mode))
			continue;
		
		auto errLevel = buildOneMode(mode);
		if(errLevel != 0)
			return errLevel;
	}
	return 0;
}
*/

int main(char[][] args)
{
	char[] confFilename;
	char[] target;
	char[] mode;

	void showTargets()
	{
		auto targets = conf.targets ~ conf.predefTargets;
		targets.sort();

		cmd.echo("Targets Found:".sformat(confFilename), targets);
	}
	
	void showModes()
	{
		auto modes = modeMap.keys;
		modes.sort();

		cmd.echo("Modes:", modes);
		cmd.echo;
		cmd.echo("Default Mode:", defaultMode);
		cmd.echo(
			"Mode '{}' is a special mode. It is not included in mode '{}',"
			.sformat(conf.modeClean, conf.modeAll)
		);
		cmd.echo("and cleans all intermedate files regardless of target.");
	}
	
	void showUsage()
	{
		cmd.echo(appName, appVer);
		cmd.echo("Usage: stbuild [-c:conf_filename] target [mode]");
		cmd.echo;
		showTargets();
		showModes();
	}
	
	bool parseArgs()
	{
		foreach(int i, char[] arg; args)
			args[i] = arg.trim();
			
		confFilename = defaultConfFilename;
		mode = defaultMode;

		switch(args.length)
		{
		case 2:
			target = args[1];
			break;
		case 3:
			if(args[1].startsWith(confPrefix))
			{
				confFilename = args[1][confPrefix.length..$];
				target = args[2];
			}
			else
			{
				target = args[1];
				mode = args[2];
			}
			break;
		case 4:
			if(!args[1].startsWith(confPrefix))
				return false;
				
			confFilename = args[1][confPrefix.length..$];
			target = args[2];
			mode = args[3];
			break;
		default:
			return false;
		}
		
		return true;
	}
	
	try
	{
		bool argsOk = parseArgs();
		conf = new Conf(confFilename);
		if(!argsOk)
		{
			showUsage();
			return 1;
		}
	}
	catch(STBuildConfException e)
	{
		cmd.echo(e.msg);
		return 1;
	}
	
	auto isTargetInConf = (conf.targets.contains(target) || conf.predefTargets.contains(target));
	auto isModeInConf   = (conf.modes.contains(mode)     || conf.predefModes.contains(mode)    );

	if(!isTargetInConf)
	{
		cmd.echo("Target '{}' not defined".sformat(target));
		cmd.echo;
		showTargets();
		return 1;
	}
	
	if(!isModeInConf || !(mode in modeMap))
	{
		cmd.echo("Mode '{}' not supported".sformat(mode));
		cmd.echo;
		showModes();
		return 1;
	}
	
	echoCmd = (target != conf.targetAll && mode != conf.modeAll);
	
	modesInAll   = modeMap.keys.allExcept([conf.modeAll, conf.modeClean]);
	targetsInAll = conf.targets.allExcept(conf.predefTargets);

	return build(target, mode, false);
}

