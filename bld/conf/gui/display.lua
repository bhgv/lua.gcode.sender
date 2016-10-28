
local floor = math.floor
local ui = require "tek.ui"
local Frame = ui.Frame

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)


local Display = Frame:newClass()

function Display.new(class, self)
    self = self or { }
    self.Bnd = {xmax = 1, xmin = 0, ymax = 1, ymin = 0}
    self.Changed = false
    self.Points = { }
    --self.font = self.Application.Display:openFont(self.Font)
    self = Frame.new(class, self)
    self.shiftX = 0
    self.shiftY = 0
    self:reset()
    return self
end

function Display:reset()
end

function Display:show(drawable)
    Frame.show(self, drawable)
    self.Window:addInputHandler(ui.MSG_INTERVAL, self, self.update)
    --self.Window:addInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    self.Window:addInputHandler(ui.MSG_MOUSEBUTTON, self, self.onMButton)
end

function Display:hide()
    self.Window:remInputHandler(ui.MSG_INTERVAL, self, self.update)
    self.Window:remInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    self.Window:remInputHandler(ui.MSG_MOUSEBUTTON, self, self.onMButton)
    Frame.hide(self)
end

function Display:update()
  if self.Window.Drawable then
    if self.Changed then
        self.Changed = false
        self:setFlags(ui.FL_REDRAW)
    end
  end
end

function Display:draw()
  if Frame.draw(self) then
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
    
    local xbc, ybc = (bnd.xmax - bnd.xmin)*k/2, (bnd.ymax - bnd.ymin)*k/2
    local dx, dy = 
              xsc - xbc + _G.Flags.screenShift.x, 
              ysc + ybc + _G.Flags.screenShift.y
    
    d:pushClipRect(x0, y0, x1, y1)
    
    if _G.Flags.DisplayProection == "xy" then
      self:drawAxis(d, dx, dy, k)
      
      for i = 1, #self.Points do
          local xb = dx + 15 + (p[i - 1].x - bnd.xmin)*k 
          local yb = dy - 15 - (p[i - 1].y - bnd.ymin)*k
          local xe = dx + 15 + (p[i].x - bnd.xmin)*k
          local ye = dy - 15 - (p[i].y - bnd.ymin)*k
          local c = p[i].p
          if c == nil then c = "red" end
          d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
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
      
      xbc, ybc = (bnd3d.xmax + bnd3d.xmin)*k/2, (bnd3d.ymax + bnd3d.ymin)*k/2
      dx, dy = 
              xsc - xbc + _G.Flags.screenShift.x, 
              ysc + ybc + _G.Flags.screenShift.y

      self:drawAxis(d, dx, dy, k)

      for i = 1, #self.Points do
          local xb = dx + 15 + ((p[i-1].x - bnd.xmin) + (p[i-1].y - bnd.ymin))*S60*k
          local yb = dy - 15 - (( (p[i-1].x - bnd.xmin) - (p[i-1].y - bnd.ymin))*C60 + p[i-1].z)*k
          local xe = dx + 15 + ((p[i].x - bnd.xmin) + (p[i].y - bnd.ymin))*S60*k
          local ye = dy - 15 - (( (p[i].x - bnd.xmin) - (p[i].y - bnd.ymin))*C60 + p[i].z)*k
          
          local c = p[i].p
          if c == nil then c = "red" end
          d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
      end
    end
    
    self:drawWritings(d, dx, dy, k)
    self:drawZeroCross(d, dx, dy, k)
    
    d:popClipRect()
    return true
  end
end


function Display:drawZeroCross(d, dx, dy, k)
  local bnd = self.Bnd
  if _G.Flags.DisplayProection == "xy" then
    local x = dx + 15 + (0 - bnd.xmin)*k
    local y = dy - 15 - (0 - bnd.ymin)*k

    d:drawLine(floor(x-10), floor(y), floor(x+10), floor(y), "green") 
    d:drawLine(floor(x), floor(y-10), floor(x), floor(y+10), "green") 
  elseif _G.Flags.DisplayProection == "xyz" then
    local x0 = dx + 15 + ((bnd.xmin) + (bnd.ymin))*S60 *k 
    local y0 = dy - 15 - ((bnd.xmin) - (bnd.ymin))*C60 *k 
    d:drawLine(floor(x0-10), floor(y0), floor(x0+10), floor(y0), "green") 
    d:drawLine(floor(x0), floor(y0-10), floor(x0), floor(y0+10), "green") 
  end
end

function Display:drawAxis(d, dx, dy, k)
    local x0, y0, x1, y1 = self:getRect()
    local bnd = self.Bnd
    local stp_cnt = floor(_G.Flags.DispScale * 10 / 100)
    local xstp = (bnd.xmax - bnd.xmin) / stp_cnt
    local ystp = (bnd.ymax - bnd.ymin) / stp_cnt
    
    local c = "bright"
    
    if _G.Flags.DisplayProection == "xy" then
      for i = 0, stp_cnt do
        local x = floor(dx + 15 + (i*xstp)*k)
        local y = floor(dy - 15 - (i*ystp)*k)
        
        d:drawLine(floor(x), floor(y0+5), floor(x), floor(y1-15), c) 
        d:drawLine(floor(x0+15), floor(y), floor(x1-5), floor(y), c) 
      end
    elseif _G.Flags.DisplayProection == "xyz" then
      for i = 0, stp_cnt do
        local xb = dx + 15 + ((i*xstp) + (-bnd.ymin))*S60*k 
        local yb = dy - 15 - ((i*xstp) - (-bnd.ymin))*C60*k 
        local xe = dx + 15 + ((i*xstp) + (bnd.ymax))*S60*k 
        local ye = dy - 15 - ((i*xstp) - (bnd.ymax))*C60*k 

        d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
        
        xb = dx + 15 + ((-bnd.xmin) + (i*ystp))*S60*k 
        yb = dy - 15 - ((-bnd.xmin) - (i*ystp))*C60*k 
        xe = dx + 15 + ((bnd.xmax) + (i*ystp))*S60*k 
        ye = dy - 15 - ((bnd.xmax) - (i*ystp))*C60*k 

        d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c)
      end
    end
end


function Display:drawWritings(d, dx, dy, k)
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
end

function Display:onMMove(msg)
  local x, y = msg[4], msg[5]
  --print("pos = ", x, y, msg[3])
  
  _G.Flags.screenShift.x = x - self.moveStart.x
  _G.Flags.screenShift.y = y - self.moveStart.y
  
  self.Changed = true
  
  return msg
end

function Display:onMButton(msg)
  local x, y, key = msg[4], msg[5], msg[3]
  local x0, y0, x1, y1 = self:getRect()

  if _G.Flags.DisplayMode == "drag" then
    if key == 1 and 
      (x0 < x and x < x1) and
      (y0 < y and y < y1)
    then
      self.moveStart = {x=x - _G.Flags.screenShift.x, y=y - _G.Flags.screenShift.y}
      self.Window:addInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    elseif key == 2 then
      self.Window:remInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    elseif key == 128 and 
      (x0 < x and x < x1) and
      (y0 < y and y < y1)
    then
      --print(key)
      local n = _G.Flags.DispScale 
      if n > 10 then
        n = n - 10
      else 
        n = 1
      end
      _G.Flags.DispScale = n
      _G.Flags.ShowScale(n)
      if _G.Flags.AutoRedraw then
        self.Changed = true
      end
    elseif key == 64 and 
      (x0 < x and x < x1) and
      (y0 < y and y < y1)
    then
      --print(key)
      local n = _G.Flags.DispScale 
      n = n + 10
      _G.Flags.DispScale = n
      _G.Flags.ShowScale(n)
      if _G.Flags.AutoRedraw then
        self.Changed = true
      end
    end
--    print("pos = ", x, y, key)
  end

return msg
end



return Display:new 
    {
      Font = "Vera:9",
        MinWidth = 40, MinHeight = 60,
        Style = "background-color: white, width: free,",
    }
