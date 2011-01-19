#!/bin/sh
./scripts/semitwist-bootstrap-stbuild.sh
./bin/semitwist-stbuild-bootstrap all all -clean
./bin/semitwist-stbuild-bootstrap all all -tool:rdmd

rm -f bin/semitwist-stbuild-bootstrap
