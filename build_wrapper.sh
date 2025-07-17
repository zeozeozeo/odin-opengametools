#!/bin/bash
set -e

clang++ -O3 -fPIC -Iopengametools/src -c wrapper/ogt_vox.cpp -o wrapper/ogt_vox.o
ar rcs wrapper/ogt_vox.a wrapper/ogt_vox.o

clang++ -O3 -fPIC -Iopengametools/src -c wrapper/ogt_voxel_meshify.cpp -o wrapper/ogt_voxel_meshify.o
ar rcs wrapper/ogt_voxel_meshify.a wrapper/ogt_voxel_meshify.o
