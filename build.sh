#!/usr/bin/env bash
set -euo pipefail

#printInfo=-d-version=PrintInfo
printInfo=

clang++ -O3 -march=native -c cppsort.cpp -o cppsort.o
ldc2 -O5 -release -boundscheck=off -mcpu=native $printInfo -flto=full fastsort.d phobossort.d cppsort.o
