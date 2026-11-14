
local exec = require "tek.lib.exec"


local rs232 = require('periphery').Serial
local PORT = nil

local lfs = require "lfs"

local read_timeout = 50

local ports = {
    "/dev/ttyUSB0",
    "/dev/ttyUSB1",
    "/dev/ttyUSB2",
    "/dev/ttyUSB3",
    "/dev/ttyUSB4",
}

local bauds = {
    115200,
}

local msg_buffer = ""


-- Use send/response flow control for both protocol generations. Buffer
-- telemetry has different meanings in 0.9 and 1.1 and can arrive late.
local oks = 0
local wco

local function vector(s, name)
  local values = s:match(name .. ":([^|>]+)")
  if not values then return end
  local x, y, z = values:match("^([^,]+),([^,]+),([^,]+)")
  x, y, z = tonumber(x), tonumber(y), tonumber(z)
  if x and y and z then return {x, y, z} end
end

return {
    out_access = false,
    
    StatPort_contents = require "conf.controllers.grbl.StatPort_contents",
    
    info = function(self)
      return {
            name = "grbl",
            ports = ports,
            bauds = bauds,
      }
    end,

    open = function(self, port, speed)
      local attr = lfs.attributes(port)
      if attr then
        PORT = rs232(port, speed)
        self.out_access = PORT ~= nil
        
        oks = 0
        msg_buffer = ""
        wco = nil
        
        return PORT
      else
        return false
      end
    end,

    init = function(self)
      local out = self:help()
      exec.sendmsg("sender","NEW")
      exec.sendmsg("sender","CALCULATE")
--      exec.sendmsg("sender","SINGLE")
--      exec.sendmsg("sender","$C")
      exec.sendmsg("sender","SINGLE")
      exec.sendmsg("sender","G21 G90")
      return out
    end,

    stop = function(self)
    end,

    pause = function(self)
      PORT:write("!")
    end,

    resume = function(self)
      PORT:write("~")
    end,

    send = function(self, cmd)
      PORT:write(cmd)
      
      self.out_access = false
      oks = oks + 1
      
      return ""
    end,

    read = function(self)
      local ln, rest = msg_buffer:match("^([^\r\n]*)[\r\n]+(.*)$")
      if not ln then
        msg_buffer = msg_buffer .. (PORT:read(256, read_timeout) or "")
        ln, rest = msg_buffer:match("^([^\r\n]*)[\r\n]+(.*)$")
      end
      if not ln then return {} end
      msg_buffer = rest

      local msg = {msg = ln, raw = ln .. "\n"}
      if ln == "ok" or ln:match("^error:") then
        oks = math.max(0, oks - 1)
        msg.ok = ln == "ok"
        msg.err = not msg.ok
        self.out_access = oks == 0
      elseif ln:match("^ALARM:") then
        msg.err = true
        oks = 0
        self.out_access = false
      elseif ln:match("^Grbl") then
        self.version = ln:match("^Grbl%s+([^%s]+)")
        wco = nil
        oks = 0
        self.out_access = true
        msg.err = true -- A controller reset invalidates the current stream.
      elseif ln:match("^<.*>$") then
        msg.stat = true
      end
      return msg
    end,

    help = function(self)
      self:send("$$\n")
      local text = ""
      local out = {}
      -- A disconnected controller must not block the sender forever.
      for i = 1, 100 do
        out = self:read()
        if out.raw then text = text .. out.raw end
        if out.ok or (out.err and not out.msg:match("^Grbl")) then break end
      end
      return {msg = text, raw = text}
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
          Sender:newcmd("SINGLE")
          Sender:newcmd(cmd)
      end
    end,
    
    set_xyz = function(self, dir)
      local cmd = "G92 "
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
          Sender:newcmd("SINGLE")
          Sender:newcmd(cmd)
      end
    end,
    
    status_query = function(self)
      -- Realtime bytes have no ok response and must not change oks.
      PORT:write("?")
    end,

    status_parse = function(self, status)
      local state = status:match("^<([^,|>]+)")
      if not state then return {} end
      local m = vector(status, "MPos")
      local w = vector(status, "WPos")
      local offset = vector(status, "WCO")
      if offset then wco = offset end
      if wco then
        if m and not w then
          w = {m[1] - wco[1], m[2] - wco[2], m[3] - wco[3]}
        elseif w and not m then
          m = {w[1] + wco[1], w[2] + wco[2], w[3] + wco[3]}
        end
      end
      return {
        state = state,
        wX = w and w[1], wY = w and w[2], wZ = w and w[3],
        mX = m and m[1], mY = m and m[2], mZ = m and m[3],
      }
    end,

}
