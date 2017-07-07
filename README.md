# lua.gcode.sender

Intro
-----
This is an attempt to build highly configurable and changeable universal g-code sender without hard to portable elements for home-made CNC and (in the future) laser & 3d printer. 
it has written using Lua & lua modules.

Lua version
------
v5.3.3 (bit operations)

Used Lua plugins
-------
- http://hg.neoscientists.org/tekui/
- https://github.com/keplerproject/luafilesystem
- https://github.com/vsergeev/lua-periphery
- https://github.com/memononen/nanosvg
- https://bitbucket.org/Coin3D/dime (DXF reader library)

Build dependencies
-------
* libreadline-dev
* libX11-dev
* libxft-dev
* libxext-dev
* libxxf86vm-dev


How to build
-------
sources of lua-5.3.3 & all modules are included. just run bld script from head folder
```sh
$ ./bld.sh 
```
current it tested on linux-arm (lubuntu, raspberry pi like board) and linux-x86 (xubuntu, ibm thinkpad x31)

How to execute
-------
```sh
$ cd bld
$ ./prg
```

How to change lua scripts
--------
all lua scripts are in the **bld/conf** folder. examples & docs to lua & modules are in their own folders.

