
local ui = require "tek.ui"


local floor = math.floor

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)


local Image = ui.Image

local SPINDLEimg = Image:new{
  {
    0x8000,0,
    0x4000, 0xffff,
    0xc000, 0xffff,
    0x8000,0
  },
  false, false,
  true,
  {{0xa000, 3, {1, 2, 3, 4}, "black"}}
}



return function (self, x, y, z)
  --if Frame.draw(self) then
  local x0, y0, x1, y1 = self:getRect()
  local xb, yb
  local bnd = self.Bnd
  local w = x1 - x0 + 1 - 20
  local h = y1 - y0 + 1 - 20
  local sw, sh = w/40, h/8
  local xsc, ysc = (x0+x1)/2, (y0+y1)/2
  local d = self.Window.Drawable
--    local p = self.Points
  local kw = w / (bnd.xmax - bnd.xmin)
  local kh = h / (bnd.ymax - bnd.ymin)
  local k = kw
  if kh < kw then k = kh end
  k = k * _G.Flags.DispScale / 100
  
  local xbc, ybc = (bnd.xmax - bnd.xmin)*k/2, (bnd.ymax - bnd.ymin)*k/2
  local dx, dy = 
            xsc - xbc + _G.Flags.screenShift.x, 
            ysc + ybc + _G.Flags.screenShift.y
    
  local c = self.PenSpindle
    
  d:pushClipRect(x0, y0, x1, y1)
    
  if _G.Flags.DisplayProection == "xy" then
    xb = dx + 15 + (x - bnd.xmin)*k 
    yb = dy - 15 - (y - bnd.ymin)*k
    
    SPINDLEimg:draw(d, floor(xb-sw), floor(yb-sh), floor(xb+sw), floor(yb), c)
  elseif _G.Flags.DisplayProection == "xyz" then
    bnd3d = {
        xmin = (bnd.xmin + bnd.ymin)*S60,
        ymin = (bnd.xmax - bnd.ymin)*C60, --+ bnd.zmin,
        xmax = (bnd.xmax + bnd.ymax)*S60,
        ymax = (bnd.xmin - bnd.ymax)*C60, --+ bnd.zmax,
    }
    kw = w / (bnd3d.xmax - bnd3d.xmin)
    kh = h / (bnd3d.ymax - bnd3d.ymin)
    k = kw
    if kh < kw then k = kh end
    k = k * _G.Flags.DispScale / 100
    
    xbc, ybc = (bnd3d.xmax + bnd3d.xmin)*k/2, (bnd3d.ymax + bnd3d.ymin)*k/2
    dx, dy = 
            xsc - xbc + _G.Flags.screenShift.x, 
            ysc + ybc + _G.Flags.screenShift.y
          
    xb = dx + 15 + ((x - bnd.xmin) + (y - bnd.ymin))*S60*k
    yb = dy - 15 - (( (x - bnd.xmin) - (y - bnd.ymin))*C60 + z)*k
    
    SPINDLEimg:draw(d, floor(xb-sw), floor(yb-sh), floor(xb+sw), floor(yb), c)
  end
  d:popClipRect()
  
  --self.Changed = true
end
