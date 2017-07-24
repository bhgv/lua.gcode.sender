#!/bin/sh

./configure \
  --enable-lua \
  --with-lua-inc=$PWD/../bld/include \
  --with-lua-lib=$PWD/../bld/lib \
  --includedir=$PWD/../bld/include \
  --libdir=$PWD/../bld/lib/lua/5.3/rs232 \


make install
