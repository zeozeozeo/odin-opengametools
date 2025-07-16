@echo off
clang-cl -c /O2 -Iopengametools/src wrapper/ogt_vox.cpp -Fo:wrapper/ogt_vox.obj
lib /nologo wrapper/ogt_vox.obj /out:wrapper/ogt_vox.lib

rem dump symbols
dumpbin /symbols wrapper/ogt_vox.lib | findstr ogt_vox
