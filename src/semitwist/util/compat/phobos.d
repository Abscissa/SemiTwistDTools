// SemiTwist Library
// Written in the D programming language.

/++
This module does NOT and is NOT intended to make SemiTwist D Tools
compatible with Phobos (Sorry!). It is merely to aid in migration.

SemiTwist D Tools currently has no plans to switch to Phobos. However,
once SemiTwist D Tools migrates to D2 (which will be right after Tango
officially supports D2), then Tango and Phobos *should* co-exist perfectly
fine together, in which case this module (and any third-party Phobos port),
will likely become obsolete (or perhaps re-purposed).

All code in this "semitwist.util.compat" package should avoid accessing any
other part of SemiTwist D Tools, because doing so might trigger DMD's
forward reference bugs.
+/

module semitwist.util.compat.phobos;

version(Tango) {}
else
{
	version = Foo;
	version = Foo;
	
	//TODO: Create Stdout that mimics Tango's Stdout but forwards to Phobos equivalent
}
