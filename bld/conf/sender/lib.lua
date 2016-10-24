
local exec = require "tek.lib.exec"



return {
  split = function(self, str, mask, cb_foo)
          local s 
          for s in string.gmatch(str, mask) do
            cb_foo(self, s)
          end
        end,
        
  display_rx = function(self, s) 
          exec.sendport("*p", "ui", "<PORT RX>" .. s) 
        end,
        
  display_rx_msg = function(self, s) 
          local t = "<PORT RX MSG>" .. s
          --print (t)
          exec.sendport("*p", "ui", t) 
  end,
        
  display_tx = function(self, s) 
          exec.sendport("*p", "ui", "<PORT TX>" .. s) 
  end,

  cnc_stat = function(self, stat)
            exec.sendport("*p", "ui", "<STATUS><wX>" .. stat.w.x
                                        .. "<wY>" .. stat.w.y
                                        .. "<wZ>" .. stat.w.z
                                        .. "<mX>" .. stat.m.x
                                        .. "<mY>" .. stat.m.y
                                        .. "<mZ>" .. stat.m.z
            )
--          end
  end,
--[[
  cnc_status_read = function(self, MK)
              local out
              repeat
                out = MK:read()
              until(out.msg)
              --print ("msg=", out.msg)
              if out.stat then
                self:cnc_stat(MK:status_parse(out.msg))
              elseif out.ok or out.err then
                print("!!!!!!!!!!!!!!!!!!!: ", out.ok, out.err)
                --int_state = "m"
              end
              return out
  end,
]]
  cnc_read_parse = function(self, MK, state)
              local out = MK:read()
              if out.msg then
                if out.stat then
                  self:cnc_stat(MK:status_parse(out.msg))
                elseif out.ok or out.err then
                  if state == "run" then
                    self:split(out.msg, "[^\n]+", self.display_rx)
                  else
                    self:split(out.msg, "[^\n]+", self.display_rx_msg)
                  end
                end
                --print(out.msg)
              end
              return out
  end,

}