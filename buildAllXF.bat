@echo off
call scripts\bootstrap_stbuild_xf.bat
bin\stbuild_bootstrap all all -clean
bin\stbuild_bootstrap all all -tool:xf

del /Q bin\stbuild_bootstrap.exe 2> _junk_.junk
del /Q _junk_.junk
