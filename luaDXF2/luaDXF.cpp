
extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <stdlib.h>
#include <string.h>


#include <string.h>
#include <math.h>
}

#include <dime/Input.h>
#include <dime/Output.h>
#include <dime/Model.h>
#include <dime/State.h>
#include <stdio.h>
#include <dime/convert/convert.h>
#include <dime/convert/layerdata.h>


#define lua_rawseti lua_seti

void pt2lua(lua_State *L, double x, double y, double z){
                lua_newtable(L);
                
                lua_pushnumber(L, x);
                lua_setfield(L, -2, "x");
                
                lua_pushnumber(L, y);
                lua_setfield(L, -2, "y");
                
                lua_pushnumber(L, z);
                lua_setfield(L, -2, "z");
}

void type2lua(lua_State *L, const char* t){
                lua_pushstring(L, t);
                lua_setfield(L, -2, "type");
}



void
my_dx2lua(lua_State *L, dxfLayerData *self, int indent)
{  
  lua_newtable(L);
  type2lua(L, "layer");

  if (!self->faceindices.count() && !self->lineindices.count() && !self->points.count()) return;

  int i, n;

  dxfdouble r,g,b;
  
  dimeLayer::colorToRGB(self->colidx, r, g, b);

  if (self->faceindices.count()) {
    dimeVec3f v;
/*
    n = self->facebsp.numPoints();
    for (i = 0; i < n ; i++) {
      self->facebsp.getPoint(i, v);
      //if (only2d) v[2] = 0.0f;
      fprintf(fp, "            %.8g %.8g %.8g,\n", v[0], v[1], v[2]);
    }
*/

    lua_newtable(L);
    type2lua(L, "faces");
    
    n = self->faceindices.count();
    int cnt = 1;
    int ind = -1;
    int j;
    for (i = 0; i < n; i++) {
      if(ind == -1){
          j = 1;
          lua_newtable(L);
          type2lua(L, "face");
      }
      ind = self->faceindices[i];
      if(ind == -1){
          lua_rawseti(L, -2, cnt);
          cnt++;
      }else{
          self->facebsp.getPoint(ind, v);
          pt2lua(L, v[0], v[1], v[2]);
          lua_rawseti(L, -2, j);
          j++;
      }
    }
    lua_setfield(L, -2, "faces");
      
//      fprintf(fp, "%d,", self->faceindices[i]);
  }

  if (self->lineindices.count()) {
    // make sure line indices has a -1 at the end
    if (self->lineindices[self->lineindices.count()-1] != -1) {
      self->lineindices.append(-1);
    }

    dimeVec3f v;
    
    lua_newtable(L);
    type2lua(L, "lines");

    n = self->lineindices.count();
    int cnt = 1;
    int ind = -1;
    int j;
    for (i = 0; i < n; i++) {
      if(ind == -1){
        j = 1;
        lua_newtable(L);
        type2lua(L, "line");
      }
      ind = self->lineindices[i];
      if(ind == -1){
          lua_rawseti(L, -2, cnt);
          cnt++;
      }else{
          self->linebsp.getPoint(ind, v);
          pt2lua(L, v[0], v[1], v[2]);
          lua_rawseti(L, -2, j);
          j++;
      }
    }
    lua_setfield(L, -2, "lines");
    
    lua_rawseti(L, -2, indent);
  }

/*
  if (self->points.count() && 0) { // FIXME disabled, suspect bug. pederb, 2001-12-11 

    dimeVec3f v;
    n = self->points.count();
    for (i = 0; i < n ; i++) {
      v = self->points[i];
      //if (only2d) v[2] = 0.0f;
      fprintf(fp, "            %g %g %g,\n", v[0], v[1], v[2]);
    }
  }
*/
}




extern "C" {
    LUALIB_API int luaopen_luaDXF2(lua_State *L);
    static int do_parse_dxf(lua_State *L);
}

static int 
do_parse_dxf(lua_State *L)
{
    char *infile; 
    //int len;

    infile = (char*)lua_tostring(L, -1);
    //len = strlen(infile);
    
    dimeInput in;

  // open file for reading (or use stdin) 
  if (!in.setFile(infile)) {
    fprintf(stderr,"Error opening file for reading: %s\n", infile);
    return 0;
  }  
  
  // try reading the file
  dimeModel model;

  if (!model.read(&in)) {
    fprintf(stderr,"DXF read error in line: %d\n", in.getFilePosition());
    return 0;
  }

  int fillmode = 0;
  int layercol = 0;

  float maxerr = 0.1f;
  int sub = -1;  
  //int i = 1;

  dxfConverter converter;
  converter.findHeaderVariables(model);
  converter.setMaxerr(maxerr);
  if (sub > 0) converter.setNumSub(sub);

  if (fillmode == 0) converter.setFillmode(true);

  if (layercol) converter.setLayercol(true);
    
  if (!converter.doConvert(model)) {
    fprintf(stderr,"Error during conversion\n");
    return 0;
  }

  // try preparing 2 lua
  lua_newtable(L);
  type2lua(L, "top");

  lua_pushstring(L, infile);
  lua_setfield(L, -2, "file_name");

  dxfLayerData **layerData = converter.getLayerData();
  // write each used layer/color
  for (int i = 0, j = 1; i < 255; i++) {
    if (layerData[i] != NULL) {
      my_dx2lua(L, layerData[i], j);
      j++;
      delete layerData[i]; layerData[i] = NULL;
    }
  }
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


static const struct luaL_Reg luaDXF_Methods[] = {
    {"do_parse", do_parse_dxf},
//    {"__gc", delete_parser},
     
    {NULL, NULL}        /* Sentinel */
};



LUALIB_API int luaopen_luaDXF2(lua_State *L){
    printf("luaDXF2\n");

    /* Create gcodeparser metatable */
    luaL_newmetatable(L, "luaDXF");
    /* Set metatable functions */
    const struct luaL_Reg *funcs = (const struct luaL_Reg *)luaDXF_Methods;
    for (; funcs->name != NULL; funcs++) {
        lua_pushcclosure(L, funcs->func, 0);
        lua_setfield(L, -2, funcs->name);
    }

    /* Set metatable properties */
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");

    /* Create {__call = lua_serial_new, __metatable = "protected metatable", version = ...} table */
    lua_newtable(L);
    lua_pushcclosure(L, do_parse_dxf, 0); 
    lua_setfield(L, -2, "__call");
    lua_pushstring(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");
    /* Set it as the metatable for the periphery.Serial metatable */
    lua_setmetatable(L, -2);

//    lua_pushstring(L, LUA_PERIPHERY_SERIAL_VERSION);
//    lua_setfield(L, -2, "version");

    return 1;
 }


