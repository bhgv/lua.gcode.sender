#include <assert.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

static void run(lua_State *L, const char *code) {
    int status = luaL_dostring(L, code);
    if(status) fprintf(stderr, "%s\n", lua_tostring(L, -1));
    assert(status == LUA_OK);
}

int main(void) {
    lua_State *ui = luaL_newstate();
    lua_State *sender = luaL_newstate();
    luaL_openlibs(ui);
    luaL_openlibs(sender);
    run(ui, "p=require 'gcodeparser'; s=p.new_store(); s[1]='UI'; "
        "p.set_callback_dict{cmd=function() called=true end}");
    run(sender, "p=require 'gcodeparser'; s=p.new_store(); s[1]='sender'");
    run(ui, "assert(p:do_parse('M5')[1]:match('M5')); assert(called and s[1]=='UI')");
    lua_close(sender);
    run(ui, "assert(p:do_parse('G90')[1]:match('G90')); assert(s[1]=='UI')");
    lua_close(ui);
    puts("independent Lua states passed");
    return 0;
}
