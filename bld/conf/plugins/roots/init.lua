
g = require "conf.gen.gcode"


local cos = function(a)
  return math.cos(math.rad(a))
end
local sin = function(a)
  return math.sin(math.rad(a))
end


local function calculate(r_smaller, r_bigger, step_deg)
  local k = 4
  local rm = r_smaller
  local s = 1

  local rb = r_bigger
  local lp = {}
  
  local a, am, pt
  
  for a = 0,360,step_deg do
    if a == 180 then -- time to flip from outer to inner profile
      rb = rb -2*rm
      s = -s
    end
    am = s*a + a/4
    pt = {
      x = s*rm*cos(am) + rb*cos( a/k ), 
      y = s*rm*sin(am) + rb*sin( a/k ),
    }
    table.insert(lp, pt)
  end
  
  return lp
end


local function draw_lobe_pass(x0, y0, z, shp_pts, r_smaller, r_bigger, step_deg)
  local k = 4

  local rm = r_smaller
  local rb = r_bigger
  
  local lp = shp_pts
  
  local x0, y0 =
            rb+rm,
            rb/math.sqrt(2)
  
  g:walk_to{x = x0 - lp[1].x, y = y0 + lp[1].y } -- to begin
  g:work_to{z = z}     -- to working depth
  
  for i = 1, #lp do 
    g:work_to{ x = x0 - lp[i].x, y = y0 + lp[i].y } -- lobe-roots shape (1 quadr)
  end
  for i = #lp,1,-1 do 
    g:work_to{ x = x0 + lp[i].x, y = y0 + lp[i].y } -- lobe-roots shape (2 quadr)
  end
  for i = 1,#lp do 
    g:work_to{ x = x0 + lp[i].x, y = y0 - lp[i].y } -- lobe-roots shape (3 quadr)
  end
  for i = #lp,1,-1 do 
    g:work_to{ x = x0 - lp[i].x, y = y0 - lp[i].y } -- lobe-roots shape (4 quadr)
  end
end


local function draw_shaft_pass(x0, y0, z, shft_r, step_deg)
  local a
  
  g:walk_to{x = x0 - shft_r, y = y0 + 0 } -- to begin
  g:walk_to{z = z} -- to working depth
  
  for a = 0, 360, step_deg do 
    g:work_to{ x = x0 - shft_r*cos(a), y = y0 + shft_r*sin(a) } -- shaft hole
  end
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


local lobe_roots = function(pars)
  local step_deg = tonumber(pars["Step (deg)"]) or 0
  step_deg = 180 / math.floor(180 / step_deg)
  
  local half_size = tonumber(pars.Size) / 2
  
  local k = 4
  local r_smaller = half_size / (k+1+1)
  local r_bigger = r_smaller * (k+1)
  
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars.Depth) or 5
  local frq = tonumber(pars.Frequency) or 40
  local n_pas = tonumber(pars.Passes) or 10
  
  local shft_r = tonumber(pars["Shaft diam"])/2

  local x0, y0 =
            r_bigger + r_smaller,
            r_bigger / math.sqrt(2)

  local dz = z_end/n_pas
  local z
  
  local shp_pts = calculate(r_smaller, r_bigger, step_deg)

  header(frq)
  g:walk_to{z = z_wlk}
  
  for z = 0, z_end, dz do
    draw_shaft_pass(x0, y0, -z, shft_r, step_deg)
  end
  g:walk_to{z = z_wlk}
  
  for z = 0, z_end, dz do
    draw_lobe_pass(x0, y0, -z, shp_pts, r_smaller, r_bigger, step_deg)
  end
  footer(z_wlk)
end




return {
  name = "Lobe-Roots shape",
  type = "plugin", 
  gui = "button",
  image = nil,
  symbol = "\u{e0e3}",
  
  params = {
    Size = 50,
    Frequency = 40,
    ["Walk Z"] = 10,
    Depth = 5,
    Passes = 5,
    ["Step (deg)"] = 5,
    ["Shaft diam"] = 10,
  },
  
  exec = function(self, pars)
    --for k,v in pairs(pars) do
    --  print("exec ", k, v)
    --end
    lobe_roots(pars)
  end,
}
