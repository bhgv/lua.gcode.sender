function do_sparse(from, to)
  from = from or 1
  to = to or #GTXT
  from = math.max(1, from)
  to = math.min(#GTXT, to)

  do_vparse()
  _G.Flags.SendFrom = from
  _G.Flags.SendTo = to

  Sender:newcmd("NEW")
  for i = from, to do
    Sender:newcmd(GTXT_parsed[i])
  end
  Sender:newcmd("FIN")
  Sender:newcmd("SENDFROM")
  Sender:newcmd(tostring(from))
  Sender:newcmd("CALCULATE")
  _G.Flags.isEdited = false
end
