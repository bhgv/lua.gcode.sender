-------------------------
-- copyright by bhgv 2016
-------------------------

svg = require "luaSVG"

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


local function parse_svg(pars)  
  local sizeW = tonumber(pars['Size W']) or 10
  local sizeH = tonumber(pars['Size H']) or 10
    
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars.Depth) or 5
  local frq = tonumber(pars.Frequency) or 40
  local n_pas = tonumber(pars.Passes) or 10
  
  local svg_f_name = pars['<FILE><NAME>SVG file<MASK>%.[Ss][Vv][Gg]$']

--  local x0, y0 =
--            r_bigger + r_smaller,
--            r_bigger / math.sqrt(2)

  local dz = z_end/n_pas
  local z
  

    
  local f = io.open(svg_f_name, "r")
  if not f then return end

  local txt = f:read("*a")
  f:close()

  local i, j, k, l, shape, path, curve
  local o = svg.do_parse(txt)

  local mx, my =
          sizeW / o.W,
          sizeH / o.H


  header(frq)
  g:walk_to{z = z_wlk}

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

  footer(z_wlk)
end



return {
  name = "SVG loader",
  type = "plugin", 
  subtype = "CAM",
  gui = "button",
  image = nil,
  nosymbol = "SVG", --"\u{e0e3}",
  
  exec = function(self, pars)
    --for k,v in pairs(pars) do
    --  print("exec ", k, v)
    --end
    parse_svg(pars)
  end,
}
