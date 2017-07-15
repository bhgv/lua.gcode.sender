
local ui = require "tek.ui"

local transformCoords = require "conf.utils.transform_coords"


local cmd_buf
local x, y, z
local ln_cur
local isX, isY, isZ

local scb_init = function(l, k)
  cmd_buf = ""
  x, y, z = 0, 0, 0
  ln_cur = 0
end

local scb_eol = function(l, k)
  local pt
  while ln_cur < l - 1 do
    Sender:newcmd("")
    ln_cur = ln_cur + 1
  end
  
  if isX or isY or isZ then
    pt = transformCoords{x=x, y=y, z=z}
  end

  if isX or isY then
    cmd_buf = cmd_buf .. string.format("X%.4f", pt.x) .. string.format(" Y%.4f",  pt.y) --.. "Z" .. z
  end
  if isZ then
    cmd_buf = cmd_buf .. string.format(" Z%.4f",  pt.z)
  end

  Sender:newcmd(cmd_buf)
  ln_cur = ln_cur + 1
  
  GTXT_parsed[ln_cur] = cmd_buf

  isX, isY, isZ = false, false, false
  cmd_buf = ""
end

local scb_cmd = function(l, k, p1, p2)
  if p1 == "X" then
    x = tonumber(p2)
    isX = true
  elseif p1 == "Y" then
    y = tonumber(p2)
    isY = true
  elseif p1 == "Z" then
    z = tonumber(p2)
    isZ = true
  else
    cmd_buf = cmd_buf .. p1 .. (p2 or "") .. " " --.. " (" .. l .. ") " 
  end
end

local scb_fini = function(l, k)
  Sender:newcmd("FIN")
end

function do_sparse(from, to)
  if from == nil then
    from = 1
  end
  if to == nil then
    to = #GTXT
  end
  --print (from, to)
  
  local txt
  if _G.Flags.isEdited then
    txt = table.concat(GTXT, "\n", from, to) .. "\n"
  end
  
  _G.Flags.SendFrom = from or 1
  _G.Flags.SendTo = to
  
  if _G.Flags.isEdited then
    gparser.set_callback_dict {
      cmd= scb_cmd,
      eol= scb_eol,
      init= scb_init,
      fini= scb_fini,
      pragma= nil,
      aux_cmd= nil,
      default= nil,
      no_callback= nil,
    }
  end

  Sender:newcmd("NEW")
  
  local o

  if _G.Flags.isEdited then
    o = gparser:do_parse(txt)
  else
    local i
    --scb_init(0, 0)
    for i = _G.Flags.SendFrom, _G.Flags.SendTo do
      Sender:newcmd(GTXT_parsed[i])
--      print(GTXT_parsed[i])
    end
    Sender:newcmd("FIN")
--scb_fini(0, 0)
  end

  _G.Flags.isEdited = false

  --local transformCoords = require "conf.utils.transform_coords"

  --local base_x, base_y, base_z = 0, 0, 0
  --local cmd, x, y, z, pt
  
  --for i = 1,#o do
  --  cmd = o[i]
    --[[
    x = tonumber( cmd:match("[xX]%s*([%+%-]?%d*%.?%d*)") )
    y = tonumber( cmd:match("[xX]%s*([%+%-]?%d*%.?%d*)") )
    z = tonumber( cmd:match("[xX]%s*([%+%-]?%d*%.?%d*)") )
    
    if x or y or z then
      x = x or base_x
      y = y or base_y
      z = z or base_z
      pt = transformCoords{
            x = x,
            y = y,
            z = z,
          }
      base_x, base_y, base_z = pt.x, pt.y, pt.z
      
      cmd = cmd:gsub("([xX]%s*)[%+%-]?%d*%.?%d*", "%1" .. pt.x)
      cmd = cmd:gsub("([yY]%s*)[%+%-]?%d*%.?%d*", "%1" .. pt.y)
      cmd = cmd:gsub("([zZ]%s*)[%+%-]?%d*%.?%d*", "%1" .. pt.z)
      print (cmd)
    end
    ]]
    
  --  Sender:newcmd(cmd)
  --  print(o[i])
  --end
  Sender:newcmd("SENDFROM")
  Sender:newcmd(tostring(from or 1))
  
  Sender:newcmd("CALCULATE")
end

