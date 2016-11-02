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
				require "conf.gui.plugins.head",
			    },
			},
			Group:new
			{
			    Children =
			    {
				require "conf.gui.plugins.plugpars",
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
