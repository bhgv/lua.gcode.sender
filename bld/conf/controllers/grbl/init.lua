
local exec = require "tek.lib.exec"


local rs232 = require('periphery').Serial
local PORT = nil

local lfs = require "lfs"

local status_mode = 3
local status_mask_choises = {
      [3] =   "<([^>,]*)," .. 
              "MPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*)," ..
              "WPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),?" ..
              "([^>]*)>",
      [15] =  "<([^>,]*)," .. 
              "MPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*)," ..
              "WPos:([+%-]?%d*%.%d*),([+%-]?%d*%.%d*),([+%-]?%d*%.%d*)," ..
              "Buf:([^,]+),RX:([^>]+)>",
}
local status_mask = status_mask_choises[3]


local read_timeout_choises = {
      [3] =   200,
      [15] =  50,
}
local read_timeout = read_timeout_choises[3]


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


local mk_flags = {
      Buf = nil,
      RX = nil,
}


local is_resp_handled = true
local oks = 0
local oks_max = 256



local function calc_mk_status(msg)
--    if msg and (msg.ok or msg.err) then oks = oks - 1 end
    
    if not is_resp_handled then
      if mk_flags.RX then
        is_resp_handled = tonumber(mk_flags.Buf) < 15 and tonumber(mk_flags.RX) < 2
      else
        is_resp_handled = oks < 1
      end
    end
    --print("calc_mk_status", msg.ok, msg.err, oks, is_resp_handled, msg.msg)

    return is_resp_handled and (msg.ok) -- or msg.err)
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
      is_resp_handled = false
      oks = oks + 1
      
      return ""
    end,

    read = function(self)
      local buf, out, ln
      local lst = {}
      local msg = {}
      local ln_1, ln, _
      local ok, er, stat = false, false, false
      buf = PORT:read(256, read_timeout) --200)
      --if buf then print("> ", buf) end
      if msg_buffer and msg_buffer ~= "" then
        if buf and buf ~= "" then
          buf = msg_buffer .. "\n" .. buf
        else 
          buf = msg_buffer
        end
      end
      if buf ~= "" then
        out = ""
        repeat
          out = out .. buf
          buf = PORT:read(256, 50)
          --if buf then print("... ", buf) end
        until(buf == "")
        --Log:msg("---------------------\n" .. out .. "\n=======================")
        for ln in string.gmatch(out, "([^\u{a}\u{d}]+)") do 
          --print(ln)
          if ln and ln ~= "" then
            table.insert(lst, ln) 
          end
        end
      --print(#lst, lst[1])
        if lst[1] then
          if lst[1]:match("^<") then
            --self:status_parse(out)
            stat = true
            ln_1 = lst[1]
            
            if lst[2] and lst[2]:match("^ok") then
              ok = true
              oks = oks - 1
              msg_buffer = table.concat(lst, "\n", 3)
            else
              msg_buffer = table.concat(lst, "\n", 2)
            end
            --table.remove(lst, 1)
          elseif lst[1]:match("^error") then
            msg_buffer = table.concat(lst, "\n", 2)
            ln_1 = lst[1]
            oks = oks - 1
            er = true
            --table.remove(lst, 1)
          else
            ln_1 = lst[1]
            --table.remove(lst, 1)
            
            local i = 1
            while i <= #lst do
              ln = lst[i]
              i = i + 1
              --table.remove(lst, 1)
              if ln:match("^ok") then
                ok = true
                --for _ in ln:gmatch("ok") do
                  oks = oks - 1
                --end
              else
                break
              end
            end
            msg_buffer = table.concat(lst, "\n", i)
            --print(msg_buffer)
          end
        
          --print("ln_1", ln_1)
          
          msg = {
            msg = ln_1, --lst[1], --out,
            ok = ok,
            err = er,
            stat = stat,
            raw = out,
          }
        else
          msg_buffer = table.concat(lst, "\n", 2)
        end
        --if msg_buffer ~= "" then print("--------------\nmsg_buffer =", msg_buffer) end
      end
      
      self.out_access = calc_mk_status(msg)
      
      --msg.ok = ok and self.out_access

      return msg
    end,

    help = function(self)
      self:send("$$\n")
      local out, _stat_mode
      local s = ""
      
      out = self:read()
      --repeat
      while not out.msg do
        out = self:read()
        --if out.raw then
        --  s = s .. out.raw
        --end
      end
      --until(out.msg)
      s = out.raw
      
      _stat_mode = s:match("%$10=(%d+)")
      
      if _stat_mode then
        status_mode = tonumber(_stat_mode)
        if status_mode ~= 15 then
          exec.sendmsg("sender", "SINGLE")
          exec.sendmsg("sender", "$10=15 (mode should be 15 for correct work)")
          status_mode = 15
        end
        status_mask = status_mask_choises[status_mode]
        read_timeout = read_timeout_choises[status_mode]
      end
      
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
      if oks < oks_max then
        self:send("?\n")
      end
    end,
    
    status_parse = function(self, status)
      local s = status
      local fr, to, state, mx, my, mz, wx, wy, wz, Buf, RX = 
            string.find(s, status_mask)
      
      mk_flags.Buf = Buf
      mk_flags.RX = RX
      
      --if Buf and RX then print("Buf =", Buf, ", RX =", RX) end
      
      local out
      out = {
        state = state,
        wX=wx, wY=wy, wZ=wz,
        mX=mx, mY=my, mZ=mz,
      }
      return out
    end,

}
