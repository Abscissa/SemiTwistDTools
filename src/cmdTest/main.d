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

import tango.io.FilePath;
import tango.io.FileSystem;
import tango.util.PathUtil;

import semitwist.cmd;
import semitwist.util.all;

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
	Stdout("SemiTwist Library: CommandLine Test");

	Stdout.newline;
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
	
	cmd.echo("Whee!");
	//testVfs(cmd.dir);

	cmd.exec("myecho_release", ["I'm echoing,", "hello!"]);
	cmd.exec("myecho_release I'm echoing, hello!");
	
	cmd.echoing = false;
	cmd.exec("myecho_release Can't see this because echoing is off");
	cmd.echoing = true;

	Stdout.newline;
	bool done = false;
	while(!done)
	{
		Stdout("cmdTest>").flush;
		
		char[] input;
		Cin.readln(input);
		input = trim(input);
		
		auto splitIndex = input.locate(' ');
		char[] command = input[0..splitIndex];
		char[] params = splitIndex==input.length? "" : input[splitIndex+1..$];
		params = trim(params);
		
		switch(command)
		{
		case "":
			break;
			
		case "exit":
			done = true;
			break;
			
		case "echo":
			cmd.echo(params);
			Stdout.newline;
			break;
			
		case "pwd":
			Stdout(cmd.dir).newline;
			Stdout.newline;
			break;
			
		case "cd":
			cmd.dir = params;
			Stdout.newline;
			break;
			
		case "exec":
			cmd.exec(params);
			Stdout.newline;
			break;
			
		case "echoing":
			switch(params)
			{
			case "on":
				cmd.echoing = true;
				break;
			case "off":
				cmd.echoing = false;
				break;
			default:
				Stdout(`param must be either "on" or "off"`).newline;
				break;
			}
			Stdout.newline;
			break;
			
		case "isechoing":
			Stdout(cmd.echoing? "on" : "off").newline;
			Stdout.newline;
			break;
			
		case "ls":
			displayNodes!(VfsFolder)(cmd.dir, "Directories");
			displayNodes!(VfsFile  )(cmd.dir.self.catalog, "Files");
			Stdout.newline;
			break;
			
		case "help":
			Stdout(
"
--Supported Commands--
help                 Displays this message
echo <text>          Echos <text>
pwd                  Print working directory
cd <dir>             Change directory
ls                   Displays current directory contents
exec <prog> <params> Runs program <prog> with paramaters <params>
echoing <on|off>     Chooses whether output from exec'ed programs is displayed
isechoing            Displays current echoing setting
exit                 Exits
");
			Stdout.newline;
			break;
			
		default:
			//mixin(traceVal!("command", "params"));
			//Stdout(input).newline;
			Stdout(`Unknown command (type "help" for list of supported commands)`).newline;
			Stdout.newline;
			break;
		}
	}
}
