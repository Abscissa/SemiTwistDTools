@echo off
rebuild %2src\semitwist\apps\stmanage\stbuild\main -oqobj\stbuild\debug -ofbin\semitwist-stbuild-debug -Isrc -debug -C-unittest -C-w
move *.map obj\stbuild\debug\ > _junk_.junk 2> _junk_.junk2
copy bin\semitwist-stbuild-debug.exe bin\semitwist-stbuild-test.exe > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
