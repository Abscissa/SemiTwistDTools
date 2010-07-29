// SemiTwist D Tools
// STManage: STStart
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

IGNORE THIS APP FOR NOW, IT IS NOT USABLE YET

This has been tested to work with:
  - DMD 1.056 / Tango 0.99.9 / Rebuild 0.76
  - DMD 1.056 / Tango 0.99.9 / xfBuild 0.4
+/

module semitwist.apps.stmanage.ststart.main;

import semitwist.cmd.all;

const string main_d_src = 
`// {0}
// Written in the D programming language

module {0}.main;

import tango.io.Stdout;

int main(string[] args)
{{
	Stdout("{0}: Hello World!").newline;
	return 0;
}
`;

void main(string[] args)
{
	// Prompt stuff
	const string promptOverwrite = "Delete and overwrite (yes/no)? ";
	const string msgFailedYesNo = "You must enter 'yes' or 'no', not '%s'.";
	bool acceptYesNo(string input)
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
	string projectName;
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
	void createDirs(string[] dirs)
	{
		foreach(string dir; dirs)
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
	auto main_d = cmd.dir.file("main.d").create.output;
	main_d.write(main_d_src.sformat(projectName));
	main_d.close;
//	cmd.dir.file("main.d").open.output.write("hello").close;
//	cmd.dir.file("main.d").output.copy("hello").close;
	
//	cmd.dir = originalDir.toString~"/"~projectName;
//	cmd.dir = "%s/%s".format(originalDir, projectName);
//	auto allCreated = cmd.dir.tree;
	cmd.dir = originalDir;
	auto allCreated = cmd.dir.folder(projectName).open.tree;
	writefln("Created %s bytes in %s folder(s) and %s file(s)",
		allCreated.bytes, allCreated.folders, allCreated.files);
	
//	cmd.dir = originalDir;
}
