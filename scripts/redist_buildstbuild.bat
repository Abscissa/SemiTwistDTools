rem TODO: Fix this up, it's probably broken.
@echo off
cd stbuild
rebuild src\semitwist\apps\stmanage\stbuild\main -oqobj\stbuild\release -ofbin\semitwist-stbuild -Isrc -release -C-O
move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
move semitwist-stbuild.exe ..
cd ..
