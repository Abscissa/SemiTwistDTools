// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.cmd.plain;

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
//TODO: Make a standard "Press a key to continue..."
//TODO: Make a standard yes/no prompt
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
			// converting-varargs-to-strings crap, so
			// just let it do all the work:
			Stdout(layout.convert([type], _argptr, "{}"));
			_argptr += type.tsize;
		}
		Stdout.newline;
	}
	
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
}
