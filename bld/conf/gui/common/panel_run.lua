
local ui = require "tek.ui"
local exec = require "tek.lib.exec"


return ui.Group:new
{
  Children = 
  {
    symBut(
      "\u{e078}",
      function(self)
          Sender:newcmd('SINGLE')
          Sender:newcmd('$H')
      end
    ),
    symBut(
      "\u{e093}",
      function(self)
        if MKstate == "STOP" then
          require("conf.gui.edit.actions").flush()
          local from = _G.Flags.SendFrom 
          local to = _G.Flags.SendTo 
          local prepared, err = pcall(do_sparse, from, to)
          if not prepared then
            self.Application:getById("status main"):setValue("Text", tostring(err))
            return
          end
          Sender:newcmd("RESUME")
          MKstate = "RUN"
--          exec.sendport(exec.getname(), "ui", "<MESSAGE>Run")
        elseif MKstate == "PAUSE" then
          Sender:newcmd("RESUME")
          MKstate = "RUN"
--          exec.sendport(exec.getname(), "ui", "<MESSAGE>Run")
        end
      end
    ),
    symBut(
      "\u{e092}",
      function(self)
        local cmd
        if MKstate == "PAUSE" then
          cmd = "RESUME"
          MKstate = "RUN"
          --exec.sendport(exec.getname(), "ui", "<MESSAGE>Run")
        elseif MKstate == "RUN" then
          cmd = "PAUSE"
          MKstate = "PAUSE"
          --exec.sendport(exec.getname(), "ui", "<MESSAGE>Pause")
        end
        Sender:newcmd(cmd)
      end
    ),
    symBut(
      "\u{e099}",
      function(self)
        if MKstate == "RUN" or MKstate == "PAUSE" then
          Sender:newcmd("STOP")
          Sender:newcmd("CALCULATE")
          MKstate = "STOP"
          --exec.sendport(exec.getname(), "ui", "<MESSAGE>Stop")
        end
      end
    ),
  }
}

