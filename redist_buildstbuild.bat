@echo off
cd stbuild
rebuild src\stmanage\stbuild\main -oqobj -ofbin\stbuild -Isrc -I..\semitwistlib\src -release -C-O
move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
move stbuild.exe ..
cd ..
