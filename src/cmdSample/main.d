// SemiTwist Library: semitwist.cmd sample:
// Creating a new subversion repository
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Uses:
- DMD 1.043
- Tango 0.99.8
*/

//TODO: Change this to new svnRepoCreate app, and make new sample app
module cmdSample.main;

import semitwist.cmd.all;

void main(char[][] args)
{
	auto cmd = new CommandLine();

	// Prompt stuff
	const char[] promptOverwrite = "Delete and overwrite (yes/no)? ";
	const char[] msgFailedYesNo = "You must enter 'yes' or 'no', not '{}'.";
	bool acceptYesNo(char[] input)
	{
		return input=="yes" || input=="no";
	}
	
	// Config
//	auto rootDirs = ["trunk"[],"branches","tags","downloads"];
//	auto trunkDirs = ["bin"[],"obj","src"];
	
	// Header
	Stdout("SemiTwist Library: semitwist.cmd sample:").newline;
	Stdout("Creating a new subversion repository").newline;
	Stdout.newline;
	
	// Do Checks
	char[] projectName;
	if(args.length > 1)
		projectName = args[1];
	else
		projectName = cmd.prompt("Enter project name: ");
	
	if(cmd.dir.folder(projectName).exists)
	{
		Stdout("Project already exists").newline;
		auto input = cmd.prompt(promptOverwrite, &acceptYesNo, msgFailedYesNo);
		if(input == "no")
			return;
		cmd.dir.folder(projectName).open.clear;
		return;
	}
	
	// Set up dirs/files for initial commit
	void createDirs(char[][] dirs)
	{
		foreach(char[] dir; dirs)
			cmd.dir.folder(dir).create;
	}

	auto originalDir = cmd.dir;
	cmd.dir.folder(projectName).create;

	cmd.dir = projectName;
	createDirs(["trunk"[],"branches","tags","downloads"]);

	cmd.dir = "trunk";
	createDirs(["bin"[],"obj","src"]);
		
	cmd.dir = "bin";
	createDirs(["debug"[],"release"]);
		
	cmd.dir = "../src";
	cmd.dir.folder(projectName).create;

	cmd.dir = projectName;
	cmd.dir.file("main.d").create;
//	cmd.dir.file("main.d").output.copy("hello").close;
	
//	cmd.dir = originalDir.toString~"/"~projectName;
//	cmd.dir = "{}/{}".sformat(originalDir, projectName);
//	auto allCreated = cmd.dir.tree;
	cmd.dir = originalDir;
	auto allCreated = cmd.dir.folder(projectName).open.tree;
	Stdout.formatln("Created {} bytes in {} folders and {} files",
		allCreated.bytes, allCreated.folders, allCreated.files);
	
//	cmd.dir = originalDir;
}
