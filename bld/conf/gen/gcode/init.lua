
local exec = require "tek.lib.exec"


local buf = {}

local partAbs = "G90"

local header = ""
local footer = ""

local move_to = function(par)
      if not par then return "" end
      
      local x, y, z, s, f = tonumber(par.x), tonumber(par.y), tonumber(par.z), tonumber(par.s), tonumber(par.f)
      local ln = ""
      if x then
        ln = ln .. "X" .. string.format("%0.4f", x)
      end
      if y then
        ln = ln .. "Y" .. string.format("%0.4f", y)
      end
      if z then
        ln = ln .. "Z" .. string.format("%0.4f", z)
      end
      if s then
        ln = ln .. "S" .. string.format("%0.1f", s)
      end
      if f then
        ln = ln .. "F" .. string.format("%0.1f", f)
      end
      return ln
end



local lib = {
        header = function(g, frq)
          g:start()
          g:set_param("absolute")
          g:set_param("metric")

          g:spindle_freq(frq)
          g:spindle_on(true)
        end,

        footer = function(g, z_wlk)
          g:walk_to{z = z_wlk}
          g:walk_to{x = 0, y = 0}
          g:walk_to{z = 0}
          g:spindle_on(false)
          
          g:finish()
        end,

}


return {
  lib = lib,
  
  --[[]]
  header = function(self, str)
    local t = type(str)
    if t == "string" then
      str = str
    elseif t == "table" then
      str = table.concat(str, "\n")
    end
    header = str
  end,
  
  footer = function(self, str)
    local t = type(str)
    if t == "string" then
      str = str
    elseif t == "table" then
      str = table.concat(str, "\n")
    end
    footer = str
  end,
  --[[]]
  
  start = function(self)
      buf = {}
      artAbs = "G90"
  end,
  
  finish = function(self)
      local gcode = header .. "\n" .. table.concat(buf, "\n") .. footer .. "\n"
      exec.sendport("*p", "ui", 
--        "<PLUGIN>"
--        .. "<NAME>"
--        .. exec.getname() 
--        .. 
        "<GCODE>" 
        .. gcode
      )
  end,
  
  set_param = function(self, par_nm, ...)
      if par_nm == "absolute" then
        artAbs = "G90"
      elseif par_nm == "relative" then
        artAbs = "G91"
      end
  end,
  
  
  work_to = function(self, par)
      local ln = partAbs .. " G1 " .. move_to(par)
      table.insert(buf, ln)
  end,
  
  walk_to = function(self, par)
      local ln = partAbs .. " G0 " .. move_to(par)
      table.insert(buf, ln)
  end,
  
  arc_cw = function(self, par)
      local ln = partAbs .. " G2 " .. move_to(par)
      table.insert(buf, ln)
  end,
  arc_ccw = function(self, par)
      local ln = partAbs .. " G3 " .. move_to(par)
      table.insert(buf, ln)
  end,
  
  spindle_on = function(self, on)
      if on == nil then on = true end
      local ln = (on and "M3") or "M5"
      table.insert(buf, ln)
  end,
  spindle_freq = function(self, freq)
      if not freq then return end
      local ln = "F" .. tonumber(freq)
      table.insert(buf, ln)
  end,
  
  speed = function(self, speed)
      if not speed then return end
      speed = tonumber(speed)
      if not speed > 0 then return end
      local ln = "S" .. tonumber(speed)
      table.insert(buf, ln)
  end,
  
}

