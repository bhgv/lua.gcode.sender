local ui = require "tek.ui"
local exec = require "tek.lib.exec"

--print(exec.getname())



return {
-- gthread = {},
-- icmd = 0,
 task = nil,

  start = function(self, param)
    --App:addCoroutine(
    self.task = exec.run 
    {
      taskname = "sender",
      abort = false,
      func = function()
        local exec = require "tek.lib.exec"
        
        local MKs = require "conf.controllers"
        local MK = nil
        
        
        local split = function(str, mask, cb_foo)
          local s 
          for s in str:gmatch(mask) do
            cb_foo(s)
          end
        end
        
        local display_rx = function(s) 
          exec.sendport("*p", "ui", "<PORT RX>" .. s) 
        end
        
        local display_rx_msg = function(s) 
          local t = "<PORT RX MSG>" .. s
          --print (t)
          exec.sendport("*p", "ui", t) 
        end
        
        local display_tx = function(s) 
          exec.sendport("*p", "ui", "<PORT TX>" .. s) 
        end
        
        --print(exec.getname())
        
        local icmd = 0
        local gthread = {}
        local cmd = ""
        local msg = nil
        
        local sthread = {}
        
        local state = "stop"
        
--        local rs232 = require('periphery').Serial
--        local PORT = nil
      
        while cmd ~= "SENDER_STOP" do
--          print("icmd, #trd = ", icmd, #gthread, PORT)
          if  
              MK ~= nil and 
              (
                (#gthread > 0 and state == "run") or 
                (#sthread > 0 and state == "single")
              )
          then
            if state == "single" then
              --cmd = sthread[#sthread]
              cmd = table.remove(sthread, #sthread)
              if #sthread == 0 then
                state = "stop"
              end
            else
              icmd = icmd + 1
              --cmd = gthread[ icmd ]
              cmd = table.remove(gthread, 1)
              
              exec.sendport("*p", "ui", "<CMD GAUGE POS>" .. icmd)
            end
            
            display_tx(cmd)
            MK:send(cmd .. '\n')
          
            local out = MK:read()
            split(out, "[^\n]+", display_rx)
            --print(out)
            
            msg = exec.waitmsg(20)
          else
            msg = exec.waitmsg(2000)
          end
          
          if msg ~= nil then
            print("msg = ", msg)
            if msg == "PORT" then
              local mk = exec.waitmsg(2000)
              local prt = exec.waitmsg(2000)
              local bod = exec.waitmsg(2000)
              if mk ~= "" and prt ~= "" and bod ~= "" then
                MK = MKs:get(mk)
                if MK then
                  MK:open(prt, 0 + bod)
                  local out = MK:init()
                  split(out, "[^\n]+", display_rx_msg)
                end
              end
            elseif msg == "NEW" then
              gthread = {}
              icmd = 0
              state = "stop"
            elseif msg == "CALCULATE" then
              exec.sendport("*p", "ui", "<CMD GAUGE SETUP>" .. #gthread)
              --state = "run"
            elseif msg == "PAUSE" then
              state = "stop"
            elseif msg == "RESUME" then
              if state == "stop" then
                state = "run"
              end
            elseif msg == "STOP" then
              icmd = 0
              state = "stop"
            elseif msg == "SINGLE" then
              msg = exec.waitmsg(200)
              if state == "stop" then
                sthread[#sthread + 1] = msg
                state = "single"
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
    --self.gthread[#self.gthread] = cmd
  end

}
