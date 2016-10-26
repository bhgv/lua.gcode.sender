
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

local msg_buffer = ""

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
      exec.sendmsg("sender","SINGLE")
      exec.sendmsg("sender","G21 G90")
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
      local buf, out, ln
      local lst = {}
      local ok, er, stat = false, false, false
      buf = PORT:read(256, 200)
      if msg_buffer and msg_buffer ~= "" then
        buf = msg_buffer .. "\n" .. buf
      end
      if buf ~= "" then
        out = ""
        repeat
          out = out .. buf
          buf = PORT:read(256, 100)
        until(buf == "")
        Log:msg("---------------------\n" .. out .. "\n=======================")
        for ln in string.gmatch(out, "([^\u{a}\u{d}]+)") do 
          --print(ln)
          --if ln ~= "" then
            table.insert(lst, ln) 
          --end
        end
      --print(#lst, lst[1])
        if lst[1]:match("<") then
          --self:status_parse(out)
          stat = true
          if lst[2] and lst[2]:match("ok") then
            ok = true
          end
          msg_buffer = table.concat(lst, "\n", 3)
        elseif lst[1]:match("error") then
          msg_buffer = table.concat(lst, "\n", 2)
          er = true
        elseif lst[1]:match("ok") then
          msg_buffer = table.concat(lst, "\n", 2)
          ok = true
        end
        
        --if msg_buffer ~= "" then print("--------------\nmsg_buffer =", msg_buffer) end
        
        return {
          msg = lst[1], --out,
          ok = ok,
          err = er,
          stat = stat,
          raw = out,
        }
      end
      return {
          ok = ok,
          err = er,
          stat = stat,
      }
    end,

    help = function(self)
      self:send("$$\n")
      local out
      repeat
        out = self:read()
      until(out.msg)
      
      return out
    end,

    go_xyz = function(self, dir)
      local cmd = "G91G0"
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
    
    status_query = function(self)
      self:send("?\n")
    end,
    
    status_parse = function(self, status)
      local s = status
      local fr, to, state, mx, my, mz, wx, wy, wz = 
            string.find(s,
              "<([^>,]*)," .. 
              "MPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*)," ..
              "WPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),?" ..
              "([^>]*)>"
            )
      local out
      out = {
        state = state,
        w = {x=wx, y=wy, z=wz,},
        m = {x=mx, y=my, z=mz,},
      }
      return out
    end,

}
