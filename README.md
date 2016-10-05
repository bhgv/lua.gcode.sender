# lua.gcode.sender

Intro
-----
This is an attempt to build universal g-code sender for home-made CNC and (in the future) laser & 3d printer using Lua & lua modules. as it faster than java or python (bCNC - maybe the best g-code sender) and more configurable then C/C++ based ones.

Lua version
------
v5.3.3 (bit operations)

Used Lua plugins
-------
- http://hg.neoscientists.org/tekui/
- https://github.com/keplerproject/luafilesystem
- https://github.com/vsergeev/lua-periphery

How to build
-------
sources of lua-5.3.3 & all modules are included. just run bld script from head folder
```sh
$ ./bld.sh 
```
current it tested only on linux-arm (raspberry pi like board)

How to execute
-------
```sh
$ cd bld
$ ./prg
```

How to change lua scripts
--------
all lua scripts are in the **bld/conf** folder. examples & docs to lua & modules are in their own folders.

