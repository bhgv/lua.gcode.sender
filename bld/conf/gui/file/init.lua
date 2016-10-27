local ui = require "tek.ui"
local Group = ui.Group

--local display = dofile("conf/gui/display.lua")

return		Group:new -- file
		{
		    Orientation = "vertical",
		    Children =
		    {
			Group:new
			{
			    Orientation = "horisontal",
			    Children =
			    {
				require "conf.gui.file.fopen",
			    },
			},
			Group:new
			{
			    Children =
			    {
				require "conf.gui.file.popen",
				ui.Handle:new {  },
				ui.Group:new 
				{
				    Children =
				    {
					DisplayBlock,
				    }
				},
			    },
			}
		    }
		}
