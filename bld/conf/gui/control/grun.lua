
local ui = require "tek.ui"

--print(ui.ProgDir)

local ico_home = ui.loadImage("conf/icons/home32.ppm")
local ico_start = ui.loadImage("conf/icons/start32.ppm")
local ico_pause = ui.loadImage("conf/icons/pause32.ppm")
local ico_stop = ui.loadImage("conf/icons/stop32.ppm")

return ui.Group:new
{
  Children = 
  {
    ui.ImageWidget:new 
    {
      Image = ico_home,
      Width = 32,
      Height = 32,
      Mode = "button",
      Style = "padding: 2",
      onClick = function(self)
    --		ui.ImageWidget.onClick(self)
          Sender:newcmd('$H')
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
      end
    },
    ui.ImageWidget:new 
    {
      Image = ico_start,
      Width = 32,
      Height = 32,
      Mode = "button",
      Style = "padding: 2",
      onClick = function(self)
        ui.ImageWidget.onClick(self)
        if MKstate == "STOP" then
          do_sparse()
          Sender:newcmd("RESUME")
          MKstate = "RUN"
        elseif MKstate == "PAUSE" then
          Sender:newcmd("RESUME")
          MKstate = "RUN"
        end
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
      end
    },
    ui.ImageWidget:new 
    {
      Image = ico_pause,
      Width = 32,
      Height = 32,
      Mode = "button",
      Style = "padding: 2",
      --IsPaused = false,
      onClick = function(self)
        ui.ImageWidget.onClick(self)
        local cmd
        if MKstate == "PAUSE" then
          cmd = "RESUME"
          MKstate = "RUN"
          --self.IsPaused = false
        elseif MKstate == "RUN" then
          cmd = "PAUSE"
          MKstate = "PAUSE"
          --self.IsPaused = true
        end
        Sender:newcmd(cmd)
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
      end
    },
    ui.ImageWidget:new 
    {
      Image = ico_stop,
      Width = 32,
      Height = 32,
      Mode = "button",
      Style = "padding: 2",
      onClick = function(self)
    		ui.ImageWidget.onClick(self)
        if MKstate == "RUN" or MKstate == "PAUSE" then
          Sender:newcmd("STOP")
          Sender:newcmd("CALCULATE")
          MKstate = "STOP"
        end
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
      end
    },
  }
}

