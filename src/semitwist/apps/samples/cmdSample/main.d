// SemiTwist D Tools
// Samples: semitwist.cmd sample
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Uses:
- DMD 1.043
- Tango 0.99.8
*/

module semitwist.apps.samples.cmdSample.main;

import semitwist.cmd.all;

void showSectionHeader(char[] str)
{
	cmd.echo();
	cmd.echo("--------", str, "--------");
}

//TODO: Find those functions in tango to read and maybe write a file in one line.
//      And add the import to semitwist.cmd.all, and add samples for it here.
//   -> tango.io.device.File: char[] blah = File.get("blah.txt");

void main(char[][] args)
{
	// ----- semitwist.cmd: cmd.echo -----
	// - Script-style alternative to Stdout, largely here for completeness
	// - May be extended later to support a limited form of
	//   "blah $myvar blah"-style string expansion.
	// - Note that a newline is automatically appended,
	//   which is useful for shell-script-style apps.
	showSectionHeader("semitwist.cmd: cmd.echo");
	cmd.echo("Hello");
	cmd.echo("This is on a separate line");
	cmd.echo("Multiple mixed-types:"c, 2, "+"w, 3.1, "="d, 5.1);
	cmd.echo("No worry about forgetting spaces:");
	cmd.echo(32, 64, 128, 256);
	class Foo {
		char[] toString() {
			return "Any type that Stdout can handle is ok.";
		}
	}
	cmd.echo(new Foo(), "See?");
	Stdout("Of course, ");
	Stdout.formatln("ordinary Stdout {} available too.", "is");

	// ----- semitwist.util.text: sformat/sformatln -----
	// - Wraps tango's Layout seamlessly for char, wchar and dchar.
	// - Note that you don't need to manually instantiate it.
	// - Using D's array-method calling syntax is, of course, optional.
	//   (But I like it.)
	showSectionHeader("semitwist.util.text: sformat/sformatln");
	auto myStr8 = "Hello {}".sformat("Joe");
	cmd.echo(myStr8);
	auto myStr16 = "This {} wstr ends in a newline, {}"w.sformatln("happy", "whee");
	cmd.echo(myStr16);
	cmd.echo("See? There was an extra newline up there.");
	
	// ----- semitwist.util.mixins: trace -----
	// - Useful for debugging.
	// - Outputs file and line information
	showSectionHeader("semitwist.util.mixins: trace");
	mixin(trace!());
	mixin(trace!());
	mixin(trace!("======== this is easy to spot ========"));
	
	// ----- semitwist.util.mixins: traceVal -----
	// - Useful for debugging.
	// - DRY way to output both an expression and the expression's value
	showSectionHeader("semitwist.util.mixins: traceVal");
	double myDouble = 5.55;
	int myInt = 7;
	mixin(traceVal!("myDouble", "myInt   ", "   myInt", "4*7"));
	mixin(traceVal!(`"Any expression {}".sformat("is ok")`));
	
	// ----- semitwist.cmd: cmd.exec -----
	// - Easy tango.sys.Process wrapper for running apps
	//
	// We'll test this with two small sample apps:
	//   - showargs: Lists the args passed into it
	//   - seterrorlevel: Sets the error level to a desired value
	showSectionHeader("semitwist.cmd: cmd.exec");
	cmd.exec("showargs Hello from D!"); // Three args
	cmd.exec(`showargs "Hello from D!"`); // One arg with spaces
	cmd.exec("showargs", ["arg 1"[], "arg 2"]); // Two args, each with spaces
	int errLevel;
	mixin(traceVal!("errLevel"));
	cmd.exec("seterrorlevel 42", errLevel);
	mixin(traceVal!("errLevel"));
	
	// ----- semitwist.cmd: cmd.echoing -----
	// - Determines whether an exec'd program's stdout/stderr are actually
	//   sent to this program's stdout/stderr or are hidden.
	// - Not to be confused with the functionality of Win's "echo on"/"echo off"
	//
	// We'll test this with a small sample app:
	//   - myecho: Like ordinary echo, but needed on Win because Win's echo
	//             is not an actual executable and therefore can't be launched
	//             by the tango.sys.Process used by exec.
	showSectionHeader("semitwist.cmd: cmd.echoing");
	cmd.exec("myecho You can see this");
	cmd.echoing = false;
	cmd.exec("myecho You cannot see this");
	cmd.echoing = true;
	cmd.exec("myecho You can see this again");
	
	// ----- semitwist.cmd: cmd.prompt -----
	// - Easy way to prompt for information interactively
	showSectionHeader("semitwist.cmd: cmd.prompt");
	char[] input;
	input = cmd.prompt("Type some stuff: ");
	cmd.echo("You entered:", input);

	// Easy prompt-with-validation
	char[] promptMsg = "Do you want 'coffee' or 'tea'? ";
	char[] failureMsg = "Please enter 'coffee' or 'tea', not '{0}'";
	bool accept(char[] input)
	{
		return ["coffee"[], "tea"].contains(toLower(input));
	}
	// This will *not* return until the user enters a valid choice,
	// so we don't need to do any more validation.
	input = cmd.prompt(promptMsg, &accept, failureMsg);
	cmd.echo("Tough luck! No", input, "for you!");
/+
	// Single-char prompts
	auto letter = cmd.promptChar("Enter any letter: ");
	cmd.echo("You entered:", letter);
	// Validation supported on single-char prompts, too.
	promptMsg = "Do you like D (y/n)? ";
	failureMsg = "Please enter 'y' or 'n', not '{0}'";
	bool acceptChar(char input)
	{
		return "YNyn".contains(input);
	}
	letter = cmd.promptChar(promptMsg, &acceptChar, failureMsg);
	cmd.echo("Yy".contains(letter)? "Yay!" : "Dang...");
+/
	// Prompt and wait for any keypress
	cmd.pause();

	// ----- semitwist.cmd: cmd.dir -----
	// - Get/Set cmd's working directory
	// - Note that setting dir does NOT affect the app's working directory
	showSectionHeader("semitwist.cmd: cmd.dir");
	cmd.echo("cmd is in", cmd.dir);          // Starts in the app's working dir
	cmd.dir.folder("myNewDir").create;       // dir exposes Tango's VfsFolder
	cmd.dir = "myNewDir";                    // Enter newly created directory
	cmd.dir = "..";                          // Back up
	cmd.dir = cmd.dir.folder("new2").create; // Create/enter new dir in one line
	  // (Note that cmd.dir can be assigned either char[] or Tango's VfsFolder)
	
	// Create/open/write/close a new file in this new "new2" directory.
	auto filename = "file.txt";
	auto fout = cmd.dir.file(filename).create.output;
	fout.write("Content of {0}".sformat(filename)); // Easy templated content!
	fout.close;
	
	// Look ma! Independent simultaneous cmd interfaces!
	auto cmd2 = new Cmd();
	// cmd2's dir is unaffected by cmd's dir
	mixin(traceVal!("cmd.dir", "cmd2.dir")); // Note the usefullness of traceVal
	
	// Changing dir doesn't change the app's working dir,
	// but we can still change it if we want to.
	// Remember that cmd is still in the newly-created "new2",
	// so let's go there:
	mixin(traceVal!("FileSystem.getDirectory()")); // Original working dir
	FileSystem.setDirectory(cmd.dir.toString);
	mixin(traceVal!("FileSystem.getDirectory()")); // New working dir
	
	// Now a newly created Cmd is in "new2",
	// because we changed the app's working directory.
	// (But ordinarily, you wouldn't need to do this. It's just to illustrate.)
	auto cmd3 = new Cmd();
	mixin(traceVal!("cmd3.dir"));
	
	// Let's undo all the directory changing now:
	cmd.dir = "..";
	// (note we never changed cmd2's dir)
	cmd3.dir = "..";
	FileSystem.setDirectory(cmd.dir.toString);
	// Now all the working dirs are back to their original state.
	// We also could have done it like this:
	//
	// auto saveOriginalDir = cmd.dir;
	//   ...do all our messing around...
	// cmd.dir = saveOriginalDir;
	// cmd3.dir = saveOriginalDir;
	// FileSystem.setDirectory(saveOriginalDir.toString);

	// ----- tango.io.vfs.FileFolder -----
	// - More explanation and examples of this are available at:
	//   http://www.dsource.org/projects/tango/wiki/ChapterVFS
	showSectionHeader("tango.io.vfs.FileFolder");
	cmd.echo("Current '.' dir is "~cmd.dir.toString);
	cmd.echo("cmd.dir contains:");
	foreach(VfsFolder folder; cmd.dir)
	{
		// Remember, mixins can generate nultiple statements
		mixin(traceVal!("folder", "folder.name"));
	}

	auto entireParentTree = cmd.dir.folder("..").open.tree;
	auto entireParentDir = cmd.dir.folder("..").open.self;
	
	cmd.echo("Total bytes in '..' dir: {}".sformat(entireParentDir.bytes));
	cmd.echo("Total bytes in entire '..' tree: {}".sformat(entireParentTree.bytes));
	
	cmd.echo("Total num folders in '..' dir: {}".sformat(entireParentDir.folders));
	foreach(VfsFolder folder; cmd.dir.folder("..").open)
	{
		cmd.echo(" -", folder);
		cmd.echo("    (", (new FilePath(normalize(folder.toString))).native, ")");
		cmd.echo();
	}
	
	cmd.echo("Total num folders in entire '..' tree: {}".sformat(entireParentTree.folders));
	foreach(VfsFolder folder; cmd.dir)
		cmd.echo(" -"~folder.toString);
	
	cmd.echo("Total num files in '..' dir: {}".sformat(entireParentDir.files));
	foreach(VfsFile file; entireParentDir.catalog)
		cmd.echo(" -"~file.toString);
	
	cmd.echo("Total num files in entire '..' tree: {}".sformat(entireParentTree.files));
	foreach(VfsFile file; entireParentTree.catalog)
		cmd.echo(" -"~file.toString);
	
	cmd.echo("Total num *.txt files in entire '..' tree: {}".sformat(entireParentTree.catalog("*.txt")));
	foreach(VfsFile file; entireParentTree.catalog("*.txt"))
		cmd.echo(" -"~file.toString);
		
	//TODO: Add deferAssert stuff
}
