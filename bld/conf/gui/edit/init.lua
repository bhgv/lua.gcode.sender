local ui = require "tek.ui"
local Group = ui.Group

return		Group:new -- edit
		{
		    Orientation = "vertical",
		    Children =
		    {
			Group:new
			{
			    Orientation = "horisontal",
			    Children =
			    {
				require "conf.gui.edit.etools",
			    },
			},
			Group:new
			{
			    Children =
			    {
				require "conf.gui.edit.cmdlst",
				ui.Handle:new { },
				ui.Group: new 
				{
				    Children =
				    {
					DisplayBlock,
				    }
				}
			    },
			}
		    }
		}
