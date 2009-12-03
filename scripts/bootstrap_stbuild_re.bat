@echo off
echo Bootstrapping STBuild...

move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
del /Q obj\*.*

rebuild src\semitwist\apps\stmanage\stbuild\main.d -oqobj -ofbin\stbuild_bootstrap -Isrc -release -C-O

move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
del /Q obj\*.*
