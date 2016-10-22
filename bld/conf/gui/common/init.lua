
ui = require "tek.ui"


symBut = function(txt, foo, color)
  local style = "font:ui-icons:20; width:24;"
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


Display = require "conf.gui.display"




local w

StatPort = ui.Group:new
{
  Orientation = "vertical",
  Children = 
  {
    ui.Text:new
    {
      Class = "caption",
      Width = 150,
      Text = "Not Connected",
    },
    
    ui.Group:new
    {
      Rows = 3,
      Columns = 4,
      Children = 
      {
          ui.Text:new{Class = "caption",Width=60, Text="WPos:"},
          ui.Text:new{Width=60}, ui.Text:new{Width=60}, ui.Text:new{Width=60}, 
          ui.Text:new{Class = "caption",Width=60, Text="MPos:"},
          ui.Text:new{Width=60}, ui.Text:new{Width=60}, ui.Text:new{Width=60}, 
          ui.Text:new{Class = "caption",Width=60, },
          ui.Button:new{Width=60, Text="x = 0"}, ui.Button:new{Width=60, Text="y = 0"}, ui.Button:new{Width=60, Text="z = 0"}, 
      },
    },

  }
}

