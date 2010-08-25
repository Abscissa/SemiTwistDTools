@echo off
call scripts\bootstrap_stbuild.bat
bin\stbuild_bootstrap all all -clean
bin\stbuild_bootstrap all all -tool:rdmd

del /Q bin\stbuild_bootstrap.exe 2> _junk_.junk
del /Q _junk_.junk
