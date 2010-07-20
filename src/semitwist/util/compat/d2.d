// SemiTwist Library
// Written in the D programming language.

/++
This module does NOT and is NOT intended to make SemiTwist D Tools
compatible with D2 (Sorry!). It is merely to aid in migration.

SemiTwist D Tools does plan to switch from D1 to D2.

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
