#!/bin/sh

export DIR=$PWD

echo "  --> lua-5.3"
cd $DIR/lua-5.3.3
make linux
make install

echo "  --> luafilesystem"
cd $DIR/luafilesystem
make
make install

echo "  --> lua-perifery"
cd $DIR/lua-periphery
./bs.sh

echo "  --> gcode parser"
cd $DIR/gcode-parser
./bld.sh

echo "  --> luaSVG"
cd $DIR/luaSVG
./bld.sh

echo "  --> luaDXF"
cd $DIR/dimeDXF
./my_conf.sh
make
make install

cd $DIR/luaDXF2
./bld.sh

echo "  --> luaObjLoader"
cd $DIR/luaObjLoader
./bld.sh

echo "  --> ascii85"
cd $DIR/ascii85
./bld.sh

echo "  --> tekUI"
cd $DIR/tekUI
make all
make install

echo "  --> main src"
cd $DIR/src
./bs.sh

echo "  --> fonts"
mkdir ~/.fonts
ln -sf $DIR/bld/share/lua/5.3/tek/ui/font ~/.fonts

cd $DIR/bld

