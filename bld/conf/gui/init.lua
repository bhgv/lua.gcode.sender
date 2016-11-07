
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

--[[
gLstWdgtM = ui.Lister:new
					{
						--Id = "the-list",
            Id = "editor cmd list",
						SelectMode = "single", --"multi",
--						ListObject = gcmdLst,
            
						onSelectLine = function(self)
							ui.Lister.onSelectLine(self)
              local lineno = self.SelectedLine
							local line = self:getItem(lineno)
							if line then
                App:getById("gedit"):setValue("Text", line[1][2])
								--self.Window:setRecord(line[1])
                --self.sel_line_no
							end
						end,
            
            setup = function(self, app, win)
              ui.Lister.setup(self, app, win)
              --print(app, win)
              app:addInputHandler(ui.MSG_USER, self, self.msgUser)
            end,
            
            cleanup = function(self)
              ui.Lister.cleanup(self)
              self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
            end,
            
            msgUser = function(self, msg)
              local ud = msg[-1]
              cmd = ud:match("<MESSAGE>error:[^%(]*%(ln%: (%d+)%)")
              if cmd ~= nil and _G.Flags.SendFrom and _G.Flags.SendTo then
                self:setValue("SelectedLine", tonumber(cmd))
              end
              return msg
            end,
					}
          
initialiseEditor = function()
  local NumberedList = require "conf.gui.classes.numberedlist"

  local i,ln
  local lst = {}
  
  for i,ln in ipairs(GTXT) do
    table.insert(lst, {{ "", ln }})
  end
  
  gLstWdgtM:setList(NumberedList:new { Items = lst })
  
  App:getById("send to"):setValue("Text", tostring(#GTXT))
  App:getById("send from"):setValue("Text", "1")
end
]]



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
    Height = 600,
    MinWidth = 800,
    MinHeight = 600,
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
        PageCaptions = { 
                      "_File", 
                      "_Control", 
                      "_Plugins", 
                      "_Editor", 
                      "_Terminal",
                      "_Showroom"},
        Style = "font:Vera/b:18;",
        Children =
        {
          require("conf.gui.file"),
          require("conf.gui.control"),
          require("conf.gui.plugins"),
          require("conf.gui.edit"),
          require("conf.gui.terminal"),
          require("conf.gui.showroom"),
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

      ui.Group:new
      {
        Children =
        {
          ui.Text:new
          {
            Id = "status main",
            Style = "font:/b:10; color:gray;", --olive;", --navy;",
      --	      Orientation = "horisontal",
      --	      Width = "free",
      --	       Height = 5, --"auto",
          },
          ui.Text:new
          {
            Style = "font:/b:10; color:gray;", --olive;", --navy;",
            Text = "Not Connected",
            setup = function(self, app, win)
											ui.Text.setup(self, app, win)
											app:addInputHandler(ui.MSG_USER, self, self.msgUser)
										end,
            cleanup = function(self)
											ui.Text.cleanup(self)
											self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
										end,
            msgUser = function(self, msg)
                      local ud = msg[-1]
                      --print("ud", ud)
                      local cmd = ud:match("<MESSAGE>(.*)")
                      if cmd then
                        --print("cmd=" .. cmd)
                        if 
                          cmd:match("^error:") 
                        then
                          MKstate = "PAUSE"
                        elseif 
                          cmd:match("^Pause")
                        then
                          MKstate = "PAUSE"
                          cmd = "status: " .. cmd
                        elseif 
                          cmd:match("^Stop")
                        then
                          MKstate = "STOP"
                          cmd = "status: " .. cmd
                        elseif 
                          cmd:match("^Run")
                        then
                          MKstate = "RUN"
                          cmd = "status: " .. cmd
                        end
                        
                        self:setValue("Text", cmd)
                      end
                      return msg
                    end,

          },
        }
      }

    }
}


ui.Application.connect(window)
App:addMember(window)
window:setValue("Status", "show")
App:run()

return 0
