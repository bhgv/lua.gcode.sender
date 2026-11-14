
local ui = require "tek.ui"

local transformCoords = require "conf.utils.transform_coords"


local rel_gcode_display

local ln_cur
local isX, isY, isZ
local cmd_buf
local motion
local absolute, coords

local t_cb = function(l, k, p1, p2)
--  print(k, p1, p2)
end
local vcb_init = function(l, k)
  absolute, coords = true, {}
  motion = 0
  GTXT_parsed:clear()
  tmp_vpts = { [0]={x=0, y=0, z=0} }
  tmp_vpt = {x=0, y=0, z=0, chng=false}
  tmp_vi = 1
  tmp_vbnd = {
            xmax = math.mininteger, xmin = math.maxinteger, 
            ymax = math.mininteger, ymin = math.maxinteger, 
            zmax = math.mininteger, zmin = math.maxinteger
  }
  ln_cur = 0
  isX, isY, isZ = false, false, false
  cmd_buf = ""
end
local vcb_eol = function(l, k)
  local previous = {x=tmp_vpt.x, y=tmp_vpt.y, z=tmp_vpt.z}
  for axis, value in pairs(coords) do
    tmp_vpt[axis] = absolute and value or (tmp_vpt[axis] + value)
    tmp_vpt.chng = true
  end
  tmp_vpt.iswork = motion == 1
  tmp_vpt.p = motion == 1 and 0xff or nil
  if tmp_vpt.chng then
    tmp_vbnd.xmin = math.min(tmp_vbnd.xmin, tmp_vpt.x)
    tmp_vbnd.xmax = math.max(tmp_vbnd.xmax, tmp_vpt.x)
    tmp_vbnd.ymin = math.min(tmp_vbnd.ymin, tmp_vpt.y)
    tmp_vbnd.ymax = math.max(tmp_vbnd.ymax, tmp_vpt.y)
    if tmp_vpt.iswork then
      tmp_vbnd.zmin = math.min(tmp_vbnd.zmin, tmp_vpt.z)
      tmp_vbnd.zmax = math.max(tmp_vbnd.zmax, tmp_vpt.z)
    end
  end
  if tmp_vpt.chng then
    tmp_vpt.ln_n = l
    tmp_vpts[tmp_vi] = tmp_vpt
    tmp_vi = tmp_vi + 1
    
    rel_gcode_display[l] = #tmp_vpts
    
    --print(tmp_vpt.x, tmp_vpt.y)
    tmp_vpt = {x=tmp_vpt.x, y=tmp_vpt.y, z=tmp_vpt.z, chng=false, iswork = motion == 1, p = motion == 1 and 0xff or nil}
  end
--end
--local scb_eol = function(l, k)
  local pt
  while ln_cur < l - 1 do
--    Sender:newcmd("")
    ln_cur = ln_cur + 1
    GTXT_parsed[ ln_cur ] = ""
  end
  
  if isX or isY or isZ then
    pt = transformCoords{x=tmp_vpt.x, y=tmp_vpt.y, z=tmp_vpt.z}
    if not absolute then
      local origin = transformCoords(previous)
      pt.x, pt.y, pt.z = pt.x - origin.x, pt.y - origin.y, pt.z - origin.z
    end
  end

  if isX or isY then
    cmd_buf = cmd_buf .. string.format("X%.4f", pt.x) .. string.format(" Y%.4f",  pt.y) --.. "Z" .. z
  end
  if isZ then
    cmd_buf = cmd_buf .. string.format(" Z%.4f",  pt.z)
  end
  
--  Sender:newcmd(cmd_buf)
  ln_cur = ln_cur + 1
  
  GTXT_parsed[ln_cur] = cmd_buf

  isX, isY, isZ = false, false, false
  coords = {}
  cmd_buf = ""
end




local vcb_cmd = function(l, k, p1, p2)
  p2 = tonumber(p2)
  if p1 == "G" and (p2 == 0 or p2 == 1) then 
    --vcb_eol(k)
    motion = p2
    tmp_vpt.iswork = motion == 1
    tmp_vpt.p = motion == 1 and 0xff or nil
    cmd_buf = cmd_buf .. p1 .. (p2 or "") .. " "
  elseif p1 == "G" and (p2 == 90 or p2 == 91) then
    absolute = p2 == 90
    cmd_buf = cmd_buf .. p1 .. p2 .. " "
  elseif p1 == "X" then
    coords.x = p2
    isX = true
  elseif p1 == "Y" then
    coords.y = p2
    isY = true
  elseif p1 == "Z" then
    coords.z = p2
    isZ = true
  else
    cmd_buf = cmd_buf .. p1 .. (p2 or "") .. " " --.. " (" .. l .. ") " 
  end
end
local vcb_fini = function(l, k)
  local nm, v
  for _, axis in ipairs{'x', 'y', 'z'} do
    if tmp_vbnd[axis .. 'min'] == math.maxinteger then
      tmp_vbnd[axis .. 'min'] = 0
      tmp_vbnd[axis .. 'max'] = 0
    end
  end
  Display.Points = tmp_vpts
  Display.Bnd = tmp_vbnd
  Display.Bnd0 = {}
  for nm,v in pairs(tmp_vbnd) do 
    Display.Bnd0[nm] = v 
  end
  Display.Changed = true
  --Display:draw()
end

function do_vparse(preview)
  local previous = GTXT_parsed
  local points, bnd, bnd0, changed = Display.Points, Display.Bnd, Display.Bnd0, Display.Changed
  GTXT_parsed = gparser.new_store()
  local txt = GTXT:concat("\n")
  if #GTXT > 0 then txt = txt .. "\n" end
  
  gparser.set_callback_dict {
    cmd= vcb_cmd,
    eol= vcb_eol,
    init= vcb_init,
    fini= vcb_fini,
    pragma= nil,
    aux_cmd= nil,
    default= nil,
    no_callback= nil,
  }
  
  rel_gcode_display = {}
  
  --local o = 
  local ok, err = pcall(gparser.do_parse, gparser, txt)
  if not ok then
    GTXT_parsed = previous
    Display.Points, Display.Bnd, Display.Bnd0, Display.Changed = points, bnd, bnd0, changed
    if App then
      App:getById("status main"):setValue("Text", "Parse failed: " .. tostring(err))
    end
    return nil, err
  end

  while #GTXT_parsed < #GTXT do
    GTXT_parsed[#GTXT_parsed + 1] = ""
  end
  if preview == false then
    Display.Points, Display.Bnd, Display.Bnd0, Display.Changed = points, bnd, bnd0, changed
  else
    _G.Flags.Rel_gcode2display = rel_gcode_display
    Display.sel_line = nil
  end
  return true
  --for i = 1,#o do
  --  print(o[i])
  --end
end

