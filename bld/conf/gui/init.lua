
--local ui = require "tek.ui"
local exec = require "tek.lib.exec"

--[[
return exec.run (
    {
      taskname = "gui",
      abort = false,
      func = 
      function()
]]
local exec = require "tek.lib.exec"


local ui = require "tek.ui"


ports = {}
bauds = {}

f = io.lines("conf/ports.txt")
repeat
    p = f(); if p then table.insert(ports, {{p}} ) end
until(p == nil)

f = io.lines("conf/bauds.txt")
repeat
    p = f(); if p then table.insert(bauds, {{p}} ) end
until(p == nil)



gLstWdgtM = ui.Lister:new
					{
						--Id = "the-list",
						SelectMode = "multi",
--						ListObject = gcmdLst,
            
						onSelectLine = function(self)
							ui.Lister.onSelectLine(self)
							local line = self:getItem(self.SelectedLine)
							if line then
                App:getById("gedit"):setValue("Text", line[1][2])
								--self.Window:setRecord(line[1])
							end
						end,
					}

local Group = ui.Group
local Slider = ui.Slider
local Text = ui.Text

local L = ui.getLocale("tekui-demo", "schulze-mueller.de")




--gparser = require "gcodeparser"

require "conf.gparser"

require "conf.gui.common"


MKs = require "conf.controllers"
MK = nil
MKStep = 10
MKstate = nil


App = ui.Application:new {
--      AuthorStyleSheets = "gradient", --"klinik", --"desktop" --
      AuthorStyleSheets = "klinik", --"desktop" --
}


local window = ui.Window:new
{
    Orientation = "vertical",
    Width = 1024,
    MinWidth = 600,
    MinHeight = 400,
    MaxWidth = "none", 
    MaxHeight = "none",
    Title = "lua.gcode.sender",
    Status = "hide",
    HideOnEscape = true,
    SizeButton = true,
    Children =
    {
      ui.PageGroup:new
      {
        PageCaptions = { "_File", "_Control", 
                      --"_Plugins", 
                      "_Edit", "_Terminal" },
        Style = "font:Vera/b:18;",
        Children =
        {
          require("conf.gui.file"),
          require("conf.gui.control"),
          require("conf.gui.edit"),
          require("conf.gui.terminal"),
        },
      },
  
      ui.Gauge:new
      {
        Min = 0,
        Max = 1,
        Value = 0,
--	      Id = "gauge-thresh",
--	      Orientation = "horisontal",
        Width = "free",
        Height = 5, --"auto",
      
        show = function(self)
											ui.Gauge.show(self)
											self.Application:addInputHandler(ui.MSG_USER, self, self.msgUser)
										end,
        hide = function(self)
											ui.Gauge.hide(self)
											self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
										end,
        msgUser = function(self, msg)
											local ud = msg[-1]
                      --print(ud)
                      local max = ud:match("<CMD GAUGE SETUP>(%d+)")
                      if max ~= nil then
                        --print("max=" .. max)
                        self:setValue("Max", 0+max)
                        self:setValue("Value", 0)
                      else
                        local pos = ud:match("<CMD GAUGE POS>(%d+)")
                        if pos ~= nil then
                          --print("pos=" .. pos)
                          self:setValue("Value", 0+pos)
                        end
                      end
											--self:setValue("Text", userdata)
											return msg
										end
      },

      ui.Text:new
      {
        Id = "status main",
--	      Orientation = "horisontal",
--	      Width = "free",
--	       Height = 5, --"auto",
      },

    }
}


ui.Application.connect(window)
App:addMember(window)
window:setValue("Status", "show")
App:run()

return 0
