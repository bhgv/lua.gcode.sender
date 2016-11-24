
local ui = require "tek.ui"

local floor = math.floor --tointeger 

local int = function(a) return math.tointeger(floor(a)) end

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)


return {
  drawZeroCross = function (self, d, dx, dy, k)
    local bnd = self.Bnd
    local c = self.PenCross 
    
      if not (
        int (dx) and
        int (dy) and
        int (k)
        ) 
      then return end
    
    if _G.Flags.DisplayProection == "xy" then
      local x = dx + 15 + (0 - bnd.xmin)*k
      local y = dy - 15 - (0 - bnd.ymin)*k

      d:drawLine(floor(x-10), floor(y), floor(x+10), floor(y), c) 
      d:drawLine(floor(x), floor(y-10), floor(x), floor(y+10), c) 
    elseif _G.Flags.DisplayProection == "xyz" then
      local x0 = dx + 15 - ((bnd.xmin) + (bnd.ymin))*S60 *k 
      local y0 = dy - 15 + ((bnd.xmin) - (bnd.ymin))*C60 *k 
      d:drawLine(floor(x0-10), floor(y0), floor(x0+10), floor(y0), c) 
      d:drawLine(floor(x0), floor(y0-10), floor(x0), floor(y0+10), c) 
    end
  end,

}
