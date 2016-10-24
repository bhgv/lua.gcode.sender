
extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#include <wchar.h>

#include <stdio.h>

#include "Scanner.h"
#include "Parser.h"

#include "uthash/include/uthash.h"

#include "GCode_foos.h"



typedef struct {
    int id;                    /* key */
    wchar* param;
    UT_hash_handle hh;         /* makes this structure hashable */
} param_hash_item;

param_hash_item *params_ht = NULL;    /* important! initialize to NULL */

typedef int(*LuaFoo)(lua_State *L);

static struct {
    LuaFoo *cmd, *eol, *init, *fini, *pragma, *def, *set_param, *get_param, *aux_cmd, *no_callback, *self, *O;
} py_callbacks;

const char* cb_types_strings[] = {
//    (const char*)NULL,
    /*Parser::CMD         =*/ "cmd",
    /*Parser::EOL         =*/ "eol",
    /*Parser::INIT        =*/ "init",
    /*Parser::FINI        =*/ "fini",
    /*Parser::PRAGMA      =*/ "pragma",
    /*Parser::AUX_CMD     =*/ "aux_cmd",
    /*Parser::DEFAULT     =*/ "default",
    /*Parser::NO_CMD_CB   =*/ "no_callback",
    (const char*)NULL
};


wchar* _int_cb_call(LuaFoo *foo, Parser::Cb_Type key, wchar *param1, wchar *param2, int line);


Parser* gparser = NULL;

wchar** result = NULL;
wchar** res_p = NULL;
wchar* res_b = NULL; 
int cur_line = 1;

int res_len = 0;
int res_len_max = 0;


int out_type = 0;


lua_State *gL = NULL;

/*
 int callExecFunction(const char* evalStr)
{
    PyCodeObject* code = (PyCodeObject*)Py_CompileString(evalStr, "pyscript", Py_eval_input);
    PyObject* global_dict = PyModule_GetDict(pModule);
    PyObject* local_dict = PyDict_New();
    PyObject* obj = PyEval_EvalCode(code, global_dict, local_dict);

    PyObject* result = PyObject_Str(obj);
    PyObject_Print(result, stdout, 0);
}
*/


/*
void eval(wchar_t* wcs){
    char* s = coco_string_create_char(wcs);
    
    printf("aux -> %ls\n%s\n", wcs, &s[1]);
    
    PyCodeObject* code = (PyCodeObject*) Py_CompileString(s, "aux", Py_eval_input);
    PyObject* main_module = PyImport_AddModule("__main__");
    PyObject* global_dict = PyModule_GetDict(main_module);
    PyObject* local_dict = PyDict_New();
//    PyObject* obj = PyEval_EvalCode(code, global_dict, local_dict);
    PyObject* obj = PyEval_EvalCode(code, local_dict, local_dict);

//    PyObject* result = PyObject_Str(obj);
//    PyObject_Print(result, stdout, 0);
}
*/


  
  void Parser::set_param(wchar* key, wchar* param){
    param_hash_item *s = NULL, *so;
    
    s = new param_hash_item();
    s->id = coco_string_hash(key);
    s->param = param;
    
    coco_string_delete(key);
    
    HASH_ADD_INT( params_ht, id, s );  /* id: name of key field */
  }
  
  
  wchar* Parser::get_param(wchar* key){
    param_hash_item *s = NULL;
    wchar* out;
    int id = coco_string_hash(key);
    
    HASH_FIND_INT( params_ht, &id, s );  /* id: name of key field */
    
    if(s == NULL) 
        out = coco_string_create(L"");
    else 
        out = coco_string_create(s->param);
    
    return out;
  }
  
  

static wchar* _int_scpy(wchar* s){
      int len;
      if(s == NULL) return 0;
      
      len = wcslen(s);
      if(len == 0) return 0;
      
/**
      if(res_len + len + 1 >= res_len_max){
          char* res_o = result;
          result = new char[res_len_max + RES_STR_MEM_STEP];
          res_len_max += RES_STR_MEM_STEP;
          
          if(res_len > 0){
              ncpy(result, res_o, res_len);
          }

          res_p = result + res_len;
          delete[] res_o;
      }
/**/
      wcscat(res_b, s);
      return res_b;
  }
  
  void _int_out_tuple_append_last(int line){
    *res_p = res_b;

    //printf("tu-a-lst => (%d -> %d) %ls, ... => %ls\n", cur_line, line, res_b, *res_p);
    for(; cur_line < line; cur_line++){
    	res_p++; *res_p = (wchar*)0;
    	res_len++;
    }
    res_b = new wchar[256];
    res_b[0] = 0;
  }
  
  void Parser::call(int line, Cb_Type key, wchar* param1, wchar* param2){
//      printf("k=%s, p1=%ls, p2=%ls\n", cb_types_strings[key], param1, param2);
      line--;

      switch(key){
          case Parser::CMD:
            _int_cb_call(py_callbacks.cmd, Parser::CMD, param1, param2, line);
            if(out_type == 0)
                _int_scpy(L" ");
            _int_scpy(param1);
            if(param2 != NULL){ 
                _int_scpy(param2);
            }
            if(out_type != 0)
                _int_out_tuple_append_last(line);
            break;

          case Parser::EOL:
                _int_cb_call(py_callbacks.eol, Parser::EOL, 0, 0, line);
                _int_out_tuple_append_last(line);
            break;
            
          case Parser::AUX_CMD:
            _int_cb_call(py_callbacks.cmd, Parser::AUX_CMD, param1, param2, line);
            break;
            
          case Parser::INIT:
            _int_cb_call(py_callbacks.cmd, Parser::INIT, 0, 0, line);
            break;
            
          case Parser::FINI:
            _int_cb_call(py_callbacks.cmd, Parser::FINI, 0, 0, line);
            break;
            
/*            
          case Parser::CMD:
            break;
*/            
 //         default:
 //           return;
      }
      
      if(param1) coco_string_delete(param1);
      if(param2) coco_string_delete(param2);
  }
/*
   def call(self, key, param=None):
      if self._int_is_callback_defined(key):
         out = self._int_call(key, param)
         if out:
            self.gcode_out_last += str(out)
      elif self._int_is_callback_defined("default"):
         out = self._int_call("default", key, param)
         if out:
            self.gcode_out_last += str(out)
      elif self._int_is_callback_defined("no_callback"):
         self._int_call("no_callback", key, param, self.getParsingPos())
      else:
         if key == "eol":
            if self.out_type == 0:
               if len(self.gcode_out_last) > 0:
                  self.gcode_out.append(self.gcode_out_last)
                  self.gcode_out_last = ""
            else:
               if len(self.gcode_out_array_last) > 0:
                  self.gcode_out.append(self.gcode_out_array_last)
                  self.gcode_out_array_last = []
                  
         elif key and key not in self.callback_names:
            if self.out_type == 0:
               self.gcode_out_last += " " + key
               if param:
                  self.gcode_out_last += param
            else:
               line = key
               if param:
                  line += param
               self.gcode_out_array_last.append(line)
               
         elif key == "aux_cmd" and param:
            pat = self.other_param.match(param)
            if pat:
               var_name = pat.group(1)
               var_val_raw = pat.group(2)
               var_val = eval(var_val_raw)
               self.gcode_params[var_name] = str(var_val)
*/


wchar*
_int_cb_call(LuaFoo *foo, Parser::Cb_Type key, wchar *param1, wchar *param2, int line){
    char str[256];
    wchar* result;
    int l;

    if(key < 1 || key >= Parser::CB_LAST) return NULL;
    
        luaL_getmetatable(gL, "gcodeparser");
        lua_getfield(gL, -1, cb_types_strings[key-1]);
        lua_remove(gL, -2);
        if(lua_isnil(gL, -1)){
          lua_remove(gL, -1);
          return NULL;
        }

	lua_pushinteger(gL, line);
        lua_pushstring(gL, cb_types_strings[key-1]);

	switch(key){
		case Parser::EOL:
                        l = wcslen(res_b);
                        wcstombs(str, res_b, l);
                        str[l] = 0;
                        lua_pushstring(gL, str);

                        lua_call(gL, 3, 1); //, 0);
			break;
			
		default:
                        if(param1 == 0)
                          lua_pushnil(gL);
                        else{
                          l = wcslen(param1);
                          wcstombs(str, param1, l);
                          str[l] = 0;
                          lua_pushstring(gL, str);
                        }
                        if(param2 == 0)
                          lua_pushnil(gL);
                        else{
                          l = wcslen(param2);
                          wcstombs(str, param2, l);
                          str[l] = 0;
                          lua_pushstring(gL, str);
                        }
                        lua_call(gL, 4, 1); //, 0);
			break;
	}
    if(lua_isnil(gL, -1)) result = NULL;
    else{
      result = NULL;
    }
    return result;
}



int
_int_set_cb_dict(lua_State *L){
     const char** p;

    if (lua_istable(L, -1)){
       luaL_getmetatable(L, "gcodeparser");

       for(p = cb_types_strings; *p != NULL; p++){
         lua_getfield(L, -2, *p);
         lua_setfield(L, -2, *p);
       }
     }
    
 //   _int_set_cb_dict_aux(dict, "cmd", &py_callbacks.cmd, true);
 //   _int_set_cb_dict_aux(dict, "init", &py_callbacks.init, true);
 //   _int_set_cb_dict_aux(dict, "fini", &py_callbacks.fini, true);
 //   _int_set_cb_dict_aux(dict, "eol", &py_callbacks.eol, true);
 //   _int_set_cb_dict_aux(dict, "pragma", &py_callbacks.pragma, true);
 //   _int_set_cb_dict_aux(dict, "default", &py_callbacks.def, true);
 //   _int_set_cb_dict_aux(dict, "set_param", &py_callbacks.set_param, true);
 //   _int_set_cb_dict_aux(dict, "get_param", &py_callbacks.get_param, true);
 //   _int_set_cb_dict_aux(dict, "aux_cmd", &py_callbacks.aux_cmd, true);
 //   _int_set_cb_dict_aux(dict, "no_callback", &py_callbacks.no_callback, true);
 //   _int_set_cb_dict_aux(dict, "self", &py_callbacks.self, false);
    
   return 0; //Py_None;
}



int 
_int_create_parser(lua_State *L){
    gparser = new Parser(NULL);
    
    py_callbacks.O = 
    py_callbacks.eol = 
    py_callbacks.init = 
    py_callbacks.fini = 
    py_callbacks.pragma = 
    py_callbacks.def = 
    py_callbacks.set_param = 
    py_callbacks.get_param = 
    py_callbacks.aux_cmd = 
    py_callbacks.no_callback = NULL;
    
    res_len = 0;
    res_len_max = RES_STR_MEM_STEP; 
    result = new wchar*[80000]; //res_len_max + 1];
    result[0] = 0;
    res_p = result;

    res_b = new wchar[256];
    res_b[0] = 0;

    cur_line = 0;

    gL = L;

    return 1;
}

int 
_int_delete_parser(lua_State *L){
    if(gparser != NULL){
      if(gparser->scanner != NULL) delete gparser->scanner;
      delete gparser;
      gparser = NULL;
    }
    
    py_callbacks.O = 
    py_callbacks.eol = 
    py_callbacks.init = 
    py_callbacks.fini = 
    py_callbacks.pragma = 
    py_callbacks.def = 
    py_callbacks.set_param = 
    py_callbacks.get_param = 
    py_callbacks.aux_cmd = 
    py_callbacks.no_callback = NULL;
    
    res_len_max = RES_STR_MEM_STEP; 
    for(res_p = result; /* *res_p != 0*/ res_len > 0; res_p++, res_len--) 
	if(*res_p != 0) 
		delete[] ((wchar*)*res_p);
    delete[] result;
    res_p = result = NULL;

    res_len = 0;

    if(res_b != NULL){ delete[] res_b; res_b = NULL;}

  return 0;
}


int 
_int_do_parse(char* gcode, int len){
    wchar** rp;
    int i;
    Scanner* sc, *sc_o;
    
    if(gparser == NULL || gcode == NULL) 
        return 0;

    sc_o = gparser->scanner;
    sc = new Scanner((const unsigned char*)gcode, len);
    gparser->scanner = sc;

    if(sc_o) delete sc_o;

    res_len = 0;
 
    gparser->Parse();

    lua_settop(gL, 0);

    lua_createtable(gL, res_len, 0);
    for(i = 1, rp = result; i <= res_len /*&& rp < res_p*/ /*&& *rp != 0*/; rp++, i++){
      char ts[256];
      char *s;
      int l;
      if(*rp != 0){
      	l = wcslen(*rp);
      	wcstombs(ts, *rp, l);
      	ts[l] = 0;
      }else{
        ts[0] = 0;
      }
//      printf("do_parse => %d) %ls ... %s\n", i, *rp, ts);
//      lua_pushinteger(gL, i);
      s = (char*)lua_pushstring(gL, ts);
//      printf("+do_parse => %d) %s\n", i, s);
//      lua_settable(gL, -3); //, i);
      lua_seti(gL, -2, i);
    }
    
    _int_delete_parser(gL);
    _int_create_parser(gL);

    return 1;
}

