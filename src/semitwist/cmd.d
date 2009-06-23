// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.cmd;

import tango.io.Stdout;

import tango.sys.Process;
import tango.io.FilePath;
import tango.io.FileScan;
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

//TODO: Scratch this stuff, use tango.io.vfs.FileFolder instead
class CmdNode : FilePath
{
	this(char[] path)
	{
		super(path);
	}
}

class CmdDir : CmdNode
{
	invariant
	{
		// Can't check this because it would trigger infinite recursion
//		mixin(deferAssert!("isFolder()"));
//		flushAsserts();
	}
	
	this(char[] path)
	{
		super(path);
		if(!isFolder())
			throw new Exception("Not a directory");
	}

	CmdNode[] nodes(bool recurse)
	{
		return nodes("*", recurse);
	}
	
	CmdNode[] dirs(bool recurse)
	{
		return dirs("*", recurse);
	}
	
	CmdNode[] files(bool recurse)
	{
		return files("*", recurse);
	}
	
	CmdNode[] nodes(char[] glob="*", bool recurse=false)
	{
		return cast(CmdNode[])dirs(glob, recurse) ~ cast(CmdNode[])files(glob, recurse);
	}

	CmdDir[] dirs(char[] glob="*", bool recurse=false)
	{
		auto scan = new FileScan();
		scan(
			this.toString(),
			(FilePath fp, bool isDir)
			{
				bool dirMatchesGlob = isDir && ( glob=="*"||patternMatch(fp.toString(), glob) );
				if(recurse)
					return dirMatchesGlob;
				else
				{
					bool ret = dirMatchesGlob && (this.toString[0..$-1] == fp.toString || this.toString[0..$-1] == fp.parent);
					if(isDir)
					{
						mixin(trace!("-----------------"));
						mixin(traceVal!(
							"dirMatchesGlob",
							"ret          ",
							"this         ",
							"this.toString",
							"fp           ",
							"fp.toString  ",
							"fp.parent    "
						));
					}
					return ret;
				}
			},
			true
		);

		CmdDir[] dirs;
		dirs.length  = scan.folders.length;
		for(int i=0; i<dirs.length; i++)
			dirs[i] = new CmdDir(scan.folders[i].toString);
		
		return dirs;
	}

	CmdFile[] files(char[] glob="*", bool recurse=false)
	{
		auto scan = new FileScan();
		if(glob=="*")
			scan(this.toString(), recurse);
		else
			scan(
				this.toString(),
				(FilePath fp, bool isDir)
				{
					return isDir || patternMatch(fp.toString(), glob);
				},
				recurse
			);

		CmdFile[] files;
		files.length = scan.files.length;
		for(int i=0; i<files.length; i++)
			files[i] = new CmdFile(scan.files[i].toString);
		
		return files;
	}
}

class CmdFile : CmdNode
{
	invariant
	{
		// Can't check this because it would trigger infinite recursion
//		mixin(deferAssert!("isFile()"));
//		flushAsserts();
	}
	
	this(char[] path)
	{
		super(path);
		if(!isFile())
			throw new Exception("Not a file");
	}
}
