#!/bin/sh
echo Bootstrapping STBuild...
#TODO: Clean before and after building
rebuild src/semitwist/apps/stmanage/stbuild/main -oqobj/stmanage/release -ofbin/stbuild_bootstrap -Isrc -release -C-O
