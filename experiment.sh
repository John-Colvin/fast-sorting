#!/usr/bin/env bash
set -euo pipefail

#printInfo=-d-version=PrintInfo
printInfo=

clang++ -O3 -march=native -c cppsort.cpp -o cppsort.o
ldc2 -O5 -release -boundscheck=off -mcpu=native -d-version=$1 $printInfo -flto=full fastsort.d cppsort.o
#/usr/bin/time -v ./fastsort $2
./fastsort $2
