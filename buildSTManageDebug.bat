@echo off
rebuild %2src\stmanage\%1\main -oqobj\debug -ofbin\%1_debug -Isrc -debug -C-unittest -C-w
move *.map obj\debug > _junk_.junk 2> _junk_.junk2
del /Q _junk_.junk
del /Q _junk_.junk2
