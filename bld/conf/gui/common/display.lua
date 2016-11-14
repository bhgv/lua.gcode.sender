
local ui = require "tek.ui"
local Frame = ui.Frame

local exec = require "tek.lib.exec"

local floor = math.floor

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)

--[[
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
]]


local maxX = 10

local function ptXline(pars)
  local ln = pars.line 
  local pt = pars.point
  local a = (ln.ye - ln.yb)/(ln.xe - ln.xb)
  local bl = ln.yb - ln.xb*a
  local bp = pt.y - pt.x*a
  
  local bnd = {
    xmin = (ln.xb < ln.xe and ln.xb) or ln.xe,
    xmax = (ln.xe > ln.xb and ln.xe) or ln.xb,
    ymin = (ln.yb < ln.ye and ln.yb) or ln.ye,
    ymax = (ln.ye > ln.yb and ln.ye) or ln.yb,
  }
  
  if 
      pt.x < bnd.xmin - maxX or
      pt.x > bnd.xmax + maxX or
      pt.y < bnd.ymin - maxX or
      pt.y > bnd.ymax + maxX 
  then
    return nil
  end
  
  local r = math.abs(bl - bp)
  return r == r and r
end





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
    
    self.drawAxis = require "conf.gui.common.lib.display.draw_axis"
    self.draw = require "conf.gui.common.lib.display.draw_draft"
    self.drawSpindle = require "conf.gui.common.lib.display.draw_spindle"
    
    
    
    self:reset()
    return self
end

function Display:reset()
end


function Display:setup(app, win)
  ui.Frame.setup(self, app, win)
  --print(app, win)
  app:addInputHandler(ui.MSG_USER, self, self.msgUser)
end

function Display:cleanup()
  ui.Frame.cleanup(self)
  self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
end


function Display:show(drawable)
    Frame.show(self, drawable)
    self.Window:addInputHandler(ui.MSG_INTERVAL, self, self.update)
    --self.Window:addInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    self.Window:addInputHandler(ui.MSG_MOUSEBUTTON, self, self.onMButton)
    --self.Window:addInputHandler(ui.MSG_USER, self, self.msgUser)
    self.Window:addInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMdisplayXY)
    
    local clr, i
    local d = self.Window.Drawable
    local penTab = {}
    for i = 0,150 do
      clr = d:allocPen(170, 150-i, 150-i, 0xff) --string.format("0x%0.2X%0.2X%0.2X", mod_clr, mod_clr, base_clr)
      table.insert(penTab, clr)
    end
    self.PenTab = penTab
    self.PenWalk = d:allocPen(170, 0, 0x80, 0)
    self.PenSpindle = d:allocPen(200, 200, 0, 150)
    self.PenGrid = d:allocPen(255, 250, 250, 250)
    self.PenCross = d:allocPen(100, 240, 0, 0)
end

function Display:hide()
    self.Window:remInputHandler(ui.MSG_INTERVAL, self, self.update)
    self.Window:remInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMove)
    self.Window:remInputHandler(ui.MSG_MOUSEBUTTON, self, self.onMButton)
    --self.Window:remInputHandler(ui.MSG_USER, self, self.msgUser)
    self.Window:remInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMdisplayXY)
    
    Frame.hide(self)

    local i
    local d = self.Window.Drawable
    local penTab = self.PenTab
    for i = 1,#penTab do
      d:freePen(penTab[i])
    end
    self.PenTab = {}
    d:freePen(self.PenWalk)
    d:freePen(self.PenSpindle)
    d:freePen(self.PenGrid)
    d:freePen(self.PenCross)
end

function Display:update()
  if self.Window.Drawable then
    if self.Changed then
        self.Changed = false
        self:setFlags(ui.FL_REDRAW)
    end
  end
end



function Display:calcScale()
  local x0, y0, x1, y1 = self:getRect()
  --local xb, yb
  local bnd = self.Bnd
  local w = x1 - x0 + 1 - 20
  local h = y1 - y0 + 1 - 20
  --local sw, sh = w/40, h/8
  --local xsc, ysc = (x0+x1)/2, (y0+y1)/2
  --local d = self.Window.Drawable
--    local p = self.Points
  local kw = w / (bnd.xmax - bnd.xmin)
  local kh = h / (bnd.ymax - bnd.ymin)
  local k = kw
  if kh < kw then k = kh end
  k = k * _G.Flags.DispScale / 100
  
  return k
end


function Display:drawZeroCross(d, dx, dy, k)
  local bnd = self.Bnd
  local c = self.PenCross 
  
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



local mouseMode = {
                  lb="up",
                  Rstart = 0,
                  sc = 1.0,
}

function Display:onMMdisplayXY(msg)
  local x, y = msg[4], msg[5]
  
  local x0, y0, x1, y1 = self:getRect()
  if 
    x < x0 or x > x1 or
    y < y0 or y > y1
  then
    return msg
  end
  
  local dx = self.dx
  local dy = self.dy
  local k = self:calcScale()
  local bnd = self.Bnd

  if _G.Flags.DisplayProection == "xy" then
    if dx and dy and k and bnd then
      _G.Flags.showMouseXY(
            (x - dx - 15)/k + bnd.xmin, -- x
            (dy - 15 - y)/k + bnd.ymin  -- y
      )
    end
  elseif _G.Flags.DisplayProection == "xyz" then
    local k = self.k3d
    if dx and dy and k and bnd then
      local S60_k_2 = S60 * k * 2
      local C60_k_2 = C60 * k * 2
      
      local X_dX_15 = (x - dx - 15)/S60_k_2
      local Y_dY_15 = (dy - 15 - y)/C60_k_2
    
      _G.Flags.showMouseXY(
            X_dX_15 + Y_dY_15 + bnd.xmin, -- x
            X_dX_15 - Y_dY_15 + bnd.ymin  -- y
      )
    end
  end

  return msg
end


function Display:onMMove(msg)
  local x, y = msg[4], msg[5]
  --print("pos = ", x, y, msg[3])
  
  _G.Flags.screenShift.x = x - self.moveStart.x
  _G.Flags.screenShift.y = y - self.moveStart.y
  
  self:onMMdisplayXY(msg)
  
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
      
      self.Window:addInputHandler(ui.MSG_MOUSEMOVE, self, self.onMMdisplayXY)
    elseif key == 128 and 
      (x0 < x and x < x1) and
      (y0 < y and y < y1)
    then
      --print(key)
      local n = _G.Flags.DispScale 
      if n >= 15 then
        n = n - 5
      else 
        n = 10
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
  else -- not _G.Flags.DisplayMode == "drag"
    if key == 1 and 
      (x0 < x and x < x1) and
      (y0 < y and y < y1)
    then
      mouseMode.lb = "down"
      --print("pos = ", x, y, key)
      local k = self:calcScale()
      local bnd = self.Bnd

      local i, pb, pe

      local dist
      local min_dist = 10000
      local min_dist_n
      
      local pt = {
        x = x, --(x - self.dx - 15)/k + bnd.xmin, 
        y = y, --(self.dy - 15 - y)/k + bnd.ymin,
      }
      --print("cnv pt", pt.x, pt.y)
      
      for i = 1, #self.scr_lns do --#self.Points do
        dist = ptXline {
          point = pt,
          i = i,
          line = self.scr_lns[i],
        }
        
        if dist and dist < min_dist then
          min_dist = dist
          min_dist_n = i
          --print(i, dist)
        end
      end
      
      if min_dist_n then
        local ln_n = self:sel_item(min_dist_n)
        
        if ln_n then
          gLstWdgtM:setValue("SelectedLine", ln_n)
          gLstWdgtM:setValue("CursorLine", ln_n)
        end

        --self.sel_line = ln
      end
    
      mouseMode.Mstart = {
            x=x, -- - _G.Flags.screenShift.x, 
            y=y -- - _G.Flags.screenShift.y
      }
      
      local transf = _G.Flags.Transformations 

      local x0, y0, x1, y1 = self:getRect()
      local xc, yc = (x0 + x1)/2, (y0 + y1)/2
      
      mouseMode.Rstart = math.atan2(y - yc, x - xc) + transf.Rotate
      mouseMode.Center = {x = xc, y = yc, }
      
      if op == "mirrorX" or op == "mirrorY" then  
        if op == "mirrorX" then
          --transf.Mirror.v
        else
        end
      else
        self.Window:addInputHandler(ui.MSG_MOUSEMOVE, self, self.onMTransform)
      end
    elseif key == 2 then
      mouseMode.lb = "up"
      self.Window:remInputHandler(ui.MSG_MOUSEMOVE, self, self.onMTransform)
    end
  end
  return msg
end


function Display:onMTransform(msg)
  local x, y = msg[4], msg[5]
  local transf = _G.Flags.Transformations 
  local op = transf.CurOp
  local txt_out
  
  local dx, dy =
      (x - mouseMode.Mstart.x), 
      (mouseMode.Mstart.y - y)
      
  --move
  if op == "move" then
    local tr_mv = transf.Move
    tr_mv.x = tr_mv.x + dx/self.k
    tr_mv.y = tr_mv.y + dy/self.k
    
    mouseMode.Mstart = {
            x=x, 
            y=y 
    } 
    txt_out = string.format( "X=%.2f, Y=%.2f, Z=%.2f",
                                  tr_mv.x,
                                  tr_mv.y,
                                  tr_mv.z 
                  )

  --scaleXY
  elseif op == "scaleXY" then
    local xc, yc = mouseMode.Mstart.x, mouseMode.Mstart.y 
    local xs, ys = (x - xc), (yc - y)
    local sgn = ((xs+ys) < 0 and -1) or 1
    local zoom = sgn * math.sqrt(xs*xs + ys*ys) * 0.01
    transf.Scale.x = transf.Scale.x + zoom
    transf.Scale.y = transf.Scale.x + zoom
      
    mouseMode.Mstart = {
            x=x, 
            y=y 
    } 
    txt_out = string.format( "X=%.2f, Y=%.2f, Z=%.2f",
                                  transf.Scale.x,
                                  transf.Scale.y,
                                  transf.Scale.z 
                  )

  --rotate
  elseif op == "rotate" then
    local xc, yc = mouseMode.Center.x, mouseMode.Center.y 
    transf.Rotate = mouseMode.Rstart - math.atan2(y - yc, x - xc) 

    txt_out = string.format( "Angle=%.2f",
                                  math.deg(transf.Rotate)
                  )

--[[    
  elseif op == "mirrorX" then
    --transf.Mirror.v
  
  elseif op == "mirrorY" then
    --transf.Mirror.v
]]
  end

  if txt_out then
    _G.Flags.TransformInput:setValue("Text", txt_out)
  end
  
  self:onMMdisplayXY(msg)
  
  self.Changed = true
  
  return msg
end



function Display:sel_item(i)
  local ln = nil
  local d = self.Window.Drawable  
  local ln_n = nil
  
  d:pushClipRect(self:getRect())
  
  local oln = self.sel_line
  if oln then
    d:drawLine(oln.xb, oln.yb, oln.xe, oln.ye, oln.c)
  end
  if i then
    ln = self.scr_lns[i]
    d:drawLine(ln.xb, ln.yb, ln.xe, ln.ye, "red")
    ln_n = ln.ln_n
  end
  self.sel_line = ln
  
  d:popClipRect()
  
  return ln_n
end


function Display:msgUser(msg)
  local ud = msg[-1]
  --print("ud", ud)
  if ud:match("<STATUS>") then
--    print("ud1", ud)
    local x, y, z = ud:match("<wX>([^<]+)<wY>([^<]+)<wZ>([^<]+)")
--      print("xyz=", x, y, z)
    if x and y and z then
      self:drawSpindle(tonumber(x), tonumber(y), tonumber(z))
      --self:setValue("Text", cmd)
    end
  end
  return msg
end


return Display:new 
    {
        --Font = "Vera:9",
        MinWidth = 40, MinHeight = 60,
        Style = "background-color: #ddd; width: free;",
    }