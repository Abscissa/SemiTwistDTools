@echo off
call scripts\bootstrap_stbuild.bat
bin\semitwist-stbuild-bootstrap all %1 --clean
bin\semitwist-stbuild-bootstrap all %1 --tool=rdmd --x=--force

del /Q bin\semitwist-stbuild-bootstrap.exe 2> _junk_.junk
del /Q _junk_.junk
