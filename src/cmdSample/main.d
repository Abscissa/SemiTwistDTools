// SemiTwist Library: semitwist.cmd sample
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Uses:
- DMD 1.043
- Tango 0.99.8
*/

module cmdSample.main;

import semitwist.cmd.all;

void main(char[][] args)
{
	// ----- semitwist.cmd: cmd.echo -----
	// - Kind of a pointless alternative to Stdout right now,
	//   but it's here for completeness and it may be extended later to support
	//   a limited form of "blah $myvar blah"-style string expansion.
	// - Also note that a newline is automatically appended,
	//   which is useful for shell-script-style apps.
	cmd.echo("SemiTwist Library: semitwist.cmd sample");
	cmd.echo("This is on a separate line");
	cmd.echo();
	
	// ----- semitwist.util.text: sformat -----
	// - Wraps tango's Layout seamlessly for char, wchar and dchar.
	// - Note that you don't need to manually instantiate it.
	// - Using D's array-method calling syntax is, of course, optional.
	//   (But I like it.)
	auto myStr8 = "Hello {}".sformat("Joe");
	cmd.echo(myStr8);
	auto myStr16 = "This {} wstr ends in a newline, {}"w.sformatln("happy", "whee");
	//cmd.echo(myStr16);
	Stdout(myStr16).newline;
	
	// ----- semitwist.util.mixins: trace -----
	// - Useful for debugging.
	// - Outputs file and line information
	mixin(trace!());
	mixin(trace!());
	mixin(trace!("-------- this is easy to spot -------"));
	
	// ----- semitwist.util.mixins: traceVal -----
	// - Useful for debugging.
	// - DRY way to outputs both an expression and the expression's value
	int myInt = 5;
	mixin(traceVal!("myInt", "  myInt  ", "4*7"));
	mixin(traceVal!(`"Hello {}".sformat("world")`));
	
	// ----- semitwist.cmd: cmd.exec -----
	// - Easy wrapper for tango.sys.Process to run apps
	//
	// We'll test this with two small sample apps:
	//   - seterrorlevel: Sets the error level to a desired value
	//   - myecho: Like ordinary echo, but needed on Win because Win's echo
	//             is not an actual executable and therefore can't be launched
	//             by the tango.sys.Process used by exec.
	cmd.exec("myecho Hello from D!"); // Three args
	cmd.exec(`myecho Hello "from D!"`); // Two args, one with a space
	cmd.exec("myecho", ["Hello"[], "from D!"]); // Two args, one with a space
	int errLevel;
	mixin(traceVal!("errLevel"));
	cmd.exec("seterrorlevel 42", errLevel);
	mixin(traceVal!("errLevel"));
	
	// ----- semitwist.cmd: cmd.echoing -----
	// - Determines whether an exec'd program's stdout/stderr are actually
	//   sent to this program's stdout/stderr or are hidden.
	// - Not to be confused with the functionality of Win's "echo on"/"echo off"
	cmd.exec("myecho You can see this");
	cmd.echoing = false;
	cmd.exec("myecho You cannot see this");
	cmd.echoing = true;
	cmd.exec("myecho You can see this again");
	
	// ----- semitwist.cmd: cmd.prompt -----
	// - Easy way to prompt for information interactively
	char[] input;
	input = cmd.prompt("Type some stuff: ");
	cmd.echo("You entered: "~input);

	// Easy prompt-with-validation
	const char[] promptMsg = "Do you want 'coffee' or 'tea'? ";
	const char[] failureMsg = "Please enter 'coffee' or 'tea', not '{0}'";
	bool accept(char[] input)
	{
		//return input=="coffee" || input=="tea";
		// FWIW, I like doing it this way:
		//return cast(bool)["coffee"[], "tea"].contains(input);
		return cast(bool)tango.core.Array.contains(["coffee"[], "tea"], input);
		// Note: The cast is only needed with Tango 0.99.8, not trunk
		//TODO: Is that true?
	}
	// This will *not* return until the user enters a valid choice,
	// so we don't need to do any more validation.
	input = cmd.prompt(promptMsg, &accept, failureMsg);
	cmd.echo("Tough luck! No "~input~" for you!");

	// ----- semitwist.cmd: cmd.dir -----
	// - Get/Set cmd's working directory
	// - Note that setting dir does NOT affect the app's working directory
	cmd.echo("cmd is in "~cmd.dir.toString); // Starts in the app's working dir
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
	// (But ordinarily, you wouldn't need to do this.)
	auto cmd3 = new Cmd();
	mixin(traceVal!("cmd3.dir"));
	
	// But let's undo all the directory changing now:
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
		cmd.echo(" -"~folder.toString);
		cmd.echo("  ("~(new FilePath(normalize(folder.toString))).native.toString~")");
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
}
