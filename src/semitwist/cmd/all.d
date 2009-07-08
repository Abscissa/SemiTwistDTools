// SemiTwist D Tools: Library
// Written in the D programming language.

/** 
Author:
$(WEB www.semitwist.com, Nick Sabalausky)
*/

module semitwist.cmd.all;

public import tango.io.Console;
public import tango.io.FilePath;
public import tango.io.FileSystem;
public import tango.io.Stdout;
public import tango.io.device.File;
public import tango.io.vfs.FileFolder;
public import tango.text.Unicode;
public import tango.text.Util;
public import tango.util.PathUtil;

public import semitwist.cmd.plain;
public import semitwist.util.all;

// Work around issue #1588 in Tango 0.99.8 (fixed in trunk)
// where contains returns size_t instead of bool.
public import tango.core.Array:
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
