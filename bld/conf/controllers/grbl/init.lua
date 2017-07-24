
local exec = require "tek.lib.exec"

--local rs232 = require('periphery').Serial
local rs232 = require('rs232.luars232')
--print ("rs232", rs232)
--print ("luars232", luars232)
rs232 = luars232
--for k,v in pairs(rs232) do print(k,v) end

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


local rs232_read_len = 255 -- read one byte
local rs232_read_timeout = 100 -- in miliseconds


local read_timeout_choises = {
      [3] =   200,
      [15] =  50,
}
local read_timeout = read_timeout_choises[3]


local ports = {
    "/dev/ttyUSB0",
    "/dev/ttyUSB1",
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



local _read_port = function(read_timeout)
  local s = ""
  local err, data_read, size --= PORT:read(rs232_read_len, rs232_read_timeout)
  data_read = ""
  
  repeat
--      s = s .. data_read
      err, data_read, size = PORT:read(rs232_read_len, read_timeout or rs232_read_timeout)
      
      if err == rs232.RS232_ERR_TIMEOUT then
        return nil
      elseif err ~= rs232.RS232_ERR_NOERROR then
        print("e!", rs232.error_tostring(err), s)
        return s
      else
        s = s .. data_read
      end
--	  assert(err == rs232.RS232_ERR_NOERROR)
  until(data_read == nil or size < rs232_read_len)

--  print("rd>", s)
  return s
end

local _write_port = function(s)
--  print("wr>", s)
  -- write with timeout
  local err, len = PORT:write(s) --, rs232_read_timeout)
  assert(err == rs232.RS232_ERR_NOERROR)
end






return {
    out_access = false,
    
    info = function(self)
      return {
            name = "grbl",
            ports = ports,
            bauds = bauds,
      }
    end,
    
    open = function(self, port_name, speed)
      local attr = lfs.attributes(port_name)
      if attr then

		local out = io.stderr

		-- open port
		local e, p = rs232.open(port_name)
		if e ~= rs232.RS232_ERR_NOERROR then
			-- handle error
			out:write(string.format("can't open serial port '%s', error: '%s'\n",
					port_name, rs232.error_tostring(e)))
			--return
			p = nil
		else
		    --print (p)
--			for k,v in pairs(p) do print(k,v) end
			-- set port settings
			assert(p:set_baud_rate(rs232.RS232_BAUD_115200) == rs232.RS232_ERR_NOERROR)
			assert(p:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
			assert(p:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
			assert(p:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
			assert(p:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)

			out:write(string.format("OK, port open with values '%s'\n", tostring(p)))
		end


        PORT = p --rs232(port, speed)
        --print(PORT)
        
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
--      PORT:write("!")
      _write_port("!")
    end,

    resume = function(self)
--      PORT:write("~")
      _write_port("~")
    end,

    send = function(self, cmd)
--      PORT:write(cmd)
      _write_port(cmd)
      
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
--      buf = PORT:read(256, read_timeout) --200)
      buf = _read_port(read_timeout)
      --if buf then print("> ", buf) end
      if msg_buffer and msg_buffer ~= "" then
        if buf and buf ~= "" then
          buf = msg_buffer .. "\n" .. buf
        else 
          buf = msg_buffer
        end
      end
      if buf and buf ~= "" then
        out = ""
        repeat
          out = out .. buf
--          buf = PORT:read(256, 50)
          buf = _read_port(50)
          --if buf then print("... ", buf) end
        until((not buf) or buf == "")
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
        w = {x=wx, y=wy, z=wz,},
        m = {x=mx, y=my, z=mz,},
      }
      return out
    end,

}
