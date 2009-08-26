#!/bin/sh
echo Bootstrapping ST Build...
rebuild src/semitwist/apps/stmanage/stbuild/main -oqobj/stmanage/release -ofbin/stbuild_bootstrap -Isrc -release -C-O

