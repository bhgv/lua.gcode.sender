
local imhlp = require "conf.utils.image_helper"

g = require "conf.gen.gcode"  


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


local get_pix_map = function(pars)
  --print("tst=", pars["<ImageLoader>"])
  if not (pars["<ImageLoader>"] and imhlp:loadImage(pars["<ImageLoader>"])) then
    return
  end
  
  local i, j
  local map = {}
  local ln
  
  local mix_max = 0
  
  for i = 0, imhlp.H-1 do
    ln = {}
    for j = 0, imhlp.W-1 do
      local px = imhlp:getPixel(j, i)
      
      local b = px & 255
      px = px >> 8 
      local g = px & 255
      px = px >> 8
      local r = px & 255
      
      local mix = 0xff - math.ceil((r + g + b) / 3)
      table.insert(ln, mix)
      if mix > mix_max then mix_max = mix end
    end
    table.insert(map, ln)
    --print(table.concat(ln, " "))
  end
  map.max = mix_max
  return map
end


local old_state = {}

local image2gcode = function(map, pars)
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars.Depth) or 5
  local frq = tonumber(pars.Frequency) or 40
  local n_pas = tonumber(pars["Passes (Z)"]) or 10
  
  local cnc_w = tonumber(pars.Width) or 50
  local cnc_h = tonumber(pars.Height) or 50
  local mm_per_cut = tonumber(pars["Mm per pass (Y)"]) or .5
  
  local clr_stp = tonumber(pars["Color->Z step (0-1)"]) or .5
  if clr_stp < 0 then clr_stp = 0 end
  if clr_stp > 1 then clr_stp = 1 end
  clr_stp = clr_stp * 0xff
  
  clr_beg = map.max - (clr_stp * n_pas) 
  if clr_beg < 0 then 
    clr_beg = 0 
    --clr_stp = math.ceil(map.max / n_pas)
  end
  
  local dx, dy = cnc_w/imhlp.W, cnc_h/imhlp.H
  
  local dz = z_end/n_pas
  local z, i, j, d_mm, ln, pas, clr_trash
  local it
  
  local process = function(st, z, pos)
          if old_state.z ~= z or old_state.st ~= st then
            if old_state.st == "walk" then
              g:walk_to(old_state.pos)
            else
              g:work_to(old_state.pos)
            end
            if st == "walk" and old_state.z <= z then
              g:walk_to{z = z}
            else
              g:work_to{z = z}
            end
            old_state.z = z
            old_state.st = st
          end
          old_state.pos = pos
        end

  
  header(frq)
  
  old_state = {st="walk", z=0, pos={x = 0, y = 0}}
  process("walk", z_wlk, {x = 0, y = (imhlp.H - 1)*dy} )

--  for z = 0, z_end, dz do
  for pas = 0, n_pas do
    z = pas * dz
    clr_trash = math.floor(pas * clr_stp)
    
    for i = 1,#map do
      ln = map[i]
      
      for d_mm = 0, dy, mm_per_cut do
        for j = 1,#ln do
          it = ln[j]
          --print(clr_beg + it, clr_trash)
          if clr_beg + it >= clr_trash then
            process( "work", -z, {x = j*dx, y = (imhlp.H - i)*dy - d_mm} )
          else
            process( "walk", z_wlk, {x = j*dx, y = (imhlp.H - i)*dy - d_mm} )
          end
          
        end -- for j
      end -- for d_mm
    end -- for i
  end -- for pas
  
  process( "walk", z_wlk, {x = 0, y = 0} )
  footer(z_wlk)
end




return {
  name = "Image (*.ppm) to g-code",
  type = "plugin", 
  gui = "button",
  image = nil,
  symbol = "\u{e02c}",
  
  params = {
    ["<ImageLoader>"] = "",
    Width = 50,
    Height = 50,
    ["Mm per pass (Y)"] = .8,
    Frequency = 40,
    ["Walk Z"] = 10,
    Depth = 5,
    ["Passes (Z)"] = 5,
    ["Color->Z step (0-1)"] = .5,
    ["Cnc - true, Laser - false"] = true,
    --["Step (deg)"] = 5,
    --["Shaft diam"] = 10,
  },
  
  exec = function(self, pars)
    --for k,v in pairs(pars) do
    --  print("exec ", k, v)
    --end
    local map = get_pix_map(pars)
    if map then
      image2gcode(map, pars)
    end
  end,
}
