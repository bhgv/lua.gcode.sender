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
        
        local display_tx = function(s) 
          exec.sendport("*p", "ui", "<PORT TX>" .. s) 
        end
        
        
        --print(exec.getname())
        
        local icmd = 0
        local gthread = {}
        local cmd = ""
        local msg = nil
        
        local state = 0
        
--        local rs232 = require('periphery').Serial
--        local PORT = nil
      
        while cmd ~= "STOP" do
--          print("icmd, #trd = ", icmd, #gthread, PORT)
          if icmd < #gthread and MK ~= nil and state == 1 then
            icmd = icmd + 1
            cmd = gthread[ icmd ]
            
            exec.sendport("*p", "ui", "<CMD GAUGE POS>" .. icmd)
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
            --print("msg = ", msg)
            if msg == "PORT" then
              local mk = exec.waitmsg(2000)
              local prt = exec.waitmsg(2000)
              local bod = exec.waitmsg(2000)
              if mk ~= "" and prt ~= "" and bod ~= "" then
                MK = MKs:get(mk)
                if MK then
                  MK:open(prt, 0+bod)
                  local out = MK:init()
                  split(out, "[^\n]+", display_rx)
                end
              end
            elseif msg == "NEW" then
              gthread = {}
              icmd = 0
              state = 0
            elseif msg == "CALCULATE" then
              exec.sendport("*p", "ui", "<CMD GAUGE SETUP>" .. #gthread)
              state = 1
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
    while not exec.sendmsg("sender", cmd) do
--      print("resend:", cmd)
    end
--    print("sent:", cmd)
    --self.gthread[#self.gthread] = cmd
  end

}
