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

// Damn, can't make templated nested func
void displayNodes(U, T)(T collection, char[] label)
{
	Stdout.formatln("");
	Stdout.formatln("{}:", label);
	foreach(U elem; collection)
		Stdout.formatln(" -{}", elem.toString());
}

void testVfs(char[] dir)
{
	auto folder = new FileFolder(dir);

	displayNodes!(VfsFolder)(folder,      `folder`);
	displayNodes!(VfsFolder)(folder.self, `folder.self`);
	displayNodes!(VfsFolder)(folder.tree, `folder.tree`);
	displayNodes!(VfsFile  )(folder.self.catalog, `folder.self.catalog`);
	displayNodes!(VfsFile  )(folder.tree.catalog, `folder.tree.catalog`);
	displayNodes!(VfsFolder)(folder.tree.subset("*est"), `folder.tree.subset("*est")`);
	displayNodes!(VfsFile  )(folder.tree.catalog("*_r*"), `folder.tree.catalog("*_r*")`);
}

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
	testVfs(cmd.dir);
}
