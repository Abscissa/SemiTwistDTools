// SemiTwist Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

Requires:
- DMD 1.041
- Tango 0.99.8

In SVN comments:
(B): Breaking changes
(NB): Non-Breaking changes

*/

// DMD output capturing for Programmer's Notepad:
// %f\(%l\):

module semitwist.util.all;

public import semitwist.util.array;
public import semitwist.util.ctfe;
public import semitwist.util.functional;
public import semitwist.util.io;
public import semitwist.util.mixins;
public import semitwist.util.nonFatalAssert;
public import semitwist.util.reflect;
public import semitwist.util.text;

/*
//TODO: Turn this into a debugmode-only alias/func
//      (can't do it until there's a way to get
//      the file and line of instantiation)
Stdout.formatln("blah: {} (line {})", __FILE__, __LINE__);
*/

/*
// Simon Kjaeraas
import std.stdio;
import std.traits;

template _debug(alias f, int line = __LINE__, string file = __FILE__)
{
	ReturnType!(f) _debug(ParameterTypeTuple!(f) u)
	{
		writefln("%s(%d) executed.", file, line);
		return f(u);
	}
}


Usage:

_debug(function)(parameters);
*/
/*
// Doesn't work, __FILE__ and __LINE__ evaluated here, not at instantiation
import tango.io.Stdout;
import tango.core.Traits;
template _trace(alias f, int line = __LINE__, char[] file = __FILE__)
{
	ReturnTypeOf!(f) _trace(ParameterTupleOf!(f) u)
	{
		Stdout.formatln("{}({}): Executing", file, line);
		return f(u);
	}
}
*/