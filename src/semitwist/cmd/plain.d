// SemiTwist D Tools: Library
// Written in the D programming language.

module semitwist.cmd.plain;

//import tango.stdc.stdio;
//import tango.io.Console;
//import tango.io.FilePath;
//import tango.io.FileSystem;
//import tango.io.Path;
import std.stdio;//tango.io.Stdout;
//import tango.io.vfs.FileFolder;
//import tango.sys.Environment;
//import tango.sys.Process;
//import tango.text.Util;
//import tango.text.convert.Layout;
import std.file;
import std.path;
import std.string;

import semitwist.util.all;
import semitwist.util.compat.all;

Cmd cmd;
static this()
{
	cmd = new Cmd();
}

//TODO: Make promptChar
//TODO: Change prompt to "Press a key to continue..."
//TODO: Make a standard yes/no prompt
//TODO? Rename echoing to exececho or echoexec
//TODO: Handle env var stuff
//TODO: Handle exec stream redirecting
//TODO: Do piping
//TODO: Wrap Vfs
//TODO? Make dir something folder-specific instead of FileFolder?
//TODO: Dup Cmd
//TODO: Add echoerr (or just "err")
//TODO? Make "cmd.dir" (but not copies) affect Environment.cwd
class Cmd
{
	private string _dir; // Working directory
	//private static Layout!(char) layout; // Used by echo

	invariant()
	{
/*
		//Shit, can't seem to do this stuff in here
		mixin(deferAssert!("_dir.exists()"));
		mixin(deferAssert!("_dir.isFolder()"));
		mixin(deferAssert!("_dir.isAbsolute()"));
		
		scope _dirStandard = _dir.dup.standard();
		mixin(deferAssert!("_dir.toString() == _dirStandard.toString()", "_dir is not in standard form"));

		flushAsserts();
*/
		assert(_dir.exists());
		assert(_dir.isdir());
		assert(_dir.isabs());

		//scope _dirStandard = _dir.dup.standard();
		//assert(_dir.toString() == _dirStandard.toString(), "_dir is not in standard form");
	}

	this()
	{
		_dir = getcwd();
		//_dir.standard();
	}
	
/+	static this()
	{
		layout = new Layout!(char)();
	}
+/
	bool echoing = true;

	// Property
/+	FileFolder dir()
	{
		//TODO: Don't create a new instance if dir hasn't changed
		return new FileFolder(_dir.toString());
	}
	FileFolder dir(VfsFolder value)
	{
		return dir(value.toString());
	}
	FileFolder dir(string value)
	{
		auto cwdSave = Environment.cwd;
		Environment.cwd = _dir.toString();
		value = Environment.toAbsolute(value);
		Environment.cwd = cwdSave;

		scope newDir = new FilePath(value);
		if(newDir.isFolder() && newDir.exists())
			_dir.set( normalize(newDir.toString()), true );
		return dir();
	}+/
	
	//TODO: Abstract the interface so that the same exec calls work on both win and lin.
	// Plain Versions
//TODO***
/+	void exec(string cmd)
	{
		int errLevel;
		exec(cmd, errLevel);
	}
	void exec(string app, string[] params)
	{
		int errLevel;
		exec(app, params, errLevel);
	}+/
	
	// With errLevel
//TODO***
/+	void exec(string cmd, out int errLevel)
	{
		auto p = new Process(cmd);
		execProcess(p, errLevel);
	}
	void exec(string app, string[] params, out int errLevel)
	{
		auto p = new Process(app ~ params);
		execProcess(p, errLevel);
	}+/
	
	// Implementation
/+	private void execProcess(Process p, out int errLevel)
	{
		//TODO: Find out what happens if wait() is called after the process finishes
		p.workDir = _dir.toString();
		p.copyEnv = true;
		p.redirect = echoing? Redirect.None : Redirect.All;
		p.execute();
		auto r = p.wait();
		errLevel = (r.reason==Process.Result.Exit)? r.status : -1;
	}
+/	
	void echo(T...)(T args)
	{
		foreach(int i, T arg; args)
		{
			if(i > 0) write(" ");
			write(arg);
		}
		writeln();
		stdout.flush();
	}
	
	private T _prompt(T, TChar)(TChar[] promptMsg, bool delegate(T) accept,
	                            TChar[] rejectedMsg, T delegate() reader)
	{
		T input;
		while(true)
		{
			Stdout(promptMsg).flush;
			input = reader();
			
			if(accept is null)
				break;
			else
			{
				if(accept(input))
					break;
				else
				{
					Stdout.newline;
					Stdout.formatln(rejectedMsg, input);
				}
			}
		}
		
		return input;
	}

	// Input is Utf8-only for now because Cin is used which is Utf8-only
//TODO***
/+	string prompt(T)(T[] promptMsg, bool delegate(string) accept=null, T[] rejectedMsg="")
	{
		string reader()
		{
			string input;
			Cin.readln(input);
			return strip(input);
		}
		
		return _prompt!(string,T)(promptMsg, accept, rejectedMsg, &reader);
	}
+/
/+
// Doesn't work right now because I need to find a way to wait for and capture
// exactly one keypress. Cin.readln and getchar both wait for a newline.

	// dchar not currently supported, because getchar/getwchar are used which
	// don't have a Utf32 equivilent.
	T promptChar(T)(T[] promptMsg, bool delegate(T) accept=null, T[] rejectedMsg="")
	{
		T reader()
		{
			static if(is(T==char))
				return cast(T)getchar();
			else static if(is(T==wchar))
				return cast(T)getwchar();
			else
				static assert(false, "T must be char or wchar for promptChar");
		}
		
		return _prompt!(T,T)(promptMsg, accept, rejectedMsg, &reader);
	}
+/

	void pause()
	{
/+
// Can't do it this way until I get promptChar working
		promptChar("Press a key to continue...");
		cmd.echo(); // The prompt doesn't output a newline
+/
		prompt("Press Enter to continue...");
	}


	string prompt(string msg, bool delegate(string) accept=null, string msgRejected="")
	{
		string input;
		while(true)
		{
			write(msg);
			stdout.flush();
			stdin.readln(input);
			input = strip(input);
			
			if(accept is null)
				break;
			else
			{
				if(accept(input))
					break;
				else
				{
					writeln();
					writefln(msgRejected, input);
				}
			}
		}
		
		return input;
	}

/+
	bool isHelpSwitch(string str)
	{
		if(str.length < 3)
			return false;
			
		if(str[0..2] == "--")
			str = str[2..$];
		else if("-/".contains(str[0]))
			str = str[1..$];
		else
			return false;
		
		return ["h"[], "help", "?"].contains(str.toLower());
	}
+/
}
