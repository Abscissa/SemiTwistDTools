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

//TODO: Handle screwup when user does "stbuild myproj clean"
//TODO: Handle screwup when user does "stbuild --help" without an stbuild.conf
//TODO: Handle screwup when user does "stbuild undefined_target"
//TODO: Handle non-existant combinations
//TODO: Handle DMD patched for -ww
//      Use STBUILD_OPTS env var: STBUILD_OPTS=dmdpatch_ww;whatever...
//TODO: Disallow crazy characters in target names
//TODO: $(proj), $(mode), $(#), $proj, $#, $$, etc.

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
	auto                  processor = &build;
	if(cmdArgs.cleanOnly) processor = &clean;
	
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
	assert(target != conf.targetAll, "target 'all' passed to build()");
	assert(mode != conf.modeAll, "mode 'all' passed to build()");

	if(verbose)
		cmd.echo("Building {} {}...".sformat(target, mode));

	int ret;
	auto cmdLine = "rebuild "~conf.getFlags(target, mode);
	
	if(cmdArgs.showCmd) cmd.echo(cmdLine);
	cmd.exec(cmdLine, ret);
	moveMapFiles(target~"/"~mode);
	
	return ret;
}

int clean(char[] target, char[] mode, bool verbose)
{
	assert(target != conf.targetAll, "target 'all' passed to clean()");
	assert(mode != conf.modeAll, "mode 'all' passed to clean()");

	if(verbose)
		cmd.echo("Cleaning {} {}...".sformat(target, mode));

	VfsFolders objDir;
	try
		objDir = cmd.dir.folder("obj/"~target~"/"~mode).open.tree;
	catch(Exception e) // No directory to clean
		return 0;
	
	foreach(VfsFile file; objDir.catalog("*.map"))
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

