#!/usr/bin/env bash
set -euo pipefail

#printInfo=-d-version=PrintInfo
printInfo=

clang++ -g -O3 -march=native -c cppsort.cpp -o cppsort.o -fpie -I/opt/homebrew/include/
ldc2 -g -O5 -release -boundscheck=off -mcpu=native $printInfo fastsort.d phobossort.d cppsort.o -L-lstdc++ -march=aarch64 
