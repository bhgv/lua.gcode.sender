
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
  Home_path = os.getenv("PWD"),
  Plugins_path = os.getenv("PWD") .. "/conf/plugins",
  Plugins = {
    Groups = {
      Stuff = {},
    },
  },
  
  DispScale = 100,
  AutoRedraw = true,
  DisplayMode = "drag",
  DisplayProection = "xy",
  screenShift = {x=0, y=0,}
}

Plugins = {
  Gui = {
    Headers = {},
    PlugPars = {},
  },
}

GFilters = {
}

local plugin_sys = require "conf.utils.plugin_system_engine"

plugin_sys:collect_plugins()


GUI = require "conf.gui"

