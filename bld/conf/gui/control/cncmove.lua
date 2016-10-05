local ui = require "tek.ui"
local List = require "tek.class.list"

print(ui.ProgDir)

local ico_popen = ui.loadImage("conf/icons/serial32.ppm")

return ui.Group:new
{
  Orientation = "vertical",
--  Width = 75+120+32,
  Children = 
  {
    StatPort,
    ui.Group:new
    {
	Rows = 3,
	Columns = 4,
	Children = 
	{
	    ui.Text:new{Class = "caption",Width=60, Text="WPos:"},
	    ui.Text:new{Width=60, Id="wpx"}, ui.Text:new{Width=60, Id="wpy"}, ui.Text:new{Width=60, Id="wpz"}, 
	    ui.Text:new{Class = "caption",Width=60, Text="MPos:"},
	    ui.Text:new{Width=60, Id="mpx"}, ui.Text:new{Width=60, Id="mpy"}, ui.Text:new{Width=60, Id="mpz"}, 
	    ui.Text:new{Class = "caption",Width=60, },
	    ui.Button:new{Width=60, Text="x = 0"}, ui.Button:new{Width=60, Text="y = 0"}, ui.Button:new{Width=60, Text="z = 0"}, 
	},
    },
  }
}

