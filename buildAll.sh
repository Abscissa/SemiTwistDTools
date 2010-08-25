#!/bin/sh
./scripts/bootstrap_stbuild.sh
./bin/stbuild_bootstrap all all -clean
./bin/stbuild_bootstrap all all -tool:rdmd

rm -f bin/stbuild_bootstrap
