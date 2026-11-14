#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p tests/build
# Build bundled Lua without the optional readline dependency.
make -C lua-5.3.3/src all SYSCFLAGS=-DLUA_USE_DLOPEN SYSLIBS='-Wl,-E -ldl'
g++ -std=c++11 -fPIC -shared -g -O1 -I bld/include \
  gcode-parser/gcodeparser.cpp gcode-parser/GCode_foos.cpp \
  gcode-parser/Parser.cpp gcode-parser/Scanner.cpp \
  -o tests/build/gcodeparser.so -pthread
gcc -I bld/include tests/states.c lua-5.3.3/src/liblua.a \
  -Wl,-E -ldl -lm -o tests/build/states
export LUA_CPATH='./tests/build/?.so'
./lua-5.3.3/src/lua tests/regression.lua
./lua-5.3.3/src/lua tests/sender.lua
./lua-5.3.3/src/lua tests/files.lua
./tests/build/states
find bld/conf -name '*.lua' -exec ./lua-5.3.3/src/luac -p '{}' \;
