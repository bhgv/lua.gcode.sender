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
    StatPort,
    ui.Group:new
    {
	Children = 
	{
	    ui.Group:new
	    {
		--Orientation = "vertical",
		Columns = 2,
		Rows = 3,
		Children = 
		{
--		    ui.Group:new
--		    {
--			Orientation = "horisontal",
--			Children = 
--			{
			    ui.Text:new
			    {
				Class = "caption",
				Width = 75,
				Text = "Port:",
			    },
			    ui.PopList:new
			    {
				Id = "Port:",
				Width = 140,
				SelectedLine = 1,
				ListObject = List:new
				{
				    Items = ports
				}
			    },
--			}
--		    },
--		    ui.Group:new
--		    {
--			Orientation = "horisontal",
--			Children = 
--			{
			    ui.Text:new
			    {
				Class = "caption",
				Width = 75,
				Text = "Baud:",
			    },
--			    ui.Input:new
--			    {
--				Id = "Baud:",
--			    },
			    ui.PopList:new
			    {
				Id = "Baud:",
				Width = 140,
				SelectedLine = 1,
				ListObject = List:new
				{
				    Items = bauds
				}
			    },
--			}
--		    },
--		    ui.Group:new
--		    {
--			Orientation = "horisontal",
--			Children = 
--			{
			    ui.Text:new
			    {
				Class = "caption",
				Width = 75,
				Text = "Device:",
			    },
--			    ui.Input:new
--			    {
--				Id = "Dev:",
--			    },
			    ui.PopList:new
			    {
				Id = "Dev:",
				Width = 140,
				SelectedLine = 1,
				ListObject = List:new
				{
				    Items =
				    {
					{ { "grbl" } },
--					{ { "a shifted" } },
--					{ { "Scrollgroup" } },
				    }
				}
			    },
--			}
--		    },
		}
	    },
	    ui.ImageWidget:new 
	    {
		Image = ico_popen,
		Width = 32,
		Height = 32,
		Mode = "button",
		Style = "padding: 1",
--		ImageAspectX = 2,
--		ImageAspectY = 3,
		onPress = function(self)
			ui.ImageWidget.onPress(self)
			Sender:newcmd("PORT")
			Sender:newcmd("/dev/ttyUSB0")
			StatPort:setValue("Text", "Connected to /dev/ttyUSB0")
      --exec.sendmsg("sender", "PORT")
      --exec.sendmsg("sender", "/dev/ttyUSB0")
--[[
			if PORT == nil then
			    -- Open /dev/ttyUSB0 with baudrate 115200, and defaults of 8N1, no flow control
			    PORT = rs232("/dev/ttyUSB0", 115200)
--			    PORT:write("Hello World!")
			    PORT:write("$$\n")
			    -- Read up to 128 bytes with 500ms timeout
			    local buf
          repeat
            buf = PORT:read(128, 500)
            print(string.format("read %d bytes: _%s_", #buf, buf))
          until(buf == "")
          
          Sender:start()
			else
			    PORT:close()
			    PORT = nil
			end
]]
		end
	    },
	},
    },
  }
}

