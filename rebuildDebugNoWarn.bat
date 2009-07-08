@echo off
rebuild %2src\%1\main -oqobj -ofbin\%1_debug -Isrc -debug -C-unittest
