#!/bin/bash
set -e

clang++ -O3 -fPIC -Iopengametools/src -c wrapper/ogt_vox.cpp -o wrapper/ogt_vox.o
ar rcs wrapper/ogt_vox.a wrapper/ogt_vox.o
