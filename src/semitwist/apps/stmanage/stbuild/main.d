// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.043 / Tango 0.99.8 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / Rebuild 0.76
  - DMD 1.051 / Tango trunk r5149 / xfBuild 0.4
+/

//TODO: Clean all if stbuild.conf has changed
//TODO: Clean all if using a different build tool from last time
//TODO: User-defined options (ex: set preference for default: rebuild or xfbuild)
//TODO***: Handle screwup when user does "stbuild myproj badmode"
//TODO***: Handle screwup when user does "stbuild --help" without an stbuild.conf
//TODO***: Handle screwup when user does "stbuild undefined_target"
//TODO***: Handle non-existant combinations
//TODO: Handle DMD patched for -ww
//      Use STBUILD_OPTS env var: STBUILD_OPTS=dmdpatch_ww;whatever...
//TODO: Disallow crazy characters in target names
//TODO: $(proj), $(mode), $(#), $proj, $#, $$, etc.
//TODO? Use Goldie to parse .conf file
//TODO: Get obj dir from conf switches instead of hardcoding to "obj/target/mode"
//TODO***: Allow extra compiler/buildtool params on the cmd line
//TODO: When using xfbuild, make sure root filenames end in ".d" (ie "src/main.d" instead of "src/main")

module semitwist.apps.stmanage.stbuild.main;

import semitwist.cmd.all;

import semitwist.apps.stmanage.stbuild.cmdArgs;
import semitwist.apps.stmanage.stbuild.conf;

const char[] appName = "STBuild";
const char[] appVer = "v0.01(pre)";

CmdArgs cmdArgs;
Conf conf;

void moveMapFiles(char[] subDir=".")
{
	foreach(VfsFile mapFile; cmd.dir.self.catalog("*.map"))
		cmd.dir.folder("obj/"~subDir).open.file(mapFile.name).move(mapFile);
}

int process(char[] target, char[] mode, bool verbose)
{
	auto processor = ( cmdArgs.cleanOnly? &clean : &build );
	
	char[][] targetsToProcess = (target == conf.targetAll)? conf.targetAllElems : [target];
	char[][] modesToProcess   = (mode   == conf.modeAll)?   conf.modeAllElems   : [mode  ];
	
	int errLevel = 0;
	foreach(char[] currTarget; targetsToProcess)
	foreach(char[] currMode;   modesToProcess  )
	{
		auto result = processor(currTarget, currMode, verbose);
		if(result > errLevel)
			errLevel = result;
	}
	
	return errLevel;
}

int build(char[] target, char[] mode, bool verbose)
{
	mixin(deferAssert!(`target != conf.targetAll`, "target 'all' passed to build()"));
	mixin(deferAssert!(`mode != conf.modeAll`, "mode 'all' passed to build()"));

	if(verbose)
		cmd.echo("Building {} {}...".sformat(target, mode));

	cmd.dir.folder("obj/"~target~"/"~mode).create();
	
	int ret;
	auto cmdLine = buildToolExecName(cmdArgs.buildTool)~" "~conf.getFlags(target, mode, cmdArgs.buildTool);
	
	if(cmdArgs.showCmd) cmd.echo(cmdLine);
	cmd.exec(cmdLine, ret);
	moveMapFiles(target~"/"~mode);
	
	return ret;
}

int clean(char[] target, char[] mode, bool verbose)
{
	mixin(deferAssert!(`target != conf.targetAll`, "target 'all' passed to clean()"));
	mixin(deferAssert!(`mode != conf.modeAll`, "mode 'all' passed to clean()"));

	if(verbose)
		cmd.echo("Cleaning {} {}...".sformat(target, mode));

	VfsFolders objDir;
	try
		objDir = cmd.dir.folder("obj/"~target~"/"~mode).open.tree;
	catch(Exception e) // No directory to clean
		return 0;
	
	foreach(VfsFile file; objDir.catalog("*.map"))
		file.remove();
	
	foreach(VfsFile file; objDir.catalog("deps"))
		file.remove();
	
	foreach(VfsFile file; objDir.catalog("*"~objExt))
		file.remove();
		
	return 0;
}

int main(char[][] args)
{
	cmdArgs = new CmdArgs(args, appName~" "~appVer);
	if(cmdArgs.shouldExit)
		return 1;

	conf = cmdArgs.conf;

	return process(cmdArgs.target, cmdArgs.mode, !cmdArgs.quiet);
}

