local ui = require "tek.ui"
local Group = ui.Group

--local display = dofile("conf/gui/display.lua")

return	Group:new -- control
	{
	    Orientation = "vertical",
	    Children =
	    {
		Group:new
		{
		    Children =
		    {
			require "conf.gui.control.grun",
		    },
		},
		Group:new
		{
		    Children =
		    {
			require "conf.gui.control.cncmove",
			ui.Handle:new {  },
			ui.Group:new 
			{
			    Children =
			    {
			        Display,
			    }
			},
		    },
		}
	    }
	}
