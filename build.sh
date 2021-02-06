#!/usr/bin/env bash
set -euo pipefail

#printInfo=-d-version=PrintInfo
printInfo=

clang++ -O3 -march=native -c cppsort.cpp -o cppsort.o -fpie -flto=thin --target=x86_64-pc-linux-gnu
ldc2 -O5 -release -boundscheck=off -mcpu=native -mtriple=x86_64-pc-linux-gnu $printInfo -flto=thin fastsort.d phobossort.d cppsort.o -L-lstdc++
