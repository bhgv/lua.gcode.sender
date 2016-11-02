local ui = require "tek.ui"
local List = require "tek.class.list"

--print(ui.ProgDir)

Plugins.Gui.PlugPars = ui.Group:new
{
  Orientation = "vertical",
--  Width = 75+120+32,
  Children = 
  {
--    StatPort,
--[[
    ui.Group:new
    {
--      Legend = "Port control",
      Children = 
      {
      },
    },
]]
  }
}


return Plugins.Gui.PlugPars
