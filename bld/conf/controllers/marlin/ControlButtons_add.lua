local ui = require "tek.ui"


return ui.Group:new
{
  Children =
  {
    ui.Button:new{Text="Emergency stop (M112)",
      onClick=function(self) ui.Button.onClick(self); Sender:newcmd("EMERGENCY") end},
  },
}
