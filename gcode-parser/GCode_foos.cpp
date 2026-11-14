extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#include <map>
#include <mutex>
#include <string>
#include <wchar.h>

#include "Scanner.h"
#include "Parser.h"
#include "GCode_foos.h"
#include "GCode_store.h"

static std::map<std::wstring, std::wstring> params;
static std::wstring res_b;
static std::vector<std::string> result_lines;
static std::mutex parse_mutex;
static int callback_error = LUA_NOREF;
static Parser *gparser = NULL;
int out_type = 0;
lua_State *gL = NULL;

static const char *cb_types_strings[] = {
    "cmd", "eol", "init", "fini", "pragma", "aux_cmd", "default", "no_callback", NULL
};

static std::string narrow(const wchar *s) {
    // Scanner tokens are ASCII G-code. Keep dynamically sized buffers.
    std::string text;
    if(s) while(*s) text += (char)*s++;
    return text;
}

void Parser::set_param(wchar *key, wchar *param) {
    params[key] = param ? param : L"";
    coco_string_delete(key);
    coco_string_delete(param);
}

wchar *Parser::get_param(wchar *key) {
    std::map<std::wstring, std::wstring>::iterator it = params.find(key);
    return coco_string_create(it == params.end() ? L"" : it->second.c_str());
}

void Parser::call(int line, Cb_Type key, wchar *param1, wchar *param2) {
    line--;
    if(callback_error == LUA_NOREF && key >= CMD && key < CB_LAST) {
        luaL_getmetatable(gL, "gcodeparser");
        lua_getfield(gL, -1, cb_types_strings[key - 1]);
        lua_remove(gL, -2);
        if(lua_isfunction(gL, -1)) {
            lua_pushinteger(gL, line);
            lua_pushstring(gL, cb_types_strings[key - 1]);
            if(key == EOL) {
                std::string text = narrow(res_b.c_str());
                lua_pushlstring(gL, text.data(), text.size());
            } else {
                if(param1) lua_pushstring(gL, narrow(param1).c_str());
                else lua_pushnil(gL);
                if(param2) lua_pushstring(gL, narrow(param2).c_str());
                else lua_pushnil(gL);
            }
            if(lua_pcall(gL, key == EOL ? 3 : 4, 0, 0) != LUA_OK)
                callback_error = luaL_ref(gL, LUA_REGISTRYINDEX);
        } else lua_pop(gL, 1);
    }

    if(key == CMD) {
        if(out_type == 0) res_b += L" ";
        if(param1) res_b += param1;
        if(param2) res_b += param2;
        if(out_type != 0) {
            result_lines.push_back(narrow(res_b.c_str()));
            res_b.clear();
        }
    } else if(key == EOL) {
        if(out_type == 0 && line > 0) {
            result_lines.resize(line);
            result_lines[line - 1] = narrow(res_b.c_str());
        }
        res_b.clear();
    }
    if(param1) coco_string_delete(param1);
    if(param2) coco_string_delete(param2);
}

int _int_set_cb_dict(lua_State *L) {
    luaL_checktype(L, lua_gettop(L), LUA_TTABLE);
    luaL_getmetatable(L, "gcodeparser");
    for(const char **p = cb_types_strings; *p; p++) {
        lua_getfield(L, -2, *p);
        lua_setfield(L, -2, *p);
    }
    lua_pop(L, 1);
    return 0;
}

int _int_create_parser(lua_State *L) {
    return 0;
}

int _int_delete_parser(lua_State *L) {
    return 0;
}

int _int_do_parse(lua_State *L, const char *gcode, int len) {
    if(!parse_mutex.try_lock()) return luaL_error(L, "parser is already running");
    gL = L;
    int errors, error_ref;
    {
        res_b.clear();
        result_lines.clear();
        params.clear();
        callback_error = LUA_NOREF;
        // The grammar expects a final EOL even for an unterminated input file.
        std::string text(gcode, len);
        if(!text.empty() && text[text.size() - 1] != '\n') text += '\n';
        Scanner *scanner = new Scanner((const unsigned char*)text.data(), text.size());
        gparser = new Parser(scanner);
        gparser->Parse();
        errors = gparser->errors->count;
        delete gparser;
        delete scanner;
        gparser = NULL;
        params.clear();
        res_b.clear();
        error_ref = callback_error;
        store_new(gL);
        GCodeStore *store = (GCodeStore*)lua_touserdata(gL, -1);
        store->lines.swap(result_lines);
    }
    parse_mutex.unlock();
    if(error_ref != LUA_NOREF) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, error_ref);
        luaL_unref(L, LUA_REGISTRYINDEX, error_ref);
        return lua_error(L);
    }
    if(errors) return luaL_error(L, "G-code parse errors: %d", errors);
    return 1;
}
