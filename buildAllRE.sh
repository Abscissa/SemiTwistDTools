#!/bin/sh
./bootstrap_stbuild_re.sh
./bin/stbuild_bootstrap all all -clean
./bin/stbuild_bootstrap all release -tool:re
./bin/stbuild_bootstrap all debug -tool:re

rm -f bin/stbuild_bootstrap

