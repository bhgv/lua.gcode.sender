
local ui = require "tek.ui"

local transformCoords = require "conf.utils.transform_coords"


local rel_gcode_display

local ln_cur
local isX, isY, isZ
local cmd_buf
local motion
local absolute, coords
local arc_words, explicit_motion, plane, feed_mode
local arcPoints = require "conf.gparser.arc"

local t_cb = function(l, k, p1, p2)
--  print(k, p1, p2)
end
local vcb_init = function(l, k)
  absolute, coords = true, {}
  arc_words, explicit_motion, plane, feed_mode = {}, false, 17, 94
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
  tmp_vpt.iswork = motion ~= 0
  tmp_vpt.p = motion ~= 0 and 0xff or nil
  local prefix = cmd_buf
  local points = {}
  local is_arc = motion == 2 or motion == 3
  if is_arc and (tmp_vpt.chng or next(arc_words)) then
    assert(plane == 17, "Arc preview currently supports G17 (XY) only")
    local scale = _G.Flags.Transformations.Scale
    assert(_G.Flags.ApproximateArcs or (math.abs(math.abs(scale.x)-math.abs(scale.y)) < 1e-10 and scale.x ~= 0),
      "Circular arcs require equal nonzero XY scale magnitudes")
    local magnitude = math.max(math.abs(scale.x),math.abs(scale.y),1e-20)
    tmp_vbnd.zmin = math.min(tmp_vbnd.zmin, previous.z)
    tmp_vbnd.zmax = math.max(tmp_vbnd.zmax, previous.z)
    points = arcPoints(previous, tmp_vpt, arc_words, motion == 2,
      (_G.Flags.ArcTolerance or 0.01)/magnitude)
    tmp_vpt.chng = true
  elseif tmp_vpt.chng then
    points[1] = tmp_vpt
  end
  for _,point in ipairs(points) do
    point.iswork, point.p, point.ln_n = motion ~= 0, motion ~= 0 and 0xff or nil, l
    tmp_vbnd.xmin = math.min(tmp_vbnd.xmin, point.x)
    tmp_vbnd.xmax = math.max(tmp_vbnd.xmax, point.x)
    tmp_vbnd.ymin = math.min(tmp_vbnd.ymin, point.y)
    tmp_vbnd.ymax = math.max(tmp_vbnd.ymax, point.y)
    if point.iswork then
      tmp_vbnd.zmin = math.min(tmp_vbnd.zmin, point.z)
      tmp_vbnd.zmax = math.max(tmp_vbnd.zmax, point.z)
    end
    tmp_vpts[tmp_vi] = point
    rel_gcode_display[l] = tmp_vi
    tmp_vi = tmp_vi + 1
  end
  if explicit_motion or (is_arc and tmp_vpt.chng) then
    local output_motion = motion
    local transf = _G.Flags.Transformations
    local mirror = transf.Mirror or {}
    local determinant = transf.Scale.x * transf.Scale.y
    if mirror.h then determinant = -determinant end
    if mirror.v then determinant = -determinant end
    if is_arc and _G.Flags.ApproximateArcs then
      output_motion = 1
    elseif is_arc and determinant < 0 then
      output_motion = 5 - motion
    end
    cmd_buf = "G" .. output_motion .. " " .. cmd_buf
  end
  if is_arc and tmp_vpt.chng then
    if arc_words.r then
      cmd_buf = cmd_buf .. string.format("R%.4f ", arc_words.r*math.abs(_G.Flags.Transformations.Scale.x))
    else
      local origin = transformCoords{x=0,y=0,z=0}
      local offset = transformCoords{x=arc_words.i or 0,y=arc_words.j or 0,z=0}
      cmd_buf = cmd_buf .. string.format("I%.4f J%.4f ", offset.x-origin.x, offset.y-origin.y)
    end
  end
  tmp_vpt = {x=tmp_vpt.x,y=tmp_vpt.y,z=tmp_vpt.z,chng=false}
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
  
  if is_arc and #points > 0 and _G.Flags.ApproximateArcs then
    assert(feed_mode == 94, "Arc approximation requires G94 feed mode")
    local segments = gparser.new_store()
    local last = transformCoords(previous)
    for i, point in ipairs(points) do
      local target = transformCoords(point)
      local x, y, z = target.x, target.y, target.z
      if not absolute then x,y,z = x-last.x,y-last.y,z-last.z end
      segments[i] = (i == 1 and prefix or "") .. string.format("G1 X%.4f Y%.4f Z%.4f", x,y,z)
      if not absolute then
        last = {x=last.x+tonumber(string.format("%.4f",x)),
          y=last.y+tonumber(string.format("%.4f",y)),
          z=last.z+tonumber(string.format("%.4f",z))}
      else
        last = target
      end
    end
    cmd_buf = segments:concat("\n")
  elseif not is_arc then
    for _,word in ipairs{'i','j','r'} do
      if arc_words[word] then cmd_buf = cmd_buf .. word:upper() .. arc_words[word] .. " " end
    end
  end
  GTXT_parsed[ln_cur] = cmd_buf

  isX, isY, isZ = false, false, false
  coords, arc_words, explicit_motion = {}, {}, false
  cmd_buf = ""
end




local vcb_cmd = function(l, k, p1, p2)
  p2 = tonumber(p2)
  if p1 == "G" and (p2 == 0 or p2 == 1 or p2 == 2 or p2 == 3) then
    motion, explicit_motion = p2, true
  elseif p1 == "G" and (p2 == 17 or p2 == 18 or p2 == 19) then
    plane = p2
    cmd_buf = cmd_buf .. p1 .. p2 .. " "
  elseif p1 == "G" and p2 == 90.1 then
    error("Absolute arc centers (G90.1) are not supported")
  elseif p1 == "G" and (p2 == 93 or p2 == 94) then
    feed_mode = p2
    cmd_buf = cmd_buf .. p1 .. p2 .. " "
  elseif p1 == "I" or p1 == "J" or p1 == "R" then
    arc_words[p1:lower()] = p2
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
  Display.Bnd = require("conf.utils.transform_bounds")(tmp_vbnd)
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

