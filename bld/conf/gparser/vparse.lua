
local ui = require "tek.ui"

t_cb = function(k, p1, p2)
  print(k, p1, p2)
end
vcb_init = function(k)
  tmp_vpts = { [0]={x=0, y=0, z=0} }
  tmp_vpt = {x=0, y=0, z=0, chng=false}
  tmp_vi = 1
  tmp_vbnd = {xmax = 000000, xmin = 000000, ymax = 000000, ymin = 000000}
end
vcb_eol = function(k)
  if tmp_vpt.chng then
    tmp_vpts[tmp_vi] = tmp_vpt
    tmp_vi = tmp_vi + 1
    --print(tmp_vpt.x, tmp_vpt.y)
    tmp_vpt = {x=tmp_vpt.x, y=tmp_vpt.y, z=tmp_vpt.z, chng=false}
  end
end
vcb_cmd = function(k, p1, p2)
  if p1 == "G" and (p2 == "0" or p2 == "1") then 
    vcb_eol(k)
    if p2 == "0" then
      tmp_vpt.p = "blue"
    end
  elseif p1 == "X" then
    local x = 0+p2
    tmp_vpt.x = x
    if x < tmp_vbnd.xmin then tmp_vbnd.xmin = x end
    if x > tmp_vbnd.xmax then tmp_vbnd.xmax = x end
    tmp_vpt.chng = true
  elseif p1 == "Y" then
    local y = 0+p2
    tmp_vpt.y = y
    if y < tmp_vbnd.ymin then tmp_vbnd.ymin = y end
    if y > tmp_vbnd.ymax then tmp_vbnd.ymax = y end
    tmp_vpt.chng = true
  elseif p1 == "Z" then
    local z = 0+p2
    tmp_vpt.z = z
    tmp_vpt.chng = true
  end
end
vcb_fini = function(k)
  Display.Points = tmp_vpts
  Display.Bnd = tmp_vbnd
  Display:draw()
end

function do_vparse()
  --App:addCoroutine(function()
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
  
  --local o = 
  gparser:do_parse(txt)

  --for i = 1,#o do
  --  print(o[i])
  --end
  --end)
end

