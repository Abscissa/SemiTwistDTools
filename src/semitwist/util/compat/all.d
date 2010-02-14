// SemiTwist Library
// Written in the D programming language.

/++
This package does NOT and is NOT intended to make SemiTwist D Tools
compatible with D2 or Phobos (Sorry!). It is merely to aid in migration.

SemiTwist D Tools will switch to D2 once Tango officially supports D2
(Although, at that time, SemiTwist D Tools will most likely NOT retain D1
compatibility).

SemiTwist D Tools currently has no plans to switch to Phobos. However,
once SemiTwist D Tools migrates to D2 (which will be right after Tango
officially supports D2), then Tango and Phobos *should* co-exist perfectly
fine together, in which case this module (and any third-party Phobos port),
will likely become obsolete (or perhaps re-purposed).

All code in this "semitwist.util.compat" package should avoid accessing any
other part of SemiTwist D Tools, because doing so might trigger DMD's
forward reference bugs.

Unless there's a particularly good reason to do otherwise, all SemiTwist D
Tools modules should, by convention, should import this module, and import it
privately.
+/

module semitwist.util.compat.all;

public import semitwist.util.compat.d2;
public import semitwist.util.compat.phobos;
