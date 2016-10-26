local ui = require "tek.ui"

--local ico_popen = ui.loadImage("conf/icons/serial32.ppm")

local Txt = function(txt) return ui.Text:new{Class = "caption",Style="color:gray;",Text=txt} end
local But = function(txt, atr) 
    local class = nil
    if txt == "" then class = "caption" end
    return ui.Button:new
    {Class = class, Text=txt, _atr = atr,
      Style="font:ui-icons:26; width:36; color:olive;",
      onClick = function(self)
        local x, y, z
        local d = self._atr
        local cmd = {x=nil, y=nil, z=nil}
        local step = 0 + self:getById("step"):getText()
        
        if MK ~= nil then
          if d == "x" then
            x = -step
          elseif d == "X" then
            x = step
          elseif d == "y" then
            y = -step
          elseif d == "Y" then
            y = step
          elseif d == "z" then
            z = -step
          elseif d == "Z" then
            z = step
          elseif d == "xy" then
            x = -step; y = -step
          elseif d == "Xy" then
            x = step; y = -step
          elseif d == "xY" then
            x = -step; y = step
          elseif d == "XY" then
            x = step; y = step
          elseif d == "step" then
            MKStep = step / 10
            self:getById("step"):setValue("Text", "" .. MKStep)
          elseif d == "Step" then
            MKStep = step * 10
            self:getById("step"):setValue("Text", "" .. MKStep)
          end
          
          MK:go_xyz{x=x, y=y, z=z}
        end
      end
    } 
end

return ui.Group:new
{
  Orientation = "vertical",
  Width = 75+120+32,
  Children = 
  {
    StatPort,
    ui.Group:new
    {
      Legend = "Moving by axis",
      Rows = 5,
      Columns = 6,
      Children = 
      {
        Txt("+Z"),          Txt(""),  Txt(""),            Txt("+Y"),          Txt(""),            Txt(""),
        But("\u{E037}","Z"),Txt(""),  But("", "xY"),      But("\u{E037}","Y"),But("", "XY"),      Txt(""),
        Txt("|"),           Txt("-X"),But("\u{E035}","x"),But("\u{e041}","0"),But("\u{E036}","X"),Txt("+X"),
        But("\u{E034}","z"),Txt(""),  But("", "xy"),      But("\u{E034}","y"),But("", "Xy"),      Txt(""),
        Txt("-Z"),          Txt(""),  Txt(""),            Txt("-Y"),          Txt(""),            Txt(""),
      },
    },
    ui.Group:new
    {
      Legend = "Move step size",
      Children = 
      {
        Txt("Step: "),
        But("\u{E0de}", "step"), 
        ui.Input:new
        {
          Id = "step",
          Text = "10.0",
          Width = 80,
        },
        But("\u{E0dd}", "Step"), 
      },
    },
  }
}

