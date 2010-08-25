@echo off
echo Bootstrapping STBuild...

move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
del /Q obj\*.*

rdmd rdmdAlt.d src\semitwist\apps\stmanage\stbuild\main.d -ofbin\stbuild_bootstrap -odobj -Isrc -release -O

move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
del /Q obj\*.*
