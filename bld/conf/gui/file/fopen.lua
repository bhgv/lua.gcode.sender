local ui = require "tek.ui"

--print(ui.ProgDir)

local ads = MK and MK.FileButtons_add
if ads then
  if type(ads)=="function" then
    ads = ads()
  elseif type(ads)~="table" then
    ads = nil
  end
end

FilePanel_ads = ui.Group:new{Children={ads,},}

return ui.Group:new
{
  Children =
  {
    require "conf.gui.common.panel_file",
    FilePanel_ads,
  },
}


