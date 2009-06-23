// SemiTwist Library: CommandLine Test
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Uses:
- DMD 1.043
- Tango 0.99.8
*/

module cmdTest.main;

import tango.io.Stdout;

import tango.io.FilePath;
import tango.io.FileSystem;
import tango.util.PathUtil;

import semitwist.util.all;
import semitwist.cmd;

void main(char[][] args)
{
	Stdout.formatln("SemiTwist Library: CommandLine Test");

	Stdout.formatln("");
	mixin(traceVal!("args[0]", "FileSystem.getDirectory()"));

	auto cmd = new CommandLine();
//	auto path = new FilePath(cmd.dir);
//	mixin(traceVal!("path.toString()", "path.isAbsolute()", "path.isFolder()"));

	mixin(traceVal!("cmd.dir"));
	cmd.dir = "..";
	mixin(traceVal!("cmd.dir"));
	cmd.dir = "../..";
	mixin(traceVal!("cmd.dir"));
	cmd.dir = FileSystem.getDirectory();
	mixin(traceVal!("cmd.dir"));
	
//	cmd.exec("echo", ["Echoing hello!"]);
//	cmd.exec("echo Echoing hello!");

	cmd.echo("Hello");

	auto cd = new CmdDir(cmd.dir);
//	mixin(traceVal!(`cd.files()`, `cd.dirs()`, `cd.nodes("*_release*")`, `cd.nodes()`, `cd.dirs("*", true)`));

	void displayNodes(CmdNode[] nodes, char[] label)
	{
		Stdout.formatln("");
		Stdout.formatln("{}:", label);
		foreach(CmdNode elem; nodes)
			Stdout.formatln(" -{}", elem.toString());
	}
	displayNodes(cast(CmdNode[])cd.files,      `cd.files`);
	displayNodes(cast(CmdNode[])cd.dirs,       `cd.dirs`);
	displayNodes(cd.nodes,                     `cd.nodes`);
	displayNodes(cd.nodes("*_release*", true), `cd.nodes("*_release*", true)`);
	displayNodes(cast(CmdNode[])cd.dirs(true), `cd.dirs(true)`);

/*	Stdout.formatln("");
	mixin(traceVal!(`(new FilePath("hi")==new FilePath("hi"))?"same":"different"`));
*/
/*	Stdout.formatln("");
	mixin(traceVal!(`new FilePath("./bin/..")`));
	mixin(traceVal!(`normalize("./bin/..")`));
	mixin(traceVal!(`FileSystem.toAbsolute(new FilePath("./bin/.."), FileSystem.getDirectory())`));
	mixin(traceVal!(`normalize(FileSystem.toAbsolute(new FilePath("./bin/.."), FileSystem.getDirectory()).toString())`));
	mixin(traceVal!(`FileSystem.toAbsolute(normalize("./bin/.."), FileSystem.getDirectory())`));
*/

	
}
