#!/bin/sh
echo Bootstrapping STBuild...
#TODO: Clean before and after building
rdmd rdmdAlt.d --build-only -ofbin/stbuild_bootstrap -odobj -Isrc -release -O src/semitwist/apps/stmanage/stbuild/main.d
