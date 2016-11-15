

local ui = require "tek.ui"


local floor = math.floor

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)


local function calcPen(self, d, base_clr, z)
  local clr
  if base_clr == nil then
    clr = self.PenWalk
  else
    local bnd = self.Bnd
    local k
    if (bnd.zmax - bnd.zmin) ~= 0 then
      k = (z - bnd.zmin) / (bnd.zmax - bnd.zmin)
      clr = self.PenTab[1+math.ceil((#self.PenTab - 1) * k)]
    else
      --k = 0
      clr = self.PenTab[#self.PenTab]
    end
  end
  return clr or self.PenWalk
end


local transformCoords = require "conf.utils.transform_coords"




return function (self)
  if ui.Frame.draw(self) then
    local x0, y0, x1, y1 = self:getRect()
    local xb, yb, xe, ye
    local bnd = self.Bnd
    local w = x1 - x0 + 1 - 20
    local h = y1 - y0 + 1 - 20
    local xsc, ysc = (x0+x1)/2, (y0+y1)/2
    local d = self.Window.Drawable
    local p = self.Points
    local kw = w / (bnd.xmax - bnd.xmin)
    local kh = h / (bnd.ymax - bnd.ymin)
    local k = kw
    if kh < kw then k = kh end
    k = k * _G.Flags.DispScale / 100
    
    self.k = k
    
    local xbc, ybc = (bnd.xmax - bnd.xmin)*k/2, (bnd.ymax - bnd.ymin)*k/2
    local dx, dy = 
              xsc - xbc + _G.Flags.screenShift.x, 
              ysc + ybc + _G.Flags.screenShift.y
              
    self.dx = dx
    self.dy = dy
    
    local scr_lns = {}
    local ln 
    
    local pb, pe
    
    d:pushClipRect(x0, y0, x1, y1)
    
    if _G.Flags.DisplayProection == "xy" then
      self:drawAxis(d, dx, dy, k)
      
      for i = 1, #self.Points do
          pb, pe = transformCoords(p[i-1]), transformCoords(p[i])
          
          local xb = dx + 15 + (pb.x - bnd.xmin)*k 
          local yb = dy - 15 - (pb.y - bnd.ymin)*k
          local xe = dx + 15 + (pe.x - bnd.xmin)*k
          local ye = dy - 15 - (pe.y - bnd.ymin)*k
          local c = calcPen(self, d, p[i].p, p[i].z) -- or "green"
          
          ln = {
              xb = floor(xb), yb = floor(yb), xe = floor(xe), ye = floor(ye), 
              i = i, 
              c = c,
              ln_n = p[i].ln_n
          }
          table.insert(scr_lns, ln)
          
          d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
          
          --d:freePen(c)
      end
    elseif _G.Flags.DisplayProection == "xyz" then
      local bnd3d = {
        xmin = (bnd.xmin + bnd.ymin)*S60,
        ymin = (bnd.xmax - bnd.ymin)*C60, --+ bnd.zmin,
        xmax = (bnd.xmax + bnd.ymax)*S60,
        ymax = (bnd.xmin - bnd.ymax)*C60, --+ bnd.zmax,
      }
      self.bnd3d = bnd3d
      
      kw = w / (bnd3d.xmax - bnd3d.xmin)
      kh = h / (bnd3d.ymax - bnd3d.ymin)
      k = kw
      if kh < kw then k = kh end
      k = k * _G.Flags.DispScale / 100
      self.k3d = k
      
      xbc, ybc = (bnd3d.xmax + bnd3d.xmin)*k/2, (bnd3d.ymax + bnd3d.ymin)*k/2
      dx, dy = 
              xsc - xbc + _G.Flags.screenShift.x, 
              ysc + ybc + _G.Flags.screenShift.y
              
      self.dx = dx
      self.dy = dy

      self:drawAxis(d, dx, dy, k)

      for i = 1, #self.Points do
          pb, pe = transformCoords(p[i-1]), transformCoords(p[i])
          
          local xb = dx + 15 + ((pb.x - bnd.xmin) + (pb.y - bnd.ymin))*S60*k
          local yb = dy - 15 - (( (pb.x - bnd.xmin) - (pb.y - bnd.ymin))*C60 + pb.z)*k
          local xe = dx + 15 + ((pe.x - bnd.xmin) + (pe.y - bnd.ymin))*S60*k
          local ye = dy - 15 - (( (pe.x - bnd.xmin) - (pe.y - bnd.ymin))*C60 + pe.z)*k
          
--          local c = p[i].p or "green"
          local c = calcPen(self, d, p[i].p, p[i].z) -- or "green"
          
          ln = {
              xb = floor(xb), yb = floor(yb), xe = floor(xe), ye = floor(ye), 
              i = i, 
              c = c, 
              ln_n = p[i].ln_n
          }
          table.insert(scr_lns, ln)
          
          d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
      
          --d:freePen(c)
      end
    end
    
    self:drawWritings(d, dx, dy, k)
    self:drawZeroCross(d, dx, dy, k)
    
    self.scr_lns = scr_lns
    
    local ln = self.sel_line
    if ln then
      ln = scr_lns[ln.i]
      d:drawLine(ln.xb, ln.yb, ln.xe, ln.ye, "red")
      self.sel_line = ln
    end

    d:popClipRect()
    
    return true
  end
end
