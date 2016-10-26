
local ui = require "tek.ui"

--print(ui.ProgDir)


return ui.Group:new
{
  Orientation = "horisontal",
  Children = 
  {
    require "conf.gui.common.panel_file",
  }
}

