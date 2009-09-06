@echo off
echo Bootstrapping ST Build...
rebuild src\semitwist\apps\stmanage\stbuild\main -oqobj\stmanage\release -ofbin\stbuild_bootstrap -Isrc -release -C-O
move *.map obj\stmanage\release > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
