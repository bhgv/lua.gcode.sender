
local floor = math.floor
local ui = require "tek.ui"
local Frame = ui.Frame

local Display = Frame:newClass()

function Display.new(class, self)
    self = self or { }
    self.Bnd = {xmax = 1, xmin = 0, ymax = 1, ymin = 0}
    self.Changed = false
    self.Points = { }
    self = Frame.new(class, self)
    self:reset()
    return self
end

function Display:reset()
end

function Display:show(drawable)
    Frame.show(self, drawable)
    self.Window:addInputHandler(ui.MSG_INTERVAL, self, self.update)
end

function Display:hide()
    self.Window:remInputHandler(ui.MSG_INTERVAL, self, self.update)
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
    local bnd = self.Bnd
    local w = x1 - x0 + 1 - 10
    local h = y1 - y0 + 1 - 10
    local d = self.Window.Drawable
    local p = self.Points
    local kw = w / (bnd.xmax - bnd.xmin)
    local kh = h / (bnd.ymax - bnd.ymin)
    local k = kw
    if kh < kw then k = kh end
    
    k = k * _G.Flags.DispScale / 100
    
    for i = 1, #self.Points do
        local x = 5 + x0 + (p[i - 1].x - bnd.xmin)*k --* w + 5
        local y = 5 + y0 + (p[i - 1].y - bnd.ymin)*k --* h + 5
        local x1 = 5 + x0 + (p[i].x - bnd.xmin)*k --* w + 5
        local y1 = 5 + y0 + (p[i].y - bnd.ymin)*k --* h + 5
        local c = p[i].p
        if c == nil then c = "red" end
        d:drawLine(floor(x), floor(y), floor(x1), floor(y1), c) --"bright")
    end
  end
end

return Display:new 
    {
        MinWidth = 40, MinHeight = 60,
        Style = "background-color: white, width: free,",
    }
