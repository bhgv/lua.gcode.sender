
local ui = require "tek.ui"
local Frame = ui.Frame

local exec = require "tek.lib.exec"

local floor = math.floor --tointeger 

local int = function(a) return math.tointeger(floor(a)) end

local S60 = math.sin(math.pi*2/3)
local C60 = math.cos(math.pi*2/3)



return {
  setup = function (self, app, win)
    ui.Frame.setup(self, app, win)
    --print(app, win)
    app:addInputHandler(ui.MSG_USER, self, self.msgUser)
  end,

  cleanup = function (self)
    ui.Frame.cleanup(self)
    self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
  end,


  show = function (self, drawable)
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
  end,

  hide = function (self)
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
  end,

  
}