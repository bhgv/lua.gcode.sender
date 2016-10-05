local ui = require "tek.ui"
local exec = require "tek.lib.exec"

print(exec.getname())

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
        
        --print(exec.getname())
        
        local icmd = 0
        local gthread = {}
        local cmd = ""
        local msg = nil
        
        local state = 0
        
        local rs232 = require('periphery').Serial
        local PORT = nil
      
        while cmd ~= "STOP" do
--          print("icmd, #trd = ", icmd, #gthread, PORT)
          if icmd < #gthread and PORT ~= nil and state == 1 then
            icmd = icmd + 1
            cmd = gthread[ icmd ]
            cmd = cmd .. "\n"
            --print(icmd, cmd)
            exec.sendport("*p", "ui", "<CMD GAUGE POS>" .. icmd)
            exec.sendport("*p", "ui", "<PORT TX>" .. cmd)
            PORT:write(cmd)
          
            local buf, out
            out = ""
            repeat
              buf = PORT:read(256, 50)
              out = out .. buf
--              print(string.format("read %d bytes: _%s_", #buf, buf))
            until(buf == "" and out ~= "")
            exec.sendport("*p", "ui", "<PORT RX>" .. out)
            --print(out)
            
            msg = exec.waitmsg(20)
          else
            msg = exec.waitmsg(2000)
          end
          
          if msg ~= nil then
            --print("msg = ", msg)
            if msg == "PORT" then
              msg = exec.waitmsg(2000)
              if msg ~= "" then
                PORT = rs232(msg, 115200) --"/dev/ttyUSB0", 115200)
--              PORT:write("Hello World!")
                PORT:write("$$\n")
              -- Read up to 128 bytes with 500ms timeout
                local buf, out
                out = ""
                repeat
                  buf = PORT:read(256, 500)
                  out = out .. buf
                until(buf == "" and out ~= "")
                --print(out)
                local foo=out:gmatch("[^\n]+")
                local s = ""
                repeat
                  exec.sendport("*p", "ui", "<PORT RX>" .. s)
                  s = foo()
                until(s == nil)
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
    --)
  end,

  newcmd = function(self, cmd)
    while not exec.sendmsg("sender", cmd) do
--      print("resend:", cmd)
    end
--    print("sent:", cmd)
    --self.gthread[#self.gthread] = cmd
  end

}
