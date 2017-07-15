
local ui = require "tek.ui"

local transformCoords = require "conf.utils.transform_coords"


local rel_gcode_display

local ln_cur
local isX, isY, isZ
local cmd_buf

local t_cb = function(l, k, p1, p2)
--  print(k, p1, p2)
end
local vcb_init = function(l, k)
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
  if tmp_vpt.chng then
    tmp_vpt.ln_n = l
    tmp_vpts[tmp_vi] = tmp_vpt
    tmp_vi = tmp_vi + 1
    
    rel_gcode_display[l] = #tmp_vpts
    
    --print(tmp_vpt.x, tmp_vpt.y)
    tmp_vpt = {x=tmp_vpt.x, y=tmp_vpt.y, z=tmp_vpt.z, chng=false, iswork = false}
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
  cmd_buf = ""
end




local vcb_cmd = function(l, k, p1, p2)
  p2 = tonumber(p2)
  if p1 == "G" and (p2 == 0 or p2 == 1) then 
    --vcb_eol(k)
    if p2 == 1 then
      tmp_vpt.p = 0xff
      tmp_vpt.iswork = true
    end
    cmd_buf = cmd_buf .. p1 .. (p2 or "") .. " "
  elseif p1 == "X" then
    local x = p2
    tmp_vpt.x = x
    if x < tmp_vbnd.xmin then tmp_vbnd.xmin = x end
    if x > tmp_vbnd.xmax then tmp_vbnd.xmax = x end
    tmp_vpt.chng = true
    isX = true
  elseif p1 == "Y" then
    local y = p2
    tmp_vpt.y = y
    if y < tmp_vbnd.ymin then tmp_vbnd.ymin = y end
    if y > tmp_vbnd.ymax then tmp_vbnd.ymax = y end
    tmp_vpt.chng = true
    isY = true
  elseif p1 == "Z" then
    local z = p2
    tmp_vpt.z = z
    if tmp_vpt.iswork then
      if z < tmp_vbnd.zmin then tmp_vbnd.zmin = z end
      if z > tmp_vbnd.zmax then tmp_vbnd.zmax = z end
    end
    tmp_vpt.chng = true
    isZ = true
  else
    cmd_buf = cmd_buf .. p1 .. (p2 or "") .. " " --.. " (" .. l .. ") " 
  end
end
local vcb_fini = function(l, k)
  local nm, v
  Display.Points = tmp_vpts
  Display.Bnd = tmp_vbnd
  Display.Bnd0 = {}
  for nm,v in pairs(tmp_vbnd) do 
    Display.Bnd0[nm] = v 
  end
  Display.Changed = true
  --Display:draw()
end

function do_vparse()
  local txt = table.concat(GTXT, "\n")
  
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
  gparser:do_parse(txt)

  _G.Flags.Rel_gcode2display = rel_gcode_display
  --for i = 1,#o do
  --  print(o[i])
  --end
end

