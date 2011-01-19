@echo off
call scripts\bootstrap_stbuild.bat
bin\semitwist-stbuild-bootstrap all all -clean
bin\semitwist-stbuild-bootstrap all all -tool:rdmd

del /Q bin\semitwist-stbuild-bootstrap.exe 2> _junk_.junk
del /Q _junk_.junk
