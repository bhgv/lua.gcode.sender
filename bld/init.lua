

db = require "tek.lib.debug"
--db.level = db.INFO

Log = require "conf.log"

rs232 = require('periphery').Serial

PORT = nil

--ui = require "tek.ui"
--Visual = require "tek.lib.visual" --ui.loadLibrary("visual", 4)
--print ("Visual", Visual)


Sender = require("conf.sender")
Sender:start()


Flags = {
  DispScale = 100,
  AutoRedraw = true,
  DisplayMode = "select",
  screenShift = {x=0, y=0,}
}


GUI = require "conf.gui"

