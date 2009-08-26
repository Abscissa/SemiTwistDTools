#!/bin/sh
./bootstrap_stbuild.sh
./bin/stbuild_bootstrap all all -clean
./bin/stbuild_bootstrap all release
./bin/stbuild_bootstrap all debug

rm -f bin/stbuild_bootstrap

