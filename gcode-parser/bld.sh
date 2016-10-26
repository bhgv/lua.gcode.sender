#!/bin/sh


export DBG="-g"
#export DBG=""

export C_FLAGS="-c -fPIC \
-I../bld/include -O2 \
"
export LD_FLAGS="-fPIC -shared \
-L../bld/lib -llua \
-lpthread -ldl -lutil -lm -Xlinker -export-dynamic \
-Wl,-O3 -Wl,-Bsymbolic-functions \
"

#tools/coco_cpp/Coco -frames $PWD/tools/coco_cpp GCode.atg

g++ $C_FLAGS $DBG \
-o gcodeparser.o gcodeparser.cpp 

g++ $C_FLAGS $DBG \
-o Parser.o Parser.cpp

g++ $C_FLAGS $DBG \
-o Scanner.o Scanner.cpp

g++ $C_FLAGS $DBG \
-o GCode_foos.o GCode_foos.cpp

g++ $LD_FLAGS $DBG \
-o gcodeparser.so gcodeparser.o Parser.o Scanner.o GCode_foos.o 

cp gcodeparser.so ../bld/lib/lua/5.3

#-march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -marm \
