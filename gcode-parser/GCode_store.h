#ifndef _GCODE_STORE_
#define _GCODE_STORE_

#include <new>
#include <string>
#include <vector>

struct GCodeStore {
    std::vector<std::string> lines;
};

static GCodeStore *check_store(lua_State *L) {
    return (GCodeStore*)luaL_checkudata(L, 1, "gcodeparser.store");
}

static int store_new(lua_State *L) {
    void *p = lua_newuserdata(L, sizeof(GCodeStore));
    new(p) GCodeStore;
    luaL_setmetatable(L, "gcodeparser.store");
    return 1;
}

static int store_gc(lua_State *L) {
    check_store(L)->~GCodeStore();
    return 0;
}

static int store_len(lua_State *L) {
    lua_pushinteger(L, check_store(L)->lines.size());
    return 1;
}

static int store_index(lua_State *L) {
    GCodeStore *s = check_store(L);
    if(lua_type(L, 2) == LUA_TNUMBER) {
        lua_Integer n = luaL_checkinteger(L, 2);
        if(n < 1 || (size_t)n > s->lines.size()) return 0;
        const std::string &line = s->lines[n - 1];
        lua_pushlstring(L, line.data(), line.size());
    } else {
        luaL_getmetatable(L, "gcodeparser.store");
        lua_pushvalue(L, 2);
        lua_rawget(L, -2);
    }
    return 1;
}

static int store_set(lua_State *L) {
    GCodeStore *s = check_store(L);
    lua_Integer n = luaL_checkinteger(L, 2);
    size_t len;
    const char *line = luaL_checklstring(L, 3, &len);
    luaL_argcheck(L, n >= 1 && (size_t)n <= s->lines.size() + 1, 2, "line out of range");
    if((size_t)n > s->lines.size()) s->lines.push_back(std::string(line, len));
    else s->lines[n - 1].assign(line, len);
    return 0;
}

static int store_insert(lua_State *L) {
    GCodeStore *s = check_store(L);
    lua_Integer n = luaL_checkinteger(L, 2);
    size_t len;
    const char *line = luaL_checklstring(L, 3, &len);
    luaL_argcheck(L, n >= 1 && (size_t)n <= s->lines.size() + 1, 2, "line out of range");
    s->lines.insert(s->lines.begin() + n - 1, std::string(line, len));
    return 0;
}

static int store_remove(lua_State *L) {
    GCodeStore *s = check_store(L);
    lua_Integer n = luaL_checkinteger(L, 2);
    luaL_argcheck(L, n >= 1 && (size_t)n <= s->lines.size(), 2, "line out of range");
    s->lines.erase(s->lines.begin() + n - 1);
    return 0;
}

static int store_clear(lua_State *L) {
    check_store(L)->lines.clear();
    return 0;
}

static int store_load(lua_State *L) {
    GCodeStore *s = check_store(L);
    size_t len;
    const char *text = luaL_checklstring(L, 2, &len);
    s->lines.clear();
    size_t start = 0;
    for(size_t i = 0; i < len; i++) {
        if(text[i] == '\r' || text[i] == '\n') {
            s->lines.push_back(std::string(text + start, i - start));
            if(text[i] == '\r' && i + 1 < len && text[i + 1] == '\n') i++;
            start = i + 1;
        }
    }
    if(start < len) s->lines.push_back(std::string(text + start, len - start));
    return 0;
}

static int store_concat(lua_State *L) {
    GCodeStore *s = check_store(L);
    const char *sep = luaL_optstring(L, 2, "\n");
    lua_Integer from = luaL_optinteger(L, 3, 1);
    lua_Integer to = luaL_optinteger(L, 4, s->lines.size());
    luaL_argcheck(L, from >= 1 && to >= from - 1 && (size_t)to <= s->lines.size(), 3, "range out of bounds");
    std::string text;
    for(lua_Integer i = from; i <= to; i++) {
        if(i > from) text += sep;
        text += s->lines[i - 1];
    }
    lua_pushlstring(L, text.data(), text.size());
    return 1;
}

static void register_store(lua_State *L) {
    static const luaL_Reg methods[] = {
        {"__gc", store_gc}, {"__len", store_len},
        {"__index", store_index}, {"__newindex", store_set},
        {"insert", store_insert}, {"remove", store_remove},
        {"clear", store_clear}, {"load", store_load},
        {"concat", store_concat}, {NULL, NULL}
    };
    luaL_newmetatable(L, "gcodeparser.store");
    luaL_setfuncs(L, methods, 0);
    lua_pushliteral(L, "protected metatable");
    lua_setfield(L, -2, "__metatable");
    lua_pop(L, 1);
}
#endif
