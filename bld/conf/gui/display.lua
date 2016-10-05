#!/usr/bin/env lua

local floor = math.floor
local ui = require "tek.ui"
local Frame = ui.Frame

local TSP = Frame:newClass()

function TSP.new(class, self)
    self = self or { }
    self.Bnd = {xmax = 1, xmin = 0, ymax = 1, ymin = 0}
    self.Decay = 0.9999999
    self.Frame = 1
    self.Length = 0
    self.Threshold = 0
    self.Changed = false
    self.Iterations = 0
    self.Accepted = 0
    self.Bombs = 0
    self.Points = { }
    self = Frame.new(class, self)
    self:reset()
    return self
end

function TSP:reset()
    self.Frame = 1
    self.Length = 0
    self.Iterations = 0
    self.Accepted = 0
    self.Bombs = 0
--    for i = 1, #self.Map do
--	self.Points[i] = self.Map[i]
--    end
    self.Length = self:length()
    self.Threshold = self.Length / #self.Points / 3
end

function TSP.getDecay(v)
    return 1 - 1 / math.pow(10, 8 ) --  - vv)
end

function TSP:show(drawable)
    Frame.show(self, drawable)
    self.Window:addInputHandler(ui.MSG_INTERVAL, self, self.update)
end

function TSP:hide()
    self.Window:remInputHandler(ui.MSG_INTERVAL, self, self.update)
    Frame.hide(self)
end

function TSP:update()
    if self.Window.Drawable then
	self.Frame = self.Frame + 1
	if self.Changed and (self.Frame % REFRESH_DELAY == 0) then
	    self.Changed = false
	    self:setFlags(ui.FL_REDRAW)
	end
    end
end

function TSP:draw()
    if Frame.draw(self) then
	local t = 15 - (1 - math.log(self.Threshold, 10))
--	self:getById("gauge-thresh"):setValue("Value", t)
--	self:getById("text-length"):setValue("Text", ("%.4f"):format(self.Length))
--	self:getById("text-iter"):setValue("Text", self.Iterations)
--	self:getById("text-accept"):setValue("Text", self.Accepted)
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

function TSP:length()
    local p = self.Points
    local tl = 0
    for i = 2, #p do
	local x0 = p[i - 1][1]
	local y0 = p[i - 1][2]
	local x1 = p[i][1]
	local y1 = p[i][2]
	local dx = x1 - x0
	local dy = y1 - y0
	local l = sqrt(dx * dx + dy * dy)
	tl = tl + l
    end
    return tl
end

function TSP:opt()
    
    local i1, i2
    local p = self.Points
    
    for i = 1, 1000 do
	self.Iterations = self.Iterations + 1
    
	repeat
	    i1 = floor(random() * #p) + 1
	    i2 = floor(random() * #p) + 1
	    if i2 < i1 then
		i1, i2 = i2, i1
	    end
	until i2 ~= i1 and i1 ~= 1 and i2 ~= #p
	
	local x0, y0, x1, y1, x2, y2, x3, y3
	local dx, dy
	
	local dtl
	
	x0 = p[i1 - 1][1]
	y0 = p[i1 - 1][2]
	x1 = p[i1][1]
	y1 = p[i1][2]
	x2 = p[i2][1]
	y2 = p[i2][2]
	x3 = p[i2 + 1][1]
	y3 = p[i2 + 1][2]
	
	dx = x1 - x0
	dy = y1 - y0
	dtl = sqrt(dx * dx + dy * dy)
	
	dx = x3 - x2
	dy = y3 - y2
	dtl = dtl + sqrt(dx * dx + dy * dy)
    
	dx = x2 - x0
	dy = y2 - y0
	dtl = -dtl + sqrt(dx * dx + dy * dy)
    
	dx = x3 - x1
	dy = y3 - y1
	dtl = dtl + sqrt(dx * dx + dy * dy)
	
	-- threshold accepting:
	local accept = dtl < self.Threshold
	if not accept then
	    -- drop some bombs:
	    if dtl < self.Length / #p and random() < 0.001 then
		accept = true
		self.Bombs = self.Bombs + 1
	    end
	end
	
	if accept then
	    local i3 = i1 + floor((i2 - i1 - 1) / 2)
	    local j = i2
	    for i = i1, i3 do
		p[i], p[j] = p[j], p[i]
		j = j - 1
	    end
	    self.Length = self.Length + dtl
	    self.Changed = true
	    self.Accepted = self.Accepted + 1
	end
	
	self.Threshold = self.Threshold * self.Decay
    
    end
    
    -- refresh length, so that floating point inaccuracies
    -- remain under control:
    self.Length = self:length()
    
end


return  TSP:new 
	{
	    MinWidth = 40, MinHeight = 60,
--	    Id = "the-tsp", 
	    Style = "background-color: white, width: free,",
	--    Map = luxembourg,
	--    Decay = TSP.getDecay(DEFAULT_DECAY)
	}

