#!/bin/sh


export DBG="-g"
#export DBG=""

export C_FLAGS="-c -fPIC \
-I../bld/include -O2 \
"
#-march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -marm \
#-fstack-protector-strong \

export LD_FLAGS="-fPIC -shared \
-L../bld/lib -llua \
-lpthread -ldl -lutil -lm -Xlinker -export-dynamic \
-Wl,-O3 -Wl,-Bsymbolic-functions \
"

gcc $C_FLAGS $DBG \
-o luaSVG.o luaSVG.c 

#g++ $C_FLAGS $DBG \

gcc $LD_FLAGS $DBG \
-o luaSVG.so luaSVG.o 

strip luaSVG.so
cp luaSVG.so ../bld/lib/lua/5.3

#-march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -marm \
