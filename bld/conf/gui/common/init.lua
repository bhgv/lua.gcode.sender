
ui = require "tek.ui"


symBut = function(txt, foo, color, isnosym)
  local font = ":18" --"Vera:18"
  --print (isnosym,txt)
  if not isnosym then
    font = "ui-icons:20"
  end
  
  local style = "font:" .. font .. "; width:24; color:olive;" --olive;" --navy;"
  local par = {}
--  if par.Style then
--    style = style .. par.Style
--  end
  par.Style = style
  par.Text = txt
  par.onClick = function(self)
    ui.Button.onClick(self)
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
    foo(self)
  end
  
  return ui.Button:new(par)
end


symButSm = function(txt, foo, color)
  local style = "font:ui-icons:12; width:12; color:olive;" --olive;" --navy;"
  local par = {}
--  if par.Style then
--    style = style .. par.Style
--  end
  par.Style = style
  par.Text = txt
  par.Class = "caption"
  par.onClick = function(self)
    ui.Button.onClick(self)
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
    foo(self)
  end
  
  return ui.Button:new(par)
end


require "conf.gui.common.display_block"



StatPort = ui.Group:new
{
  Orientation = "vertical",
  Legend = "Status",
--  Children = 
--  {
--  }
}

