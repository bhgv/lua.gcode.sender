
local lfs = require"lfs"
local exec = require "tek.lib.exec"

local plugs_no = 0



local test_run_plugin = function(plug_path)  
  local task = exec.run(
    {
      taskname = "plug_" .. plugs_no,
      abort = false,
      func = function()
        local exec = require "tek.lib.exec"
        
        local tab2str = function(tab)
              local s = ""
              local k1, v1
              for k1,v1 in pairs(tab) do
                v1 = tostring(v1)
                v1 = v1:gsub("=", "\\u{3d}")
                v1 = v1:gsub("&", "\\u{26}")
                s = s .. k1 .. "=" .. v1 .. "\n"
              end
              return s
        end
        
--[[
        local new_G = {
        }
        
        local function get_upvalue(fn, search_name)
          local idx = 1
          while true do
            local name, val = debug.getupvalue(fn, idx)
            if not name then break end
            if name == search_name then
              return idx, val
            end
            idx = idx + 1
          end
        end
      
        local function set_upvalue(fn, name, val)
          debug.setupvalue(fn, get_upvalue(fn, name), val)
        end
]]

        local plug_path = arg[1]
        
        local f = loadfile(plug_path)
        
        if not f then return "can't load: " .. plug_path end
        
--        set_upvalue(f, "_ENV", new_G)

        local noerr, conf = pcall(f)
        
        if not noerr then 
          print(debug.traceback()) 
          return "can't execute: " .. plug_path
        end
        
        print("loaded plugin: " .. conf.name .. ", (" .. plug_path .. ")")
        
        if conf.type == "plugin" then
          local k, v, s
          s = ""
          for k,v in pairs(conf) do 
            if k == "params" then
              --[[
              s = s .. "params="
              local k1, v1
              for k1,v1 in pairs(v) do
                v1 = tostring(v1)
                v1 = v1:gsub("=", "\\u{3d}")
                v1 = v1:gsub("&", "\\u{26}")
                s = s .. k1 .. "\\u{3d}" .. v1 .. "\n"
              end
              s = s .. "&"
              ]]
            elseif k ~= "exec" then
              v = tostring(v)
              v = v:gsub("=", "\\u{3d}")
              v = v:gsub("&", "\\u{26}")
              s = s .. k .. "=" .. v .. "&" 
            end
          end
          print("s =", s)
          --exec.sendport("*p", "ui", "<PLUGIN><CONNECT>" .. s)
          exec.sendmsg("*p", s)
        else
          exec.sendmsg("*p", "")
          return "wrong config. plugin: " .. plug_path
        end
        
        local msg
        while msg ~= "QUIT" do 
          msg = exec.waitmsg(2000)
          if msg then
            print(msg)
            if msg == "<CLICK>" then
              exec.sendport("*p", "ui", "<PLUGIN><REM PARAMS>")
              if conf.params then
                local s = conf.params
                if type(s) == "table" then
                  s = tab2str(s)
                end
                exec.sendport("*p", "ui", "<PLUGIN>" .. exec.getname() .. "<SHOW PARAMS>" .. s)
              end
            elseif conf.exec and msg:match("^<EXECUTE>") then
              local pars = msg:match("^<EXECUTE>(.*)")
              local partab = {}
              local k,v
              for k,v in pars:gmatch("%s*([^=]+)=%s*([^\n]*)\n") do
                partab[k] = v
              end
              local out = conf:exec(partab)
            end
          end
        end
        
        return msg
      end,
    },
    plug_path
  )
  
  local msg = exec.waitmsg(1000)
  --print("msg =", msg)
  if (not msg) or msg == "" then
    task:join()
    exec.getsignals("actm")
  else
    local k, v
    local t = {}
    for k,v in msg:gmatch("([^%s=]+)=([^&]+)&") do
      v = v:gsub("\\u{3d}", "=")
      v = v:gsub("\\u{26}", "&")
      t[k] = v
    end
    
    table.insert(_G.Flags.Plugins, {
        taskname = "plug_" .. plugs_no, 
        conf = t,
    })
  
    plugs_no = plugs_no + 1
  end
end


return {
  collect_plugins = function(self)
    local path = _G.Flags.Plugins_path
    plugs_no = 0
    
    for file in lfs.dir(path) do
      if file ~= "." and file ~= ".." and file ~= "init.lua" then
        local f = path..'/'..file
        print ("\t "..f)
        local attr = lfs.attributes (f)
        assert (type(attr) == "table")
        if attr.mode == "directory" then
          if lfs.attributes(f .. "/init.lua") then
            test_run_plugin(f .. "/init.lua") 
          end
        elseif file:match("%.lua$") then
        --  for name, value in pairs(attr) do
        --    print (name, value)
        --  end
          test_run_plugin(f)
        end
      end
    end
  end,

}