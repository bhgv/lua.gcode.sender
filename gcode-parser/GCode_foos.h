
#ifndef _GCODE_FOOS_
#define _GCODE_FOOS_

#define RES_STR_MEM_STEP 0x100
//#define RES_STR_TUPLE_STEP 0x1000

extern "C" {

typedef wchar_t wchar;

int 
_int_create_parser(lua_State *L);

int 
_int_delete_parser(lua_State *L);

int //PyObject* //const wchar_t* 
_int_do_parse(lua_State *L, const char* gcode, int len);

int //PyObject *
_int_set_cb_dict(lua_State *L);

}

extern int out_type;

extern lua_State *gL;

#endif
