-------------------------
-- copyright by bhgv 2016
-------------------------

dxf = require "luaDXF2"

g = require "conf.gen.gcode"



local cos = function(a)
  return math.cos(math.rad(a))
end
local sin = function(a)
  return math.sin(math.rad(a))
end


local function calculate(r_smaller, r_bigger, step_deg)
end



local function header(frq)
  g:start()
  g:set_param("absolute")
  g:set_param("metric")

  g:spindle_freq(frq)
  g:spindle_on(true)
end


local function footer(z_wlk)
  g:walk_to{z = z_wlk}
  g:walk_to{x = 0, y = 0}
  g:walk_to{z = 0}
  g:spindle_on(false)
  
  g:finish()
end


local function parse_dxf(pars)  
  local sizeW = tonumber(pars['Size W']) or 10
  local sizeH = tonumber(pars['Size H']) or 10
    
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars.Depth) or 5
  local frq = tonumber(pars.Frequency) or 40
  local n_pas = tonumber(pars.Passes) or 10
  
  local dxf_f_name = pars['<FILE><NAME>DXF file<MASK>%.[Dd][Xx][Ff]$']

--  local x0, y0 =
--            r_bigger + r_smaller,
--            r_bigger / math.sqrt(2)

  local dz = z_end/n_pas
  local z
  

    
  local f = io.open(dxf_f_name, "r")
  if not f then return end

--  local txt = f:read("*a")
  f:close()

  local i, j, k, l, shape, path, curve
  local o = dxf.do_parse(dxf_f_name)
  if not o then return end
--  local mx, my =
--          sizeW / o.W,
--          sizeH / o.H


  header(frq)
  g:walk_to{z = z_wlk}

  local i,layer
  for i,layer in ipairs(o) do
    local j, face, line
    local k, pt
    
    if layer.faces then
      for j,face in ipairs(layer.faces) do
        for k,pt in ipairs(face) do
          if k == 1 then
            g:walk_to{x = pt.x, y = pt.y}
            g:walk_to{z = pt.z}
          else
            g:work_to{x = pt.x, y = pt.y, z = pt.z}
          end
        end
        g:walk_to{z = z_wlk}
      end
    end
    
    if layer.lines then
      for j,line in ipairs(layer.lines) do
        for k,pt in ipairs(line) do
          if k == 1 then
            g:walk_to{x = pt.x, y = pt.y}
            g:walk_to{z = pt.z}
          else
            g:work_to{x = pt.x, y = pt.y, z = pt.z}
          end
        end
        g:walk_to{z = z_wlk}
      end
    end
  end

--[[
  for z = dz, z_end, dz do

    for i,shape in ipairs(o) do
      --print("\n",i,shape.type, "\n-----------------------")
      for j,path in ipairs(shape) do
        --print("\n",j,path.type,"\n++++++")
        g:work_to{z = -z}
        for k,curve in ipairs(path) do
          --print(k,curve.type)
          g:work_to{x = mx * curve.p1.x, y = my * curve.p1.y}
          g:work_to{x = mx * curve.p2.x, y = my * curve.p2.y}
          g:work_to{x = mx * curve.p3.x, y = my * curve.p3.y}
          g:work_to{x = mx * curve.p4.x, y = my * curve.p4.y}
        end
        g:walk_to{z = z_wlk}
      end
    end
    g:walk_to{z = z_wlk}
  end
]]

  footer(z_wlk)
end



return {
  name = "DXF loader",
  type = "plugin", 
  subtype = "CAM",
  gui = "button",
  image = nil,
  nosymbol = "DXF", --"\u{e0e3}",
  
  exec = function(self, pars)
    --for k,v in pairs(pars) do
    --  print("exec ", k, v)
    --end
    parse_dxf(pars)
  end,
}
