
local ui = require "tek.ui"

scb_init = function(k)
end
scb_eol = function(k)
end
scb_cmd = function(k, p1, p2)
end
scb_fini = function(k)
end

function do_sparse()
  --App:addCoroutine(function()
  local txt = table.concat(GTXT, "\n")
  
  --[[
  gparser.set_callback_dict {
    cmd= nil, -- scb_cmd,
    eol= nil, -- scb_eol,
    init= nil, -- scb_init,
    fini= nil, -- scb_fini,
    pragma= nil,
    aux_cmd= nil,
    default= nil,
    no_callback= nil,
  }
  ]]
  
  Sender:newcmd("NEW")
  
  local o = gparser:do_parse(txt)
  
  for i = 1,#o do
    Sender:newcmd(o[i])
  --  print(o[i])
  end
  Sender:newcmd("CALCULATE")
  --end)
end
