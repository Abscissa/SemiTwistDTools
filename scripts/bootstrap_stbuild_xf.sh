#!/bin/sh
echo Bootstrapping STBuild...
#TODO: Clean before and after building
xfbuild src/semitwist/apps/stmanage/stbuild/main.d +obin/stbuild_bootstrap +Oobj +Dobj/stbuild_bootstrap.deps +rmo -Isrc -release -O
