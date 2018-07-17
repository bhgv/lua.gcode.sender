local ui = require "tek.ui"

--print(ui.ProgDir)

local ads = MK and MK.ControlButtons_add
if ads then
  if type(ads)=="function" then
    ads = ads()
  elseif type(ads)~="table" then
    ads = nil
  end
end

ControlPanel_ads = ui.Group:new{Children={ads,},}

return ui.Group:new
{
  Children =
  {
    require "conf.gui.common.panel_run",
    ControlPanel_ads,
  },
}

