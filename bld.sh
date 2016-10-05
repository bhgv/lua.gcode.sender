#!/bin/sh

export DIR=$PWD

cd $DIR/lua-5.3.3
make linux
make install

cd $DIR/luafilesystem
make
make install

cd $DIR/lua-periphery
./bs.sh

cd $DIR/gcode-parser
./bld.sh

cd $DIR/tekUI
make all
make install

cd $DIR/src
./bs.sh

cd $DIR/bld

