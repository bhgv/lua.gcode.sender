#!/bin/sh

export LD_FLAGS="-fPIC -shared \
-L../bld/lib -llua \
-Wl,-O2 -Wl,-Bsymbolic-functions \
"

#-lpthread -ldl -lutil -lm -Xlinker -export-dynamic \


gcc -fPIC  -DLUA_COMPAT_5_2 -DLUA_USE_LINUX -I. -Wall -I../bld/include -g -O2 -MD -MP -c  luaObj.c

gcc -g -O2 -o luaObj.so luaObj.o $LD_FLAGS  

strip luaObj.so
cp luaObj.so ../bld/lib/lua/5.3
