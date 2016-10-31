
local ui = require "tek.ui"

scb_init = function(k)
end
scb_eol = function(k)
end
scb_cmd = function(k, p1, p2)
end
scb_fini = function(k)
end

function do_sparse(from, to)
  if from == nil then
    from = 1
  end
  if to == nil then
    to = #GTXT
  end
  --print (from, to)
  local txt = table.concat(GTXT, "\u{d}", from, to)
  
  _G.Flags.SendFrom = from
  _G.Flags.SendTo = to
  
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
  Sender:newcmd("SENDFROM")
  Sender:newcmd(tostring(from))
  
  Sender:newcmd("CALCULATE")
end

