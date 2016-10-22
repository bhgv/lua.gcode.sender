
local exec = require "tek.lib.exec"

local rs232 = require('periphery').Serial
local PORT = nil


local ports = {
    "/dev/ttyUSB0",
    "/dev/ttyUSB1",
}

local bauds = {
    115200,
}

return {
    info = function(self)
      return {
            name = "grbl",
            ports = ports,
            bauds = bauds,
      }
    end,

    open = function(self, port, speed)
      PORT = rs232(port, speed)
      return PORT ~= nil
    end,

    init = function(self)
      local out = self:help()
      exec.sendmsg("sender","NEW")
      exec.sendmsg("sender","CALCULATE")
      return out
    end,

    stop = function(self)
    end,

    pause = function(self)
    end,

    resume = function(self)
    end,

    send = function(self, cmd)
      PORT:write(cmd)
      return ""
    end,

    read = function(self)
      local buf, out
      out = ""
      repeat
        buf = PORT:read(256, 500)
        out = out .. buf
      until(buf == "" and out ~= "")
      --print(out)
      return out
    end,

    help = function(self)
      self:send("$$\n")
      return self:read()
    end,

    go_xyz = function(self, dir)
      local cmd = "G90G0"
      local x = dir.x
      local y = dir.y
      local z = dir.z

      if x then
          cmd = cmd .. "X" .. x
      end
      if y then
          cmd = cmd .. "Y" .. y
      end
      if z then
          cmd = cmd .. "Z" .. z
      end

      if x or y or z then
          --self:send(cmd)
          Sender:newcmd("SINGLE")
          Sender:newcmd(cmd)
      end
    end,
    
    get_status = function(self)
      self:send("?\n")
      local s = self:read()
      local fr, to, stat, mx, my, mz, wx, wy, wz = 
            string.find(s,
              "<([^>,]*)," .. 
              "MPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*)," ..
              "WPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),?" ..
              "([^>]*)>"
            )
      print (s)
      print (fr, to, "\nm = ",mx, my, mz, "\nw = ", wx, wy, wz)
      
      local out
      out = {
        state = stat,
        wrk = {x=wx, y=wy, z=wz,},
        mcn = {x=mx, y=my, z=mz,},
      }
      return out
    end,

}
