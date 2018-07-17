local ui = require "tek.ui"

--print(ui.ProgDir)


return ui.Group:new
{
  Children =
  {
    require "conf.gui.common.panel_run",
    MK and MK.ControlButtons_add,
  },
}

