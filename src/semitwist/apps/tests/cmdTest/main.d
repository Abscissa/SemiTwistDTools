// SemiTwist D Tools:
// Tests: semitwist.cmd test
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.056 / Tango 0.99.9 / Rebuild 0.76
  - DMD 1.056 / Tango 0.99.9 / xfBuild 0.4
+/

module semitwist.apps.tests.cmdTest.main;

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

//TODO: Add errLevel stuff
void main(char[][] args)
{
	Stdout("SemiTwist Library: semitwist.cmd test");

	Stdout.newline;
	mixin(traceVal!("args[0]", "Environment.cwd"));

//	auto path = new FilePath(cmd.dir);
//	mixin(traceVal!("path.toString()", "path.isAbsolute()", "path.isFolder()"));

	mixin(traceVal!("cmd.dir"));
	cmd.dir = "..";
	mixin(traceVal!("cmd.dir"));
	cmd.dir = "../..";
	mixin(traceVal!("cmd.dir"));
	cmd.dir = Environment.cwd;
	mixin(traceVal!("cmd.dir"));
	
	cmd.echo("Whee!");
	//testVfs(cmd.dir);

	cmd.exec("myecho", ["I'm echoing,", "hello!"]);
	cmd.exec("myecho I'm echoing, hello!");
	
	cmd.echoing = false;
	cmd.exec("myecho Can't see this because echoing is off");
	cmd.echoing = true;

/+
	Stdout(cmd.prompt("Enter anything:")).newline;
	Stdout(
		cmd.prompt(
			`Enter "yes" or "no":`,
			(char[] input) {
				return cast(bool)tango.core.Array.contains(["yes","no"], input);
			},
			`'{}' is not valid, must enter "yes" or "no"!`
		)
	).newline;
+/

	Stdout.newline;
	bool done = false;

	const char[] helpMsg = `
--Supported Commands--
help                 Displays this message
echo <text>          Echos <text>
pwd                  Print working directory
cd <dir>             Change directory
ls                   Displays current directory contents
exec <prog> <params> Runs program <prog> with paramaters <params>
echoing <on|off>     Chooses whether output from exec'ed programs is displayed
isechoing            Displays current echoing setting
prompt               Prompt for text entry
promptyn             Prompt for "yes" or "no"
exit                 Exits
`;

	void delegate(char[] params)[char[]] cmdLookup = [
		""[]        : (char[] params) { },
		"help"      : (char[] params) { Stdout(helpMsg);         },
		"exit"      : (char[] params) { done = true;             },
		"echo"      : (char[] params) { cmd.echo(params);        },
		"pwd"       : (char[] params) { Stdout(cmd.dir).newline; },
		"cd"        : (char[] params) { cmd.dir = params;        },
		"exec"      : (char[] params) { cmd.exec(params);        },
		"isechoing" : (char[] params) { Stdout(cmd.echoing? "on" : "off").newline; },
		
		"ls":
		(char[] params) {
			displayNodes!(VfsFolder)(cmd.dir, "Directories");
			displayNodes!(VfsFile  )(cmd.dir.self.catalog, "Files");
		},
		
		"prompt":
		(char[] params) {
			Stdout.formatln(
				"You entered: {}",
				cmd.prompt("Enter anything:")
			);
		},
		
		"promptyn":
		(char[] params) {
			Stdout.formatln(
				"You entered: {}",
				cmd.prompt(
					`Enter "yes" or "no":`,
					(char[] input) {
						return cast(bool)tango.core.Array.contains(["yes","no"], input);
					},
					`'{}' is not valid. Please enter "yes" or "no".`
				)
			);
		},
		
		"echoing":
		(char[] params) {
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
			{
				Stdout("ERR: ");
				//Stdout("ERR: "~e.classinfo.name~": ");
				e.writeOut( (char[] msg) {Stdout(msg);} );
				//Stdout.formatln("Exception: {}", e.msg);
			}
		}
		else
			Stdout(`Unknown command (type "help" for list of supported commands)`).newline;
		
		if( !tango.core.Array.contains(["","exit"], command) )
			Stdout.newline;
	}
}
