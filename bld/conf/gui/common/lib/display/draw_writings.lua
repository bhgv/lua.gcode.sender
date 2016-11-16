
ui = require "tek.ui"


local floor = math.floor

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)



return {
  drawWritings = function(self, d, dx, dy, k)
    local x0, y0, x1, y1 = self:getRect()
    local x, y
    local stp_cnt = floor(_G.Flags.DispScale * 10 / 100)
    local bnd = self.Bnd
    local xstp = (bnd.xmax - bnd.xmin) / stp_cnt
    local ystp = (bnd.ymax - bnd.ymin) / stp_cnt
    
    local font = self.font or self.Application.Display:openFont(self.Font)
    local cw, ch
        
    local c = "black"

    self.font = font
    d:setFont(font)
    
    if _G.Flags.DisplayProection == "xy" then
      for i = 0,stp_cnt do
        x = floor(dx + 15 + (i*xstp)*k)
        y = floor(dy - 15 - (i*ystp)*k)

        sx = string.format("%0.2f", i*xstp + bnd.xmin)
        sy = string.format("%0.2f", i*ystp + bnd.ymin)
        
        cw, ch = font:getTextSize(sy)
        d:drawText(floor(x0), floor(y), floor(x0+cw), floor(y-ch), sy, c)
        cw, ch = font:getTextSize(sx)
        d:drawText(floor(x), floor(y1-ch), floor(x+cw), floor(y1), sx, c)
      end
    elseif _G.Flags.DisplayProection == "xyz" then
      for i = 0,stp_cnt do
        sx = string.format("%0.2f", i*xstp + bnd.xmin)
        sy = string.format("%0.2f", i*ystp + bnd.ymin)
        
        x = dx + 15 + ((i*xstp) + (-bnd.ymin))*S60*k
        y = dy - 15 - ((i*xstp) - (-bnd.ymin))*C60*k
        
        cw, ch = font:getTextSize(sx)
        d:drawText(floor(x-cw), floor(y), floor(x), floor(y+ch), sx, c)

        x = dx + 15 + ((-bnd.xmin) + (i*ystp))*S60*k 
        y = dy - 15 - ((-bnd.xmin) - (i*ystp))*C60*k 
      
        cw, ch = font:getTextSize(sy)
        d:drawText(floor(x-cw), floor(y-ch), floor(x), floor(y), sy, c)
      end
    end
  end,

}

