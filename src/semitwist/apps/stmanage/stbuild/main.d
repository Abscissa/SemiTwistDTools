// SemiTwist D Tools
// STManage: STBuild
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 2.046 / xfBuild 0.4
+/

//TODO: Clean all if stbuild.conf has changed
//TODO: Clean all if using a different build tool from last time
//TODO: User-defined options (ex: set preference for default: rebuild or xfbuild)
//TODO: Handle DMD patched for -ww
//      Use STBUILD_OPTS env var: STBUILD_OPTS=dmdpatch_ww;whatever...
//TODO: Disallow crazy characters in target names
//TODO: $(proj), $(mode), $(#), $proj, $#, $$, etc.
//TODO? Use Goldie to parse .conf file
//TODO: Get obj dir from conf switches instead of hardcoding to "obj/target/mode"
//TODO: Translate extraArgs between rebuild/xfbuild
//TODO: When using xfbuild, make sure root filenames end in ".d" (ie "src/main.d" instead of "src/main")

module semitwist.apps.stmanage.stbuild.main;

import semitwist.cmd.all;

// Needed for tango.sys.Process workaround in build() below
/+version(Windows) {}
else
{
	import tango.stdc.posix.unistd;
	import tango.stdc.posix.sys.wait;
	import tango.stdc.stdlib;
	import tango.stdc.string;
	import tango.stdc.stringz;
    import tango.stdc.errno;

	//This stuff is borrowed from tango/sys/Process.d
	version(darwin)
    {
        extern (C) char*** _NSGetEnviron();
        private char** environ;
        
        static this ()
        {
            environ = *_NSGetEnviron();
        }
    }
    extern (C) extern char** environ;
    import tango.stdc.posix.stdlib;
}+/

import semitwist.apps.stmanage.stbuild.cmdArgs;
import semitwist.apps.stmanage.stbuild.conf;

const string appName = "STBuild";
const string appVerStr = "0.02.1";
Ver appVer;
static this()
{
	appVer = appVerStr.toVer();
}

CmdArgs cmdArgs;
Conf conf;

void moveMapFiles(string subDir=".")
{
//TODO***
//	foreach(VfsFile mapFile; cmd.dir.self.catalog("*.map"))
//		cmd.dir.folder("obj/"~subDir).open.file(mapFile.name).move(mapFile);

	foreach(string name; dirEntries(".", SpanMode.shallow))
	{
		if(name.fnmatch("*.map"))
			rename(name, "obj/"~subDir~"/"~name.basename());
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

int build(string target, string mode, bool verbose)
{
	mixin(deferAssert!(`target != conf.targetAll`, "target 'all' passed to build()"));
	mixin(deferAssert!(`mode != conf.modeAll`, "mode 'all' passed to build()"));

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
	//TODO***
	//version(Windows)
		ret = system(cmdLine);
	//else
	//{
/+		// On Tango 0.99.9, tango.sys.Process, and therefore cmd.exec, hangs
		// on non-Windows due to Tango Bug #1859, so this is a quick-n-dirty
		// workaround.
		
		string[] args;
		//mixin(traceVal!("cmdLine"));
		foreach(string arg; quotes(cmdLine, " "))
		{
			//writefln(":%s", arg);
			
			if(arg == "")
				continue;
				
			// UTF-safe because '"' is a single code-unit in any UTF.
			if(arg[0] == '"')
				arg = arg[1..$];
			if(arg[$-1] == '"')
				arg = arg[0..$-1];
			
			args ~= arg;
		}
		
		string execFile = args[0];
		//char* execFileZ = toStringz(execFile.dup);
		char*[] argsZ = [];
		foreach(string arg; args)
			argsZ ~= toStringz(arg.dup);
		argsZ ~= null;

		auto pid = fork();
		if(pid < 0)
			throw new ProcessException("Failed to fork new process");

		if(pid != 0)
		{
			// Parent process
			int status;
			waitpid(pid, &status, 0);
		}
		else
		{
			// Child process
			
			// This block is borrowed from tango/sys/Process.d
            int rc = -1;
            char* str;
            if (!contains(execFile, FileConst.PathSeparatorChar) &&
                (str = getenv("PATH")) !is null)
            {
                char[][] pathList = delimit(str[0 .. strlen(str)], ":");

                foreach (path; pathList)
                {
                    if (path[path.length - 1] != FileConst.PathSeparatorChar)
                    {
                        path ~= FileConst.PathSeparatorChar;
                    }

                    path ~= execFile;
                    path ~= '\0';

                    rc = execve(path.ptr, argsZ.ptr, environ);
                    // If the process execution failed because of an error
                    // other than ENOENT (No such file or directory) we
                    // abort the loop.
                    if (rc == -1 && errno != ENOENT)
                    {
                        break;
                    }
                }
            }
			
			throw new ProcessException("Program '"~execFile~"' not found");
		}+/
		
	//}
	moveMapFiles(target~"/"~mode);
	
	return ret;
}

int clean(string target, string mode, bool verbose)
{
	mixin(deferAssert!(`target != conf.targetAll`, "target 'all' passed to clean()"));
	mixin(deferAssert!(`mode != conf.modeAll`, "mode 'all' passed to clean()"));

	if(verbose)
		cmd.echo("Cleaning %s %s...".format(target, mode));

//TODO***
/+	VfsFolders objDir;
	try
		objDir = cmd.dir.folder("obj/"~target~"/"~mode).open.tree;
	catch(Exception e) // No directory to clean
		return 0;
	
	foreach(VfsFile file; objDir.catalog("*.map"))
		file.remove();
	
	foreach(VfsFile file; objDir.catalog("deps"))
		file.remove();
	
	foreach(VfsFile file; objDir.catalog("*"~objExt))
		file.remove();+/

	foreach(string name; dirEntries("obj/"~target~"/"~mode, SpanMode.depth))
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

