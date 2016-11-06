local ui = require "tek.ui"
local exec = require "tek.lib.exec"

--print(exec.getname())



return {
 task = nil,

  start = function(self, param)
    self.task = exec.run 
    {
      taskname = "sender",
      abort = false,
      func = function()
        local exec = require "tek.lib.exec"
        
        local MKs = require "conf.controllers"
        local MK = nil
        
        Log = require "conf.log"
        
        local lib = require "conf.sender.lib"
        
        local state = "stop"
        local int_state = "s"
        
        local is_resp_handled = true
        local req_inc_cmd = false
        
        local stat_on = true
--        local cnc_stat_ctr = 0
        
        --print(exec.getname())
        
        local icmd = 1
        local gthread = {}
        local cmd = ""
        local msg = nil
        
        local sthread = {}
        
        oks = 0
        
        local oks_max = 3000
        
        local send_from = 1
        
        while cmd ~= "SENDER_STOP" do
          if MK then
            --print("int_state =", int_state, oks)
            
            if int_state == "s" then
              if stat_on then
                if oks < oks_max then
                  MK:status_query()
                  oks = oks + 1
                end
                int_state = "rs"
              else
                int_state = "m"
              end
            elseif int_state == "r" or int_state == "rs" then
              local msg
            --  repeat
                msg = lib:cnc_read_parse(MK, state)
            --  until(msg.msg or int_state == "r")
              
              if msg and (msg.ok or msg.err) then oks = oks - 1 end
              
              if not is_resp_handled then
                is_resp_handled = --[[(msg.ok or msg.err) and]] oks < 1
              end
              
              if --[[msg and]] msg.ok and oks < 1 and req_inc_cmd then --or not msg.stat then
--                is_resp_handled = --[[(msg.ok or msg.err) and]] oks < 1
                
                --print(msg.ok, state, oks)
                if --[[msg.ok and state == "run" and]] is_resp_handled then --oks < 1 then 
                  --is_resp_handled = (msg.ok or msg.err) --and oks < 1
                  
                  if icmd < #gthread then
                    icmd = icmd + 1 
                  else
                    state = "stop"
                    icmd = 1
                    exec.sendport("*p", "ui", "<MESSAGE>Stop")
                  end
                  req_inc_cmd = false
                end
              end
              
              if msg.err then
                exec.sendport("*p", "ui", "<MESSAGE>" 
                              .. msg.msg:match("([^\u{a}\u{d}]+)") 
                              .. " (ln: " .. (send_from + icmd - 1) .. ")"
                              )
                state = "stop"
                --stat_on = true
                oks = oks - 1
                icmd = icmd + 1
              end
              
--[[
              if int_state == "rs" then
                if msg.stat then
                  int_state = "m"
              --  else --if msg.ok or msg.err or not msg.msg then
              --    int_state = "s"
                end
              else
]]
              if msg.msg or int_state ~= "rs" then
                if msg.stat or int_state == "rs" then
                  int_state = "m"
                else --if msg.ok or msg.err or not msg.msg then
                  int_state = "s"
                end
              end
            
            elseif int_state == "m" then
              --print(#gthread, state)
              if
                (
                  (#gthread > 0 and state == "run") or 
                  (#sthread > 0 and state == "single")
                )
              then
                --print(is_resp_handled, oks, oks_max)
                if is_resp_handled and oks < oks_max then
                  if state == "single" then
                    --cmd = sthread[#sthread]
                    cmd = table.remove(sthread, #sthread)
                    if #sthread == 0 then
                      state = "stop"
                    end
                  else
                    --icmd = icmd + 1
                    cmd = '(' .. (send_from + icmd - 1) .. ') ' .. gthread[ icmd ]
                    --cmd = table.remove(gthread, 1)
                    
                    exec.sendport("*p", "ui", "<CMD GAUGE POS>" .. icmd)
                  end
                  
                  lib:display_tx(cmd)
                  
                
                  --if cmd == nil then
                  --  cmd = ""
                  --end
                  
                  MK:send(cmd .. '\n')
                  --Log:msg(icmd .. ", " .. tostring(is_resp_handled) .. ", m cmd: " .. cmd)
                  
                  oks = oks + 1
                  
                  is_resp_handled = false
                  req_inc_cmd = true
                end
                
                int_state = "r"
              else
                int_state = "s"
              end
            end
          end
          
          msg = exec.waitmsg(20)
          
          if msg ~= nil then
            Log:msg("msg = " .. msg)
            if msg == "PORT" then
              local mk = exec.waitmsg(2000)
              local prt = exec.waitmsg(2000)
              local bod = exec.waitmsg(2000)
              if mk ~= "" and prt ~= "" and bod ~= "" then
                MK = MKs:get(mk)
                if MK then
                  if MK:open(prt, 0 + bod) then
                    local out = MK:init()
                    lib:split(out.raw, "[^\u{a}\u{d}]+", lib.display_rx_msg)
                    exec.sendport("*p", "ui", "<MESSAGE>Connected to " .. prt .. ", " .. bod)
                  else
                    MK = nil
                    exec.sendport("*p", "ui", "<MESSAGE>Can't connect to " .. prt)
                  end
                end
              end
            elseif msg == "NEW" then
              gthread = {}
              icmd = 1
              state = "stop"
              exec.sendport("*p", "ui", "<MESSAGE>Stop")
            elseif msg == "CALCULATE" then
              exec.sendport("*p", "ui", "<CMD GAUGE SETUP>" .. #gthread)
              --state = "run"
            elseif msg == "PAUSE" then
              MK:pause()
              state = "stop"
              exec.sendport("*p", "ui", "<MESSAGE>Pause")
            elseif msg == "FILL" then
              stat_on = false
            elseif msg == "RESUME" then
              stat_on = true
              MK:resume()
              if state == "stop" then
                state = "run"
                exec.sendport("*p", "ui", "<MESSAGE>Run")
              end
            elseif msg == "STOP" then
              icmd = 1
              state = "stop"
              exec.sendport("*p", "ui", "<MESSAGE>Stop")
            elseif msg == "SINGLE" then
              msg = exec.waitmsg(200)
              if state == "stop" then
                sthread[#sthread + 1] = msg
                state = "single"
              end
            elseif msg == "SENDFROM" then
              msg = exec.waitmsg(200)
              if state == "stop" and msg then
                send_from = tonumber(msg)
              end
            else
              gthread[#gthread + 1] = msg
              --exec.sendport("main", "ui", "<CMD GAUGE SETUP 2>" .. #gthread)
              cmd = msg
            end
          end
        end
      end
    }
  end,

  newcmd = function(self, cmd)
    while cmd and not exec.sendmsg("sender", cmd) do
--      print("resend:", cmd)
    end
--    print("sent:", cmd)
  end

}
