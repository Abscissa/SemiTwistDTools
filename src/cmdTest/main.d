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

import semitwist.cmd.all;
import semitwist.util.all;

// Damn, can't make templated nested func
void displayNodes(TElem, TColl)(TColl collection, char[] label)
{
	Stdout.formatln("");
	Stdout.formatln("{}:", label);
	foreach(TElem elem; collection)
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

	const char[] helpMsg = "
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
";

	void delegate(char[] params)[char[]] cmdLookup = [
		""[]        : (char[] params) { },
		"help"      : (char[] params) { Stdout(helpMsg);         },
		"exit"      : (char[] params) { done = true;             },
		"echo"      : (char[] params) { cmd.echo(params);        },
		"pwd"       : (char[] params) { Stdout(cmd.dir).newline; },
		"cd"        : (char[] params) { cmd.dir = params;        },
		"exec"      : (char[] params) { cmd.exec(params);        },
		"isechoing" : (char[] params) { Stdout(cmd.echoing? "on" : "off").newline; },
		"ls"        : (char[] params) {
			displayNodes!(VfsFolder)(cmd.dir, "Directories");
			displayNodes!(VfsFile  )(cmd.dir.self.catalog, "Files");
		},
		"echoing"   : (char[] params) {
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
		},
	];
	
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
		
		if(command in cmdLookup)
		{
			try
				cmdLookup[command](params);
			catch(Exception e)
				Stdout.formatln("Exception: {}", e.msg);
		}
		else
			Stdout(`Unknown command (type "help" for list of supported commands)`).newline;
		
		if( !tango.core.Array.contains(["","exit"], command) )
			Stdout.newline;
	}
}
