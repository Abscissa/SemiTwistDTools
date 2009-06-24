// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.cmd;

public import tango.io.vfs.FileFolder;

import tango.io.Stdout;

import tango.sys.Process;
import tango.io.FilePath;
import tango.io.FileSystem;
import tango.util.PathUtil;

import semitwist.util.all;

class CommandLine
{
	private FilePath _dir; // Working directory

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

	// Property
	char[] dir()
	{
		return _dir.toString();
	}
	char[] dir(char[] value)
	{
		value = FileSystem.toAbsolute(value, _dir.toString());
		scope newDir = new FilePath(value);
		if(newDir.isFolder() && newDir.exists())
			_dir.set( normalize(newDir.toString()), true );
		return dir();
	}

	// Plain Versions
	char[] exec(char[] cmd)
	{
		int errLevel;
		return exec(cmd, errLevel);
	}
	char[] exec(char[] app, char[][] params)
	{
		int errLevel;
		return exec(app, params, errLevel);
	}
	
	// With errLevel
	char[] exec(char[] cmd, out int errLevel)
	{
		auto p = new Process(cmd);
		return execProcess(p, errLevel);
	}
	char[] exec(char[] app, char[][] params, out int errLevel)
	{
		auto p = new Process(app ~ params);
		return execProcess(p, errLevel);
	}
	
	// Implementation
	private char[] execProcess(Process p, out int errLevel)
	{
		//TODO: Find out what happens if wait() is called after the process finishes
		p.workDir = _dir.toString();
		p.execute();
		auto r = p.wait();
		errLevel = (r.reason==Process.Result.Exit)? r.status : -1;
		return "".dup;
	}
	
	void echo(char[] msg)
	{
		Stdout.formatln("{}", msg);
	}
}
