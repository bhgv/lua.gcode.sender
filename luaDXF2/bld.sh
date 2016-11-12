#!/bin/sh

export LD_FLAGS="-fPIC -shared \
-L../bld/lib -llua \
../dimeDXF/bld/lib/libdime.a \
-Wl,-O2 -Wl,-Bsymbolic-functions \
"

#-L./bld/lib   -ldime \
#-lpthread -ldl -lutil -lm -Xlinker -export-dynamic \



g++ -fPIC  -DLUA_COMPAT_5_2 -DLUA_USE_LINUX -I. -Wall -I../dimeDXF/bld/include -I../bld/include   -g -O2 -MD -MP -c  luaDXF.cpp

g++ -g -O2 -o luaDXF2.so *.o $LD_FLAGS  

strip luaDXF2.so
cp luaDXF2.so ../bld/lib/lua/5.3
