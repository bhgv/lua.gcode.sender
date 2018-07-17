local ui = require "tek.ui"

--print(ui.ProgDir)


return ui.Group:new
{
  Children =
  {
    require "conf.gui.common.panel_file",
    MK and MK.FileButtons_add,
  },
}


