function do_sparse(from, to)
  from = from or 1
  to = to or #GTXT
  assert(type(from) == "number" and math.tointeger(from), "Invalid first line")
  assert(type(to) == "number" and math.tointeger(to), "Invalid last line")
  assert(from >= 1 and to <= #GTXT and from <= to, "Invalid print range")
  from = math.max(1, from)
  to = math.min(#GTXT, to)

  local parsed, err = do_vparse()
  assert(parsed, err)
  assert(_G.Flags.Controller ~= "marlin" or from == 1, "Marlin printing must start at row 1 to preserve extrusion/setup state")
  if from > 1 then assert(_G.Flags.RangeErrors[from] == "", _G.Flags.RangeErrors[from]) end
  _G.Flags.SendFrom = from
  _G.Flags.SendTo = to

  Sender:newcmd("NEW")
  if from > 1 then
    Sender:newcmd("SOURCE")
    Sender:newcmd(tostring(from))
    Sender:newcmd(_G.Flags.ModalStates[from])
  end
  for i = from, to do
    Sender:newcmd("SOURCE")
    Sender:newcmd(tostring(i))
    local line = GTXT_parsed[i]
    if line == "" then
      Sender:newcmd("")
    else
      for command in line:gmatch("[^\n]+") do Sender:newcmd(command) end
    end
  end
  Sender:newcmd("FIN")
  Sender:newcmd("SENDFROM")
  Sender:newcmd(tostring(from))
  Sender:newcmd("CALCULATE")
  _G.Flags.isEdited = false
end
