
local exec = require "tek.lib.exec"


local buf = {}

local partAbs = "G90"

local header = ""
local footer = ""

local move_to = function(par)
      local x, y, z, s, f = tonumber(par.x), tonumber(par.y), tonumber(par.z), tonumber(par.s), tonumber(par.f)
      local ln = ""
      if x then
        ln = ln .. "X" .. x
      end
      if y then
        ln = ln .. "Y" .. y
      end
      if z then
        ln = ln .. "Z" .. z
      end
      if s then
        ln = ln .. "S" .. f
      end
      if f then
        ln = ln .. "F" .. f
      end
      return ln
end


return {
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
  
  start = function(self)
      buf = {}
      artAbs = "G90"
  end,
  finish = function(self)
      --local i, ln
      local gcode = header .. "\n" .. table.concat(buf, "\n") .. footer .. "\n"
      --for i,ln in ipairs(buf) do
      --  gcode = gcode .. ln .. "\n"
      --end
      --gcode = gcode .. footer .. "\n"
      exec.sendport("*p", "ui", "<PLUGIN><GCODE>" .. gcode)
  end,
  
  absolute = function(self)
      artAbs = "G90"
  end,
  relative = function(self)
      artAbs = "G91"
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

