# odin-opengametools

Odin bindings for [open game tools](https://github.com/jpaver/opengametools), a set of unencumbered, free, lightweight, easy-to-integrate tools for use in game development.

Contains bindings for the following libraries:

- [ogt_vox](https://github.com/jpaver/opengametools/blob/master/src/ogt_vox.h) a MagicaVoxel scene reader, writer and merger
- [ogt_voxel_meshify](https://github.com/jpaver/opengametools/blob/master/src/ogt_voxel_meshify.h) a few routines to convert voxel grid data to triangle mesh

# ogt_vox: MagicaVoxel scene reader, writer and merger

Please refer to the [readme of open game tools](https://github.com/jpaver/opengametools?tab=readme-ov-file#ogt_vox-magicavoxel-scene-reader-writer-and-merger).

## Usage

See [demo_vox.odin](/examples/demo_vox.odin) for a simple example.

# ogt_voxel_meshify: converts voxel grid data to triangle mesh data

Please refer to the [readme of open game tools](https://github.com/jpaver/opengametools?tab=readme-ov-file#ogt_voxel_meshify-converts-voxel-grid-data-to-triangle-mesh-data).

# Building

Build the .lib and .a files required for these bindings.

### Windows

> ![NOTE]
> This library already provides prebuilt libraries for x86_64 Windows, so you most likely don't need to do any of this.

```batch
git clone https://github.com/zeozeozeo/odin-opengametools.git
cd odin-opengametools
git submodule update --init --recursive
build_wrapper.bat
```

### Linux, MacOS, BSD, ...

```bash
git clone https://github.com/zeozeozeo/odin-opengametools.git
cd odin-opengametools
git submodule update --init --recursive
./build_wrapper.sh
```

The built files should be located under the [wrapper](/wrapper/) directory.

# License

open game tools is distributed under the terms of the MIT license: https://github.com/jpaver/opengametools/blob/master/LICENSE.md

odin-opengametools (these bindings and examples) are distributed under the terms of The Unlicense:

```
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
```
