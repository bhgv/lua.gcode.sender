
local ui = require "tek.ui"


local floor = math.floor

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)


return function (self, d, dx, dy, k)
    local x0, y0, x1, y1 = self:getRect()
    local bnd = self.Bnd
    local stp_cnt = floor(_G.Flags.DispScale * 10 / 100)
    local xstp = (bnd.xmax - bnd.xmin) / stp_cnt
    local ystp = (bnd.ymax - bnd.ymin) / stp_cnt
    
    local c = self.PenGrid --"bright"
    
    if xstp == 0 or ystp == 0 then return end
    
    if _G.Flags.DisplayProection == "xy" then
      for i = 0, stp_cnt do
        local x = floor(dx + 15 + (i*xstp)*k)
        local y = floor(dy - 15 - (i*ystp)*k)
        
        if x ~= x or y ~= y then return end
        
        d:drawLine(floor(x), floor(y0+5), floor(x), floor(y1-15), c) 
        d:drawLine(floor(x0+15), floor(y), floor(x1-5), floor(y), c) 
      end
    elseif _G.Flags.DisplayProection == "xyz" then
      for i = 0, stp_cnt do
        local xb = dx + 15 + ((i*xstp) + (bnd.ymin -bnd.ymin))*S60*k 
        local yb = dy - 15 - ((i*xstp) - (bnd.ymin -bnd.ymin))*C60*k 
        local xe = dx + 15 + ((i*xstp) + (bnd.ymax -bnd.ymin))*S60*k 
        local ye = dy - 15 - ((i*xstp) - (bnd.ymax -bnd.ymin))*C60*k 

        d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
        
        xb = dx + 15 + ((bnd.xmin -bnd.xmin) + (i*ystp))*S60*k 
        yb = dy - 15 - ((bnd.xmin -bnd.xmin) - (i*ystp))*C60*k 
        xe = dx + 15 + ((bnd.xmax -bnd.xmin) + (i*ystp))*S60*k 
        ye = dy - 15 - ((bnd.xmax -bnd.xmin) - (i*ystp))*C60*k 

        d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
      end
    end
end
