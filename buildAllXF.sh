#!/bin/sh
./scripts/bootstrap_stbuild_xf.sh
./bin/stbuild_bootstrap all all -clean
./bin/stbuild_bootstrap all release -tool:xf
./bin/stbuild_bootstrap all debug -tool:xf

rm -f bin/stbuild_bootstrap
