
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include <stdio.h>
#include <string.h>
#include <math.h>
#define NANOSVG_ALL_COLOR_KEYWORDS	// Include full list of color keywords.
#define NANOSVG_IMPLEMENTATION		// Expands implementation
#include "nanosvg.h"



static int
do_parse(lua_State *L)
{
//    wchar_t *gcode;
    char *svg; 
    int out;
    int len;
    int i, j, k, l;

    svg = (char*)lua_tostring(L, -1);
    len = strlen(svg);
  

// Load
    NSVGshape* shape;
    NSVGpath* path;
    struct NSVGimage* image;

    //image = nsvgParseFromFile("nano.svg", "px", 96);
    image = nsvgParse(svg, "px", 96);
//    printf("size: %f x %f\n", image->width, image->height);
    // Use...

    lua_newtable(L);

    lua_pushnumber(L, image->width);
    lua_setfield(L, -2, "W");

    lua_pushnumber(L, image->height);
    lua_setfield(L, -2, "H");

    j = 1;
    for (shape = image->shapes, k = 1; shape != NULL; shape = shape->next, k++) {
        //----
        lua_newtable(L);
        lua_pushstring(L, "shape");
        lua_setfield(L, -2, "type");
        for (path = shape->paths, l = 1; path != NULL; path = path->next, l++) {
            lua_newtable(L);
            lua_pushstring(L, "path");
            lua_setfield(L, -2, "type");
            for (i = 0, j = 1; i < path->npts-1; i += 3, j++) {
                float* p = &path->pts[i*2];
/*
printf("\n--------\n%d\n--\n", j);
                //drawCubicBez(p[0],p[1], p[2],p[3], p[4],p[5], p[6],p[7]);
                printf("p1(%f, %f)-p2(%f, %f)-p3(%f, %f)-p4(%f, %f)\n",
		    p[0],p[1], 
		    p[2],p[3], 
		    p[4],p[5], 
		    p[6],p[7]
                );
*/
                //----
                lua_newtable(L);
                lua_pushstring(L, "curve");
                lua_setfield(L, -2, "type");
                //----
                lua_newtable(L);
                lua_pushnumber(L, p[0]);
                lua_setfield(L, -2, "x");
                lua_pushnumber(L, p[1]);
                lua_setfield(L, -2, "y");

                lua_setfield(L, -2, "p1");
                //----
                lua_newtable(L);
                lua_pushnumber(L, p[2]);
                lua_setfield(L, -2, "x");
                lua_pushnumber(L, p[3]);
                lua_setfield(L, -2, "y");

                lua_setfield(L, -2, "p2");
                //----
                lua_newtable(L);
                lua_pushnumber(L, p[4]);
                lua_setfield(L, -2, "x");
                lua_pushnumber(L, p[5]);
                lua_setfield(L, -2, "y");

                lua_setfield(L, -2, "p3");
                //----
                lua_newtable(L);
                lua_pushnumber(L, p[6]);
                lua_setfield(L, -2, "x");
                lua_pushnumber(L, p[7]);
                lua_setfield(L, -2, "y");

                lua_setfield(L, -2, "p4");
                //----
                lua_rawseti(L, -2, j);

                //j++;
            }
            lua_rawseti(L, -2, l);
        }
        lua_rawseti(L, -2, k);
    }
    // Delete
    nsvgDelete(image);
    
    return 1;
}

/*
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
*/


static const struct luaL_Reg luaSVG_Methods[] = {
    {"do_parse", do_parse},
//    {"set_callback_dict", set_callback_dict},
//    {"__gc", delete_parser},
     
    {NULL, NULL}        /* Sentinel */
};



LUALIB_API int luaopen_luaSVG(lua_State *L)
{

    printf("luaSVG\n");

    /* Create gcodeparser metatable */
    luaL_newmetatable(L, "luaSVG");
    /* Set metatable functions */
    const struct luaL_Reg *funcs = (const struct luaL_Reg *)luaSVG_Methods;
    for (; funcs->name != NULL; funcs++) {
        lua_pushcclosure(L, funcs->func, 0);
        lua_setfield(L, -2, funcs->name);
    }
    /* Set metatable properties */
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");

    /* Create {__call = lua_serial_new, __metatable = "protected metatable", version = ...} table */
    lua_newtable(L);
    lua_pushcclosure(L, do_parse, 0); //create_parser, 0);
    lua_setfield(L, -2, "__call");
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");
    /* Set it as the metatable for the periphery.Serial metatable */
    lua_setmetatable(L, -2);

//    lua_pushstring(L, LUA_PERIPHERY_SERIAL_VERSION);
//    lua_setfield(L, -2, "version");

    return 1;
 }


