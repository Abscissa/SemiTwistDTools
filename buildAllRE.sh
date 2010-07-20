#!/bin/sh
./scripts/bootstrap_stbuild_re.sh
./bin/stbuild_bootstrap all all -clean
./bin/stbuild_bootstrap all all -tool:re

rm -f bin/stbuild_bootstrap
