#!/usr/bin/env bash
set -euo pipefail

g++ -O3 -march=native -c cppsort.cpp -o cppsort.o && ldc2 -O5 -release -boundscheck=off -mcpu=native -d-version=calloc -flto=full fastsort.d cppsort.o && ./fastsort 1000000
