
extern "C" {

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
}

//#define GCODE_MODULE
//#include "GCodemodule.h"

#include "GCode_foos.h"
#include "GCode_store.h"

extern "C" {

static int
do_parse(lua_State *L)
{
    size_t len;
    const char *gcode = luaL_checklstring(L, lua_gettop(L), &len);
    luaL_argcheck(L, len <= 0x7ffffffe, lua_gettop(L), "G-code is too large");
    int out = _int_do_parse(L, gcode, (int)len);

  return out; 
}


static int
set_o_by_ln(lua_State *L){
    out_type = 0;
    
//    Py_INCREF(Py_None);
    return 0; //Py_None;
}

static int
set_o_by_cmd(lua_State *L){
    out_type = 1;
    
//    Py_INCREF(Py_None);
    return 0; //Py_None;
}

static int
set_callback_dict(lua_State *L)
{
    return _int_set_cb_dict(L);
}

static int
create_parser(lua_State *L)
{
  _int_create_parser(L);
  return 1;
}

static int
delete_parser(lua_State *L)
{
  _int_delete_parser(L);
  return 0;
}



static const struct luaL_Reg gcodeMethods[] = {
    {"set_out_type_by_line", set_o_by_ln},
    {"set_out_type_by_cmd", set_o_by_cmd},
    {"do_parse", do_parse},
    {"new_store", store_new},
    {"set_callback_dict", set_callback_dict},
    {"__gc", delete_parser},
     
    {NULL, NULL}        /* Sentinel */
};



LUALIB_API int luaopen_gcodeparser(lua_State *L)
{

register_store(L);

    /* Create gcodeparser metatable */
    luaL_newmetatable(L, "gcodeparser");
    /* Set metatable functions */
    const struct luaL_Reg *funcs = (const struct luaL_Reg *)gcodeMethods;
    for (; funcs->name != NULL; funcs++) {
        lua_pushcclosure(L, funcs->func, 0);
        lua_setfield(L, -2, funcs->name);
    }
    /* Set metatable properties */
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");

    /* Create {__call = lua_serial_new, __metatable = "protected metatable", version = ...} table */
    lua_newtable(L);
    lua_pushcclosure(L, create_parser, 0);
    lua_setfield(L, -2, "__call");
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");
    /* Set it as the metatable for the periphery.Serial metatable */
    lua_setmetatable(L, -2);

    // Parser state is created only while parsing, not when a sender task loads the module.

//    lua_pushstring(L, LUA_PERIPHERY_SERIAL_VERSION);
//    lua_setfield(L, -2, "version");

    return 1;
 }

}


