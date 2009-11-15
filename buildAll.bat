@echo off
call bootstrap_stbuild.bat
bin\stbuild_bootstrap all all -clean
bin\stbuild_bootstrap all release
bin\stbuild_bootstrap all debug

del /Q bin\stbuild_bootstrap.exe 2> _junk_.junk
del /Q _junk_.junk
