@echo off
rebuild %2src\%1\main -oqobj -ofbin\%1_release -Isrc -I..\semitwistlib\src -release -C-w
