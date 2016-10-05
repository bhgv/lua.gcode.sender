
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
      onPress = function(self)
    --		ui.ImageWidget.onPress(self)
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
      onPress = function(self)
        ui.ImageWidget.onPress(self)
        do_sparse()
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
      onPress = function(self)
        ui.ImageWidget.onPress(self)
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
      onPress = function(self)
    --		ui.ImageWidget.onPress(self)
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
      end
    },
  }
}

