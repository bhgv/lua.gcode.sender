
local floor = math.floor
local ui = require "tek.ui"
local Frame = ui.Frame

local Text = ui.Text

--local NOTIFY_YPOS = { ui.NOTIFY_SELF, "onSetYPos", ui.NOTIFY_VALUE }
--local NOTIFY_XPOS = { ui.NOTIFY_SELF, "onSetXPos", ui.NOTIFY_VALUE }

local Display = Frame:newClass()

function Display.new(class, self)
    self = self or { }
    self.Bnd = {xmax = 1, xmin = 0, ymax = 1, ymin = 0}
    self.Changed = false
    self.Points = { }
    --self.font = self.Application.Display:openFont(self.Font)
    self = Frame.new(class, self)
--    self = Text.new(class, self)
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
--    self:addNotify("YPos", ui.NOTIFY_ALWAYS, NOTIFY_YPOS)
--    self:addNotify("XPos", ui.NOTIFY_ALWAYS, NOTIFY_XPOS)
end

function Display:hide()
    self.Window:remInputHandler(ui.MSG_INTERVAL, self, self.update)
    self.Window:remInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    self.Window:remInputHandler(ui.MSG_MOUSEBUTTON, self, self.onMButton)
--    self:remNotify("YPos", ui.NOTIFY_ALWAYS, NOTIFY_YPOS)
--    self:remNotify("XPos", ui.NOTIFY_ALWAYS, NOTIFY_XPOS)
    Frame.hide(self)
end

function Display:update()
  if self.Window.Drawable then
    if self.Changed --[[and (self.Frame % REFRESH_DELAY == 0)]] then
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
    
    self:drawAxis(d, dx, dy, k)
    
    for i = 1, #self.Points do
        local xb = dx + 15 + (p[i - 1].x - bnd.xmin)*k --* w + 5
        local yb = dy - 15 - (p[i - 1].y - bnd.ymin)*k --* h + 5
        local xe = dx + 15 + (p[i].x - bnd.xmin)*k --* w + 5
        local ye = dy - 15 - (p[i].y - bnd.ymin)*k --* h + 5
        local c = p[i].p
        if c == nil then c = "red" end
        d:drawLine(floor(xb), floor(yb), floor(xe), floor(ye), c) --"bright")
    end
    
    self:drawZeroCross(d,
            dx + 15 + (0 - bnd.xmin)*k,
            dy - 15 - (0 - bnd.ymin)*k
            )
    d:popClipRect()
    return true
  end
end


function Display:drawZeroCross(d, x, y)
      d:drawLine(floor(x-10), floor(y), floor(x+10), floor(y), "green") --"bright")
      d:drawLine(floor(x), floor(y-10), floor(x), floor(y+10), "green") --"bright")
end

function Display:drawAxis(d, dx, dy, k)
    local x0, y0, x1, y1 = self:getRect()
    local x, y
    local bnd = self.Bnd
    local xstp = (bnd.xmax - bnd.xmin)/10
    local ystp = (bnd.ymax - bnd.ymin)/10
    
    local font = self.font or self.Application.Display:openFont(self.Font)
    local cw, ch, _ = font:getTextSize("")
    
    self.TextRecords = {}
    
    local c = "bright"

    self.font = font
    d:setFont(font)
      
    for i = 0, 10 do
      local x = floor(dx + 15 + (i*xstp)*k) --* w + 5
      local y = floor(dy - 15 - (i*ystp)*k) --* h + 5

      sx = string.format("%0.2f", i*xstp + bnd.xmin)
      sy = string.format("%0.2f", i*ystp + bnd.ymin)
      
      cw, ch = font:getTextSize(sy)
      d:drawText(floor(x0), floor(y), floor(x0+cw), floor(y-ch), sy, "black")
      cw, ch = font:getTextSize(sx)
      d:drawText(floor(x), floor(y1-ch), floor(x+cw), floor(y1), sx, "black")
      
      d:drawLine(floor(x), floor(y0+5), floor(x), floor(y1-15), c) --"bright")
      d:drawLine(floor(x0+15), floor(y), floor(x1-5), floor(y), c) --"bright")
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
      self.moveStart = {x=x, y=y}
      self.Window:addInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    elseif key == 2 then
      self.Window:remInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    elseif key == 64 then
    elseif key == 128 then
    end
    --print("pos = ", x, y, key)
  end

return msg
end



return Display:new 
    {
      Font = "Vera:9",
        MinWidth = 40, MinHeight = 60,
        Style = "background-color: white, width: free,",
    }
