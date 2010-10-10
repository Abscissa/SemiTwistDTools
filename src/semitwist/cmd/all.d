// SemiTwist D Tools: Library
// Written in the D programming language.

module semitwist.cmd.all;

//public import tango.core.Exception;
//public import tango.core.Version;
//public import tango.io.Console;
//public import tango.io.FilePath;
//public import tango.io.FileSystem;
//public import tango.io.Path;
public import std.stdio;//tango.io.Stdout;
//public import tango.io.device.File;
//public import tango.io.vfs.FileFolder;
public import std.math;//tango.math.Math;
//public import tango.sys.Environment;
//public import tango.text.Unicode;
//public import tango.util.Convert;
public import std.conv;
public import std.string;
public import std.array;
public import std.algorithm : find, sort, reduce;
public import std.iterator;
public import std.file;
public import std.path;
public import std.process;

public import semitwist.cmd.plain;
public import semitwist.cmdlineparser;
public import semitwist.refbox;
public import semitwist.treeout;
public import semitwist.util.all;
public import semitwist.util.compat.all;

// Workaround for conflict between tango.text.Util and tango.core.Array
// on 'contains', 'mismatch', 'count', 'replace'.
/+public static import tango.text.Util;
public import tango.text.Util:
	trim, triml, trimr, strip, stripl, stripr,
	chopl, chopr, delimit, split, splitLines,
	head, join, prefix, postfix, combine,
	repeat, substitute,
	containsPattern,
	index, locate, locatePrior, locatePattern, locatePatternPrior, indexOf,
	matching, isSpace, unescape,
	layout, lines, quotes, delimiters, patterns;
+/
// Workaround for Tango issue #1588  where contains returns size_t instead of bool.
/+public import tango.core.Array:
	find, rfind, kfind, krfind, findIf, rfindIf, findAdj,
	mismatch,
	count, countIf,
	replace, replaceIf,
	remove, removeIf,
	distinct, shuffle, partition, select, sort,
	lbound, ubound,
	bsearch, includes,
	unionOf, intersectionOf, missingFrom, differenceOf,
	makeHeap, pushHeap, popHeap, sortHeap;
import tango.core.Array: _contains = contains;
bool contains(Buf,Pat)(Buf buf, Pat pat)
{
	return cast(bool)_contains(buf, pat);
}
bool contains(Buf,Pat,Pred)(Buf buf, Pat pat, Pred pred)
{
	return cast(bool)_contains(buf, pat, pred);
}
+/