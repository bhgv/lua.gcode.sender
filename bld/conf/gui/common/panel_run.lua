
local ui = require "tek.ui"


return ui.Group:new
{
  Children = 
  {
    symBut(
      "\u{e078}",
      function(self)
          Sender:newcmd('$H')
      end
    ),
    symBut(
      "\u{e093}",
      function(self)
        if MKstate == "STOP" then
          Sender:newcmd("FEEL")
          do_sparse()
          Sender:newcmd("RESUME")
          MKstate = "RUN"
        elseif MKstate == "PAUSE" then
          Sender:newcmd("RESUME")
          MKstate = "RUN"
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
        elseif MKstate == "RUN" then
          cmd = "PAUSE"
          MKstate = "PAUSE"
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
        end
      end
    ),
  }
}

