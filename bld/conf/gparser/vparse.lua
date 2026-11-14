
local ui = require "tek.ui"

local transformCoords = require "conf.utils.transform_coords"


local rel_gcode_display

local ln_cur
local isX, isY, isZ
local cmd_buf
local motion
local absolute, coords, units
local offset, special
local extrusion, extrusion_word, extrusion_absolute, service
local arc_words, explicit_motion, plane, feed_mode
local state_before, feed, shifted, block_feed
local modal_states, range_errors
local function modalState()
  return string.format("G%d G%d G%d G%d G%d",units==1 and 21 or 20,absolute and 90 or 91,plane,feed_mode,
    (motion==2 or motion==3) and (_G.Flags.ApproximateArcs and 1 or motion) or motion) ..
    (feed and string.format(" F%.6f",feed_mode==94 and feed/units or feed) or "")
end
local function outputPoint(point)
  return transformCoords{x=point.x-offset.x,y=point.y-offset.y,z=point.z-offset.z}
end
local arcPoints = require "conf.gparser.arc"

local t_cb = function(l, k, p1, p2)
--  print(k, p1, p2)
end
local vcb_init = function(l, k)
  absolute, coords, units = true, {}, 1
  offset, special = {x=0,y=0,z=0}, nil
  extrusion, extrusion_word, extrusion_absolute, service = 0,nil,true,nil
  arc_words, explicit_motion, plane, feed_mode = {}, false, 17, 94
  motion = 0
  feed, shifted, block_feed = nil, false, nil
  modal_states, range_errors = gparser.new_store(), gparser.new_store()
  state_before = modalState()
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
  while #modal_states < l do
    modal_states[#modal_states+1] = state_before
    range_errors[#range_errors+1] = shifted and "G92 state precedes selected range; start before G92" or ""
  end
  if service then
    assert(not explicit_motion and not special, "Marlin service and motion commands must use separate blocks")
    while ln_cur < l-1 do ln_cur=ln_cur+1; GTXT_parsed[ln_cur]="" end
    for _,axis in ipairs{'x','y','z'} do
      if coords[axis] then cmd_buf=cmd_buf .. axis:upper() .. coords[axis] .. " " end
    end
    if extrusion_word then cmd_buf=cmd_buf .. "E" .. extrusion_word .. " " end
    ln_cur=ln_cur+1
    GTXT_parsed[ln_cur]=cmd_buf
    coords,arc_words,explicit_motion,special,service = {},{},false,nil,nil
    extrusion_word,block_feed=nil,nil
    isX,isY,isZ=false,false,false
    cmd_buf=""
    state_before=modalState()
    return
  end
  if block_feed then feed=feed_mode==94 and block_feed*units or block_feed end
  local previous_e = extrusion
  if extrusion_word then
    if special == 92 or extrusion_absolute then extrusion=extrusion_word*units
    else extrusion=extrusion+extrusion_word*units end
  end
  if extrusion_word then cmd_buf=cmd_buf .. string.format("E%.5f ",extrusion_word) end
  local previous = {x=tmp_vpt.x, y=tmp_vpt.y, z=tmp_vpt.z}
  if special == 92 or special == 92.1 then
    assert(not explicit_motion, "G92 cannot share a block with a motion command")
    if special == 92.1 then
      shifted = false
      offset = {x=0,y=0,z=0}
    else
      shifted = next(coords) ~= nil or shifted
      for axis,value in pairs(coords) do offset[axis]=previous[axis]-value*units end
    end
    while ln_cur < l-1 do ln_cur=ln_cur+1; GTXT_parsed[ln_cur]="" end
    ln_cur=ln_cur+1
    if special == 92 and next(coords) then
      local target=outputPoint(previous)
      GTXT_parsed[ln_cur]=cmd_buf .. string.format("X%.4f Y%.4f Z%.4f",target.x/units,target.y/units,target.z/units)
    else
      GTXT_parsed[ln_cur]=cmd_buf
    end
    coords,arc_words,explicit_motion,special = {},{},false,nil
    isX,isY,isZ=false,false,false
    cmd_buf=""
    block_feed,extrusion_word=nil,nil
    state_before=modalState()
    return
  end
  for axis, value in pairs(coords) do
    tmp_vpt[axis] = absolute and (value*units+offset[axis]) or (tmp_vpt[axis] + value*units)
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
    local geometry = {}
    for word,value in pairs(arc_words) do geometry[word]=value*units end
    points = arcPoints(previous, tmp_vpt, geometry, motion == 2,
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
      local offset = transformCoords{x=(arc_words.i or 0)*units,y=(arc_words.j or 0)*units,z=0}
      cmd_buf = cmd_buf .. string.format("I%.4f J%.4f ", (offset.x-origin.x)/units, (offset.y-origin.y)/units)
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
    pt = outputPoint(tmp_vpt)
    if not absolute then
      local origin = outputPoint(previous)
      pt.x, pt.y, pt.z = pt.x - origin.x, pt.y - origin.y, pt.z - origin.z
    end
  end

  if isX or isY then
    cmd_buf = cmd_buf .. string.format("X%.4f", pt.x/units) .. string.format(" Y%.4f",  pt.y/units) --.. "Z" .. z
  end
  if isZ then
    cmd_buf = cmd_buf .. string.format(" Z%.4f",  pt.z/units)
  end
  
--  Sender:newcmd(cmd_buf)
  ln_cur = ln_cur + 1
  
  if is_arc and #points > 0 and _G.Flags.ApproximateArcs then
    assert(feed_mode == 94, "Arc approximation requires G94 feed mode")
    local segments = gparser.new_store()
    local last = outputPoint(previous)
    local sent_e = previous_e
    for i, point in ipairs(points) do
      local target = outputPoint(point)
      local x, y, z = target.x, target.y, target.z
      if not absolute then x,y,z = x-last.x,y-last.y,z-last.z end
      local segment_prefix = prefix:gsub("E[+%-]?[%d%.]+%s*", "")
      segments[i] = (i == 1 and segment_prefix or "") .. string.format("G1 X%.4f Y%.4f Z%.4f", x/units,y/units,z/units)
      if extrusion_word then
        local fraction = point.fraction or i/#points
        local target_e = previous_e+(extrusion-previous_e)*fraction
        local amount = extrusion_absolute and target_e or (target_e-sent_e)
        sent_e = sent_e + tonumber(string.format("%.5f",amount/units))*units
        segments[i] = segments[i] .. string.format(" E%.5f",amount/units)
      end
      if not absolute then
        last = {x=last.x+tonumber(string.format("%.4f",x/units))*units,
          y=last.y+tonumber(string.format("%.4f",y/units))*units,
          z=last.z+tonumber(string.format("%.4f",z/units))*units}
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
  block_feed,extrusion_word=nil,nil
  state_before=modalState()
end




local vcb_cmd = function(l, k, p1, p2)
  p2 = tonumber(p2)
  if _G.Flags.Controller == "marlin" and p1 == "E" then
    extrusion_word = p2
  elseif _G.Flags.Controller == "marlin" and p1 == "M" and (p2==82 or p2==83) then
    extrusion_absolute=p2==82
    cmd_buf=cmd_buf .. p1 .. p2 .. " "
  elseif _G.Flags.Controller == "marlin" and p1 == "M" then
    service=p2
    cmd_buf=cmd_buf .. p1 .. p2 .. " "
  elseif p1 == "G" and (p2 == 92 or p2 == 92.1) then
    special = p2
    cmd_buf = cmd_buf .. p1 .. p2 .. " "
  elseif p1 == "G" and (p2 == 10 or p2 == 28 or p2 == 30 or p2 == 43.1 or (p2 >= 55 and p2 <= 59)) then
    error("G" .. p2 .. " requires controller coordinate context unavailable to offline preview")
  elseif p1 == "F" then
    block_feed = p2
    cmd_buf = cmd_buf .. p1 .. p2 .. " "
  elseif p1 == "G" and p2 == 53 then
    error("G53 requires machine/work-coordinate context unavailable to offline preview")
  elseif p1 == "G" and (p2 == 0 or p2 == 1 or p2 == 2 or p2 == 3) then
    motion, explicit_motion = p2, true
  elseif p1 == "G" and (p2 == 20 or p2 == 21) then
    units = p2 == 20 and 25.4 or 1
    cmd_buf = cmd_buf .. p1 .. p2 .. " "
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
    if _G.Flags.Controller == "marlin" then extrusion_absolute=absolute end
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
  local source = GTXT
  local passthrough = gparser.new_store()
  if _G.Flags.Controller == "marlin" then
    source = GTXT:clone()
    for i=1,#source do
      local number = source[i]:upper():match("^%s*[MG](%d+)")
      local letter = source[i]:upper():match("^%s*([MG])")
      if (letter=="M" and (number=="117" or number=="118" or number=="84" or number=="18")) or
        (letter=="G" and (number=="28" or number=="29" or number=="10" or number=="11")) then
        passthrough[i]=source[i]
        source[i]=""
      else
        passthrough[i]=""
      end
    end
  end
  local txt = source:concat("\n")
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
  if ok and _G.Flags.Controller == "marlin" then
    ok, err = pcall(function()
      local prepare = require "conf.controllers.marlin.prepare"
      for i=1,#GTXT do
        if passthrough[i] == "" then GTXT_parsed[i]=prepare(GTXT_parsed[i] or "") end
      end
    end)
  end
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
  for i=1,#passthrough do
    if passthrough[i] ~= "" then GTXT_parsed[i]=passthrough[i] end
  end
  while #modal_states < #GTXT do
    modal_states[#modal_states+1] = state_before
    range_errors[#range_errors+1] = shifted and "G92 state precedes selected range; start before G92" or ""
  end
  _G.Flags.ModalStates, _G.Flags.RangeErrors = modal_states, range_errors
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

