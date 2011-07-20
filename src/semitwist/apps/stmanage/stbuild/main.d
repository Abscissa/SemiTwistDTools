// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with DMD 2.052 through 2.054
+/

//TODO: Clean all if stbuild.conf has changed
//TODO: Clean all if using a different build tool from last time
//TODO: User-defined options (ex: set preference for default: rebuild or xfbuild)
//TODO: Handle DMD patched for -ww
//      Use STBUILD_OPTS env var: STBUILD_OPTS=dmdpatch_ww;whatever...
//TODO: Disallow crazy characters in target names
//TODO? Use Goldie to parse .conf file
//TODO: Get obj dir from conf switches instead of hardcoding to "obj/target/mode"
//TODO: Translate extraArgs between rebuild/xfbuild/rdmd
//TODO: When using xfbuild, make sure root filenames end in ".d" (ie "src/main.d" instead of "src/main")
//TODO: Fix: 'stbuild.conf' errors get displayed before header message.

module semitwist.apps.stmanage.stbuild.main;

import semitwist.cmd.all;

import semitwist.apps.stmanage.stbuild.cmdArgs;
import semitwist.apps.stmanage.stbuild.conf;

enum appName = "STBuild";
enum appVerStr = "0.03.1";
Ver appVer;
static this()
{
	appVer = appVerStr.toVer();
}

CmdArgs cmdArgs;
Conf conf;

void moveMapFiles(string subDir=".")
{
	foreach(string name; dirEntries(".", SpanMode.shallow))
	{
		if(name.fnmatch("*.map"))
		{
			auto newName = "obj/"~subDir~"/"~name.basename();
			if(exists(newName))
				remove(newName);
			
			rename(name, newName);
		}
	}
}

int process(string target, string mode, bool verbose)
{
	auto processor = ( cmdArgs.cleanOnly? &clean : &build );
	
	string[] targetsToProcess = (target == conf.targetAll)? conf.targetAllElems : [target];
	string[] modesToProcess   = (mode   == conf.modeAll)?   conf.modeAllElems   : [mode  ];
	
	int errLevel = 0;
	foreach(string currTarget; targetsToProcess)
	foreach(string currMode;   modesToProcess  )
	{
		auto result = processor(currTarget, currMode, verbose);
		if(result > errLevel)
			errLevel = result;
	}
	
	return errLevel;
}

void rdmdFixup(bool verbose)
{
	version(Windows)
	{
		auto execPath = getExecPath();
		if(!exists(execPath~".."~pathSep~"rdmdAlt.exe"))
		{
			if(verbose)
				cmd.echo("Pre-building fixed rdmd...");
				
			auto buildCmd =
				"dmd "~
				quoteArg(execPath~".."~pathSep~"rdmdAlt.d")~
				" "~quoteArg("-of"~execPath~".."~pathSep~"rdmdAlt.exe");
				
			if(cmdArgs.showCmd)
				cmd.echo(buildCmd);

			system(buildCmd);
		}
	}
}

int build(string target, string mode, bool verbose)
{
	mixin(deferAssert!(`target != conf.targetAll`, "target 'all' passed to build()"));
	mixin(deferAssert!(`mode != conf.modeAll`, "mode 'all' passed to build()"));

	rdmdFixup(verbose);

	if(verbose)
		cmd.echo("Building %s %s...".format(target, mode));

	auto objDir = "obj/"~target~"/"~mode;
	if(!exists(objDir))
		mkdirRecurse(objDir);
	
	int ret;
	auto cmdLine =
		buildToolExecName(cmdArgs.buildTool)~" "~
		conf.getFlags(target, mode, cmdArgs.buildTool)~" "~
		cmdArgs.extraArgs;
	
	if(cmdArgs.showCmd) cmd.echo(cmdLine);
	ret = system(cmdLine);
	moveMapFiles(target~"/"~mode);
	
	return ret;
}

int clean(string target, string mode, bool verbose)
{
	mixin(deferAssert!(`target != conf.targetAll`, "target 'all' passed to clean()"));
	mixin(deferAssert!(`mode != conf.modeAll`, "mode 'all' passed to clean()"));

	if(verbose)
		cmd.echo("Cleaning %s %s...".format(target, mode));

	auto objDir = "obj/"~target~"/"~mode; 
	if(exists(objDir))
	foreach(string name; dirEntries(objDir, SpanMode.depth))
	{
		if(name.fnmatch("*.map") || name.basename().fnmatch("deps") || name.fnmatch("*"~objExt))
			remove(name);
	}
		
	return 0;
}

int main(string[] args)
{
	cmdArgs = new CmdArgs(args, appName~" v"~appVerStr);
	if(cmdArgs.shouldExit)
		return 1;

	conf = cmdArgs.conf;

	return process(cmdArgs.target, cmdArgs.mode, !cmdArgs.quiet);
}
