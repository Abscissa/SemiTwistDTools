@echo off
echo Bootstrapping STBuild...

move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
del /Q obj\*.*

xfbuild src\semitwist\apps\stmanage\stbuild\main.d +obin\stbuild_bootstrap +Oobj +Dobj\stbuild_bootstrap.deps +rmo -Isrc -release -O

move *.map obj > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
del /Q obj\*.*
