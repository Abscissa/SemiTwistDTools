// SemiTwist Library
// Written in the D programming language.

module semitwist.util.process;

import std.conv;
import std.file;
import std.process;
import std.stream;
import std.string;

version(Windows)
{
	import core.sys.windows.windows;
	extern(Windows) int CreatePipe(
		HANDLE* hReadPipe,
		HANDLE* hWritePipe,
		SECURITY_ATTRIBUTES* lpPipeAttributes,
		uint nSize);
}
else
{
	import core.sys.posix.unistd;
}

import semitwist.util.all;

void createPipe(out HANDLE readHandle, out HANDLE writeHandle)
{
	version(Windows)
	{
		auto secAttr = SECURITY_ATTRIBUTES(SECURITY_ATTRIBUTES.sizeof, null, true);
		if(!CreatePipe(&readHandle, &writeHandle, &secAttr, 0))
			throw new Exception("Couldn't create pipe");
	}
	else
	{
		int[2] pipeHandles;
		if(pipe(pipeHandles) != 0)
			throw new Exception("Couldn't create pipe");
		readHandle  = pipeHandles[0];
		writeHandle = pipeHandles[1];
	}
}

bool evalCleanup = true;

//TODO: Support string/wstring in addition to char[]/wchar[]
TRet eval(TRet)(string code, string imports="", string rdmdOpts="")
{
	void removeIfExists(string filename)
	{
		if(exists(filename))
			remove(filename);
	}
	void cleanup(string tempName)
	{
		if(evalCleanup)
		{
			removeIfExists(tempName~".d");
			removeIfExists(tempName~".d.deps");
			removeIfExists(tempName~".map");
			version(Windows)
				removeIfExists(tempName~".exe");
			else
				removeIfExists(tempName);
		}
	}

	enum boilerplate = q{
		import std.conv;
		import std.process;
		import std.stream;
		import std.string;
		version(Windows) import std.c.windows.windows;
		%s
		alias %s TRet;
		void main(string[] args)
		{
			static if(is(TRet==void))
				_main();
			else
			{
				if(args.length < 2 || !std.string.isNumeric(args[1]))
					throw new Exception("First arg must be file handle for the return value");

				auto writeHandle = cast(HANDLE)std.conv.to!size_t(args[1]);
				auto retValWriter = new std.stream.File(writeHandle, FileMode.Out);

				auto ret = _main();
				retValWriter.write(ret);
			}
		}
		TRet _main()
		{
			%s
		}
	}.normalize();
	
	code = boilerplate.format(imports, TRet.stringof, code);
	
	HANDLE retValPipeRead;
	HANDLE retValPipeWrite;
	static if(!is(TRet==void))
	{
		createPipe(retValPipeRead, retValPipeWrite);
		auto retValReader = new std.stream.File(retValPipeRead, FileMode.In);
	}
	
	auto tempName = "eval_st_"~md5(code);
	std.file.write(tempName~".d", code);
	scope(exit) cleanup(tempName);

	auto rdmdName = "rdmd";

	auto errlvl = system(rdmdName~" -of"~tempName~" "~rdmdOpts~" "~tempName~" "~to!string(cast(size_t)retValPipeWrite));
	
	if(errlvl != 0)
		//TODO: Include failure text, and what part failed: compile or execution
		throw new Exception("eval failed");
	
	static if(is(TRet==void))
		return;
	else
	{
		TRet retVal;
		retValReader.read(retVal);
		return retVal;
	}
}

mixin(unittestSemiTwistDLib(q{
	//enum test_eval1 = q{ eval!int(q{ writeln("Hello World!"); return 7; }, q{ import std.stdio; }) };
	//mixin(deferEnsure!(test_eval1, q{ _==7 }));

	enum test_eval2 = q{ eval!int(q{ return 42; }) };
	mixin(deferEnsure!(test_eval2, q{ _==42 }));

	enum test_eval3 = q{ eval!(char[])(q{ return "Test string".dup; }) };
	mixin(deferEnsure!(test_eval3, q{ _=="Test string" }));

	enum test_eval4 = q{ eval!void(q{ return; }) };
	//mixin(deferEnsure!(test_eval4, q{ true })); //TODO: Fix error: "voids have no value"
	mixin(test_eval4~";");
}));
