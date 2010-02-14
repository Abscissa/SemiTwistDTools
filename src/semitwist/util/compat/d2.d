// SemiTwist Library
// Written in the D programming language.

/++
This module does NOT and is NOT intended to make SemiTwist D Tools
compatible with D2 (Sorry!). It is merely to aid in migration.

SemiTwist D Tools will switch to D2 once Tango officially supports D2
(Although, at that time, SemiTwist D Tools will most likely NOT retain D1
compatibility).

All code in this "semitwist.util.compat" package should avoid accessing any
other part of SemiTwist D Tools, because doing so might trigger DMD's
forward reference bugs.
+/

module semitwist.util.compat.d2;

// To aid migration, all SemiTwist D Tools code should, by convention,
// use 'string' instead of 'char[]', etc.
version(Tango)
{
	// These are already defined in Phobos
	alias char[]  string;
	alias wchar[] wstring;
	alias dchar[] dstring;
}
