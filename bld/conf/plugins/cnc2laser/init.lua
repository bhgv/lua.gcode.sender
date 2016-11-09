-------------------------
-- copyright by bhgv 2016
-------------------------


local function cnc2laser(cmd, pars)
  local out = cmd
  local isXY = cmd:match("[xyXYfFsS]%s*[%+%-]?%s*%d*%.?%d*")
  
  if isXY then
    out = out:gsub("[Zz]%s*%-%s*%d*%.?%d*", "M3") --"S1000")
    out = out:gsub("[Zz]%s*%d*%.?%d*", "M5") --"S0")
  --  out = out:gsub("[Gg]%s*0+([^%d])", "G1%1")
  else
    if cmd:match("[Zz]%s*%-%s*%d*%.?%d*") then
      out = "M3" --"S1000"
    elseif cmd:match("[Zz]%s*%d*%.?%d*") then
      out = "M5" --"S0"
    end
  end
  
  return out
end




return {
  name = "runtime CNC -> Laser",
  type = "plugin", 
  subtype = "Filter",
  gui = "button",
  image = nil,
  symbol = "\u{e0e5}",
  
  exec = function(self, cmd, pars)
--    for k,v in pairs(pars) do
--      print("exec ", k, v)
--    end
    return cnc2laser(cmd, pars)
  end,
}
