// SemiTwist D Tools: Library
// Written in the D programming language.

module semitwist.cmd.plain;

//import tango.stdc.stdio;
import tango.sys.Process;
import tango.io.Console;
import tango.io.FilePath;
import tango.io.FileSystem;
import tango.io.Stdout;
import tango.io.vfs.FileFolder;
import tango.text.Util;
import tango.text.convert.Layout;
import tango.util.PathUtil;

import semitwist.util.all;

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
class Cmd
{
	private FilePath _dir; // Working directory
	private static Layout!(char) layout; // Used by echo

	invariant
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
		assert(_dir.isFolder());
		assert(_dir.isAbsolute());

		scope _dirStandard = _dir.dup.standard();
		assert(_dir.toString() == _dirStandard.toString(), "_dir is not in standard form");
	}

	this()
	{
		_dir = new FilePath(FileSystem.getDirectory());
		_dir.standard();
	}
	
	static this()
	{
		layout = new Layout!(char)();
	}

	bool echoing = true;

	// Property
	FileFolder dir()
	{
		//TODO: Don't create a new instance if dir hasn't changed
		return new FileFolder(_dir.toString());
	}
	FileFolder dir(VfsFolder value)
	{
		return dir(value.toString());
	}
	FileFolder dir(char[] value)
	{
		value = FileSystem.toAbsolute(value, _dir.toString());
		scope newDir = new FilePath(value);
		if(newDir.isFolder() && newDir.exists())
			_dir.set( normalize(newDir.toString()), true );
		return dir();
	}
	
	//TODO: Abstract the interface so that the same exec calls work on both win and lin.
	// Plain Versions
	void exec(char[] cmd)
	{
		int errLevel;
		exec(cmd, errLevel);
	}
	void exec(char[] app, char[][] params)
	{
		int errLevel;
		exec(app, params, errLevel);
	}
	
	// With errLevel
	void exec(char[] cmd, out int errLevel)
	{
		auto p = new Process(cmd);
		execProcess(p, errLevel);
	}
	void exec(char[] app, char[][] params, out int errLevel)
	{
		auto p = new Process(app ~ params);
		execProcess(p, errLevel);
	}
	
	// Implementation
	private void execProcess(Process p, out int errLevel)
	{
		//TODO: Find out what happens if wait() is called after the process finishes
		p.workDir = _dir.toString();
		p.copyEnv = true;
		p.redirect = echoing? Redirect.None : Redirect.All;
		p.execute();
		auto r = p.wait();
		errLevel = (r.reason==Process.Result.Exit)? r.status : -1;
	}
	
	void echo(...)
	{
		foreach(int i, TypeInfo type; _arguments)
		{
			if(i > 0) Stdout(" ");

			// Tango's Layout already handles all this
			// converting-varargs-to-strings crap,
			// so let it do all the dirty work:
			Stdout(layout.convert([type], _argptr, "{}"));
			_argptr += type.tsize;
		}
		Stdout.newline;
		Stdout.flush();
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
	char[] prompt(T)(T[] promptMsg, bool delegate(char[]) accept=null, T[] rejectedMsg="")
	{
		char[] reader()
		{
			char[] input;
			Cin.readln(input);
			return trim(input);
		}
		
		return _prompt!(char[],T)(promptMsg, accept, rejectedMsg, &reader);
	}

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
/+
	char[] prompt(char[] msg, bool delegate(char[]) accept=null, char[] msgRejected="")
	{
		char[] input;
		while(true)
		{
			Stdout(msg).flush;
			Cin.readln(input);
			input = trim(input);
			
			if(accept is null)
				break;
			else
			{
				if(accept(input))
					break;
				else
				{
					Stdout.newline;
					Stdout.formatln(msgRejected, input);
				}
			}
		}
		
		return input;
	}
+/
/+
	bool isHelpSwitch(char[] str)
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
