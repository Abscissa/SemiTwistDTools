@echo off
rebuild %2src\%1\main -oqobj -ofbin\%1_debug -Isrc -I..\semitwistlib\src -debug -debug=UnitTest -C-unittest -C-w
