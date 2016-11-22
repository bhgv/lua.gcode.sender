-------------------------
-- copyright by bhgv 2016
-------------------------

local lib3d = require "conf.plugins.obj.lib_3d"
local lib2d = require "conf.plugins.obj.lib_2d"
local libDraw = require "conf.plugins.obj.lib_draw"

local g = require "conf.gen.gcode"



local function parse_obj(pars)  
  local sizeW = tonumber(pars['Size W']) or 10
  local sizeH = tonumber(pars['Size H']) or 10
    
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars['Size Z']) or 5
  local dz  = tonumber(pars['Step in depth (Z)']) or 5
  local frq = tonumber(pars.Frequency) or 40
  
  local sl_step = tonumber(pars['Scanline step (Y)']) or 1
  local is_outside = tonumber(
    pars['<RADIO>Milling mode<CASE>Inside<VAL>0<CASE>Outside<VAL>1<CASE>Contour<VAL>2']
  )
  
  local obj_f_name = pars['<FILE><NAME>Obj file<MASK>%.[Oo][Bb][Jj]$']
  
  local f = io.open(obj_f_name, "r")
  if not f then return end
  f:close()
  
  local o = lib3d.obj.do_parse(obj_f_name)
  collectgarbage()
  if not o then return end
  
  g.lib.header(g, frq)
  g:walk_to{z = z_wlk}

  local tdz = (o.max.z - o.min.z)*dz / z_end
  
  local kx = sizeW / (o.max.x - o.min.x)
  local ky = sizeH / (o.max.y - o.min.y)
  local kz = z_end / (o.max.z - o.min.z)
  --print("k", kx, ky, kz, tdz)

  --local i = 0
  local z
  for z = o.max.z, o.min.z, -tdz do
    --print(i, z, dz)
    --i = i + 1
    local slice_lns = lib2d.sort_lns(  lib3d.calculate_slice(o, z)  )
    
    if #slice_lns > 0 or is_outside == 1 then
      libDraw.draw_scanlines(g, o, slice_lns, is_outside, sl_step, kx, ky, kz, -(o.max.z - z), z_wlk)
    end
    
    if #slice_lns > 0 then
      libDraw.draw_contour(g, slice_lns, kx, ky, kz, -(o.max.z - z), z_wlk)
    end
  end
 
  --print("min", o.min.x, o.min.y, o.min.z)
  --print("max", o.max.x, o.max.y, o.max.z)

  g.lib.footer(g, z_wlk)
end



return {
  name = "3D .obj file slicer",
  type = "plugin", 
  subtype = "CAM",
  gui = "button",
  image = nil,
  nosymbol = "Obj", 
  
  exec = function(self, pars)
    --for k,v in pairs(pars) do
    --  print("exec ", k, v)
    --end
    parse_obj(pars)
  end,
}
