
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


local image = function(pars)
  --print("tst=", pars["<ImageLoader>"])
  if not (pars["<ImageLoader>"] and imhlp:loadImage(pars["<ImageLoader>"])) then
    return
  end
  
  local i, j
  local map = {}
  local ln
  
  for i = 0, imhlp.W-1 do
    ln = {}
    for j = 0, imhlp.H-1 do
      local px = imhlp:getPixel(i, j)
      
      local b = px & 255
      px = px >> 8 
      local g = px & 255
      px = px >> 8
      local r = px & 255
      
      local mix = math.ceil((r + g + b) / 3)
      table.insert(ln, mix)
    end
    table.insert(map, ln)
  end
  
    
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars.Depth) or 5
  local frq = tonumber(pars.Frequency) or 40
  local n_pas = tonumber(pars.Passes) or 10
  
  local dz = z_end/n_pas
  local z = 0
  local it
  
  header(frq)
  
  for z = 0, z_end, dz do
    
    for i = 1,#map do
      ln = map[i]
      
      g:walk_to{z = z_wlk}
      g:walk_to{x = 0, y = imhlp.H - i}
      
      for j = 1,#ln do
        it = ln[j]
        if it < 0x7f then
          g:work_to{z = -z}
          g:work_to{x = j, y = imhlp.H - i }
        else
          g:walk_to{z = z_wlk}
          g:walk_to{x = j, y = imhlp.H - i }
        end
      end
    end
  end
  
  footer(z_wlk)
end




return {
  name = "Picture to g-code",
  type = "plugin", 
  gui = "button",
  image = nil,
  symbol = "\u{e02c}",
  
  params = {
    ["<ImageLoader>"] = "",
    --Size = 50,
    Frequency = 40,
    ["Walk Z"] = 10,
    Depth = 5,
    Passes = 5,
    --["Step (deg)"] = 5,
    --["Shaft diam"] = 10,
  },
  
  exec = function(self, pars)
    --for k,v in pairs(pars) do
    --  print("exec ", k, v)
    --end
    image(pars)
  end,
}
