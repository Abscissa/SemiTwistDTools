@echo off
rebuild %2src\semitwist\apps\stmanage\%1\main -oqobj -ofbin\%1_debug -Isrc -debug -C-unittest
