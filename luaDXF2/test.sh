#!/bin/sh

export LD_LIBRARY_PATH=$PWD/bld/lib:$LD_LIBRARY_PATH

#alleyoop ../bld/bin/lua test.lua $1
../bld/bin/lua test.lua $1
