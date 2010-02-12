// SemiTwist Library
// Written in the D programming language.

/++
Author:
$(WEB www.semitwist.com, Nick Sabalausky)

This has been tested to work with:
  - DMD 1.056 / Tango 0.99.9 / Rebuild 0.76
  - DMD 1.056 / Tango 0.99.9 / xfBuild 0.4

In SVN comments:
(B): Breaking changes
(NB): Non-Breaking changes
+/

// Potentially handy note:
//   DMD output capturing for Programmer's Notepad:
//   ((.)*: )?(warning - )?([ \t]*instantiatied in )?((.)*@)?%f\(%l(:%c)?\):

//TODO: Make separate unittest app, like tango
//TODO: Make automatically-generatable app that forwards to other programs:
//      Ex: Apps: neededApp.exe, foo1.exe, and foo2.exe
//          (Where "foo1" and "foo2" are commonly-used names likely to already be on path):
//          neededApp.exe -> "Usage: 'neededApp foo1' or 'neededApp foo2'"
//          neededApp.exe foo1 param1 -> foo1.exe param1
//          neededApp.exe foo2 a b    -> foo2.exe a b
//      Ex: "goldie parse ...", "goldie calculatorStatic"

module semitwist.util.all;

public import semitwist.util.array;
public import semitwist.util.ctfe;
public import semitwist.util.functional;
public import semitwist.util.io;
public import semitwist.util.mixins;
public import semitwist.util.deferAssert;
public import semitwist.util.reflect;
public import semitwist.util.text;
public import semitwist.util.os;
public import semitwist.util.ver;
