local ui = require "tek.ui"
local List = require "tek.class.list"

--print(ui.ProgDir)

local ico_new = ui.loadImage("conf/icons/new32.ppm")
local ico_popen = ui.loadImage("conf/icons/serial32.ppm")
local ico_save = ui.loadImage("conf/icons/save32.ppm")

return ui.Group:new
{
  Orientation = "vertical",
--  Width = 75+120+32,
  Children = 
  {
    ui.Group:new
    {
	Orientation = "vertical",
	Width = "free",
	Children = 
	{
	    ui.ListView:new
	    {
		VSliderMode = "auto",
		HSliderMode = "auto",
		Headers = { "N", "gcode commands" },
		Child = gLstWdgtM
	    },
	    ui.Input:new
	    {
		Id = "gedit",
	    },
	    ui.Group:new
	    {
		Children = 
		{
		    ui.Button:new
		    {
			Text = "New"
		    },
		    ui.Button:new
		    {
			Text = "Update"
		    },
		    ui.Button:new
		    {
			Text = "Delete"
		    },
		}
	    },
	},
    },
  }
}

