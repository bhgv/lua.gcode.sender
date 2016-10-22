
--gparser = require "gcodeparser"


--[[
gp = gparser
--print(gp.do_parse)
f = io.open("/home/orangepi/el/tst_pars.gcode")
t = f:read("*a")
o = gp:do_parse(t)

print(t)

for i = 1,#o do
  print(o[i])
end
]]

db = require "tek.lib.debug"
--db.level = db.INFO

--ui = require "tek.ui"
rs232 = require('periphery').Serial

PORT = nil

ui = require "tek.ui"
Visual = require "tek.lib.visual" --ui.loadLibrary("visual", 4)
print ("Visual", Visual)

--GUI = require "conf.gui"


Sender = require("conf.sender")
Sender:start()

Flags = {
}

--[[
ports = {}
bauds = {}

f = io.lines("conf/ports.txt")
repeat
    p = f(); if p then table.insert(ports, {{p}} ) end
until(p == nil)

f = io.lines("conf/bauds.txt")
repeat
    p = f(); if p then table.insert(bauds, {{p}} ) end
until(p == nil)
]]




--[[
f = io.open("conf/ports.txt", "r")
repeat
p = f:read("*a")
table.insert(ports, p)
print(p)
until(p == nil)
f:close()

print(ports)
]]

GUI = require "conf.gui"

--[[
ui.Application:new
{
    Children =
    {
	ui.Window:new
	{
	    Title = "Hello",
	    HideOnEscape = true,
	    Children =
	    {
		ui.Button:new
		{
		    Text = "_Hello, World!",
		    onClick = function(self)
			print "Hello, World!"
		    end
		}
	    }
	}
    }
}:run()
]]

