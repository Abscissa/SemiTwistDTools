// SemiTwist Library
// Written in the D programming language.

/++
This package does NOT and is NOT intended to make SemiTwist D Tools
compatible with D2 or Phobos (Sorry!). It is merely to aid in migration.

SemiTwist D Tools does plan to switch from D1 to D2.

All code in this "semitwist.util.compat" package should avoid accessing any
other part of SemiTwist D Tools, because doing so might trigger DMD's
forward reference bugs.

Unless there's a particularly good reason to do otherwise, all SemiTwist D
Tools modules, by convention, should import this module, and import it
privately.
+/

module semitwist.util.compat.all;

public import semitwist.util.compat.d2;
public import semitwist.util.compat.phobos;
