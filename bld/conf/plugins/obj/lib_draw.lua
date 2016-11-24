-------------------------
-- copyright by bhgv 2016
-------------------------


local lib2d = require "conf.plugins.obj.lib_2d"




local function draw_scanlines(g, o, slice_lns, is_outside, sl_step, kx, ky, kz, z, z_wlk)
  if is_outside ~= 0 and is_outside ~= 1 then return end
  
  local y
  local y_stp = sl_step / ky
  local i = 1

  for y = o.min.y, o.max.y, y_stp  do
    local sl4y = lib2d.slice2scanline(slice_lns, y)
    
    local j, x
    local x_fr, x_to, x_st, x_b, x_e
    if i&1 == 1 then
      x_fr = 1
      x_to = #sl4y
      x_st = 1
      x_b = o.min.x
      x_e = o.max.x
    else
      x_fr = #sl4y
      x_to = 1
      x_st = -1
      x_e = o.min.x
      x_b = o.max.x
    end
    
    if is_outside == 1 then
      g:walk_to{x = x_b * kx, y = y * ky}
      --g.lib.process(g, "walk", z_wlk, {x = o.min.x * kx, y = y * ky} )
      g:work_to{z = z * kz}
      --g.lib.process(g, "work", z * kz, {x = o.min.x * kx, y = y * ky} )
    end

--    for j,x in ipairs(sl4y) do
    for j = x_fr, x_to, x_st do
      x = sl4y[j]
      if (j & 1) == is_outside then
        g:work_to{x = x * kx, y = y * ky}
        --g.lib.process(g, "work", z * kz, {x = x * kx, y = y * ky} )
      else
        g:walk_to{z = z_wlk}
        --g.lib.process(g, "walk", z_wlk, {} )
        g:walk_to{x = x * kx, y = y * ky}
        --g.lib.process(g, "walk", z_wlk, {x = x * kx, y = y * ky} )
        g:work_to{z = z * kz}
        --g.lib.process(g, "work", z * kz, {x = x * kx, y = y * ky} )
      end
    end
    if is_outside == 1 then
      g:work_to{x = x_e * kx, y = y * ky}
      --g.lib.process(g, "work", z * kz, {x =  o.max.x * kx, y = y * ky} )
    end
    g:walk_to{z = z_wlk}
    --g.lib.process(g, "walk", z_wlk, {} )
    
    i = i + 1
  end
end


local function draw_contour(g, slice_lns, kx, ky, kz, z, z_wlk)
  local ln = slice_lns[1]
  local ln_p = ln[2]
  
  g:walk_to {x = ln[1].x * kx, y = ln[1].y * ky, }
  --g.lib.process(g, "walk", z_wlk, {x = ln[1].x * kx, y = ln[1].y * ky, } )
  g:work_to {z = z * kz, }
  --g.lib.process(g, "work", z * kz, {} )
  g:work_to {x = ln[2].x * kx, y = ln[2].y * ky, }
  --g.lib.process(g, "work", z * kz, {x = ln[2].x * kx, y = ln[2].y * ky, } )
  
  for i = 2,#slice_lns do
    ln = slice_lns[i]
    
    if lib2d.get_l(ln_p, ln[1]) > 0.2 then
      g:walk_to{z = z_wlk}
      --g.lib.process(g, "walk", z_wlk, {} )
      g:walk_to {x = ln[1].x * kx, y = ln[1].y * ky, }
      --g.lib.process(g, "walk", z_wlk, {x = ln[1].x * kx, y = ln[1].y * ky, } )
      g:work_to {z = z * kz }
      --g.lib.process(g, "work", z * kz, {} )
    else
      g:work_to {x = ln[1].x * kx, y = ln[1].y * ky, }
      --g.lib.process(g, "work", z * kz, {x = ln[1].x * kx, y = ln[1].y * ky, } )
    end
    g:work_to {x = ln[2].x * kx, y = ln[2].y * ky, }
    --g.lib.process(g, "work", z * kz, {x = ln[2].x * kx, y = ln[2].y * ky, } )
    ln_p = ln[2]
  end
  g:walk_to {z = z_wlk }
  --g.lib.process(g, "walk", z_wlk, {} )
end


return {
  draw_scanlines = draw_scanlines,
  draw_contour = draw_contour,
}

