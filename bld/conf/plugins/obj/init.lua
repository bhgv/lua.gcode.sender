-------------------------
-- copyright by bhgv 2016
-------------------------

local obj = require "luaObj"

local g = require "conf.gen.gcode"



local cos = function(a)
  return math.cos(math.rad(a))
end
local sin = function(a)
  return math.sin(math.rad(a))
end


local function calculate_slice(o, z)
  local verts = o.verts
  
  local slice_lns = {}
  
  local pth = {}
  
  local v_eq = {}
  local v_eq_msk = {}
  local v_big = {}
  local v_big_msk = {}
  local v_sml = {}
  local v_sml_msk = {}
  
  local f_tr = {}
  local f_tr_msk = {}
  
  local i,v
  for i,v in ipairs(verts) do 
    if v.z < z then
      v_sml_msk[i] = true
      table.insert(v_sml, i)
    elseif v.z > z then
      v_big_msk[i] = true
      table.insert(v_big, i)
    else
      v_eq_msk[i] = true
      table.insert(v_eq, i)
    end
  end
  
  local j,f
    
  local f_p_cmp_aux = function(p)
    if v_sml_msk[p] then return -1 
    elseif v_big_msk[p] then return 1
    else return 0
    end
  end

  for j,f in ipairs(o.faces) do
    local sem = f_p_cmp_aux(f.p1) + f_p_cmp_aux(f.p2) + f_p_cmp_aux(f.p3)
    
    if sem > -3 and sem < 3 then
      f_tr_msk[j] = true
      table.insert(f_tr, f)
    end
  end
  
  
  local calc_ln_v = function(p1, p2, z)
    -- (x-x1)/(x2-x1)=(y-y1)/(y2-y1)=(z-z1)/(z2-z1)
    local v1 = verts[p1]
    local v2 = verts[p2]
    local dz = (v2.z - v1.z)
    if dz == 0.0 then dz = 0.01 end
    
    v = {
      x = v1.x + (v2.x - v1.x)*(z - v1.z) / dz,
      y = v1.y + (v2.y - v1.y)*(z - v1.z) / dz,
      z = z,
    }
    
    return v
  end
  
  for j,f in ipairs(f_tr) do
    local s1 = f_p_cmp_aux(f.p1)
    local s2 = f_p_cmp_aux(f.p2)
    local s3 = f_p_cmp_aux(f.p3)
    
    local ln = {}
    
    if s1*s2 <= 0 then 
      table.insert(ln, calc_ln_v(f.p1, f.p2, z) )
    end
    if s1*s3 <= 0 then 
      table.insert(ln, calc_ln_v(f.p1, f.p3, z) )
    end
    if s2*s3 <= 0 then 
      table.insert(ln, calc_ln_v(f.p2, f.p3, z) )
    end
    
    table.insert(slice_lns, ln)
  end
  
  return slice_lns
end





local G_z_wlk, G_z_cur


local ent_tab = {
    point = function(e)
        g:walk_to{x = e.b.x, y = e.b.y}
        g:work_to{z = G_z_cur}
    end,
    line = function(e)
        g:walk_to{x = e.b.x, y = e.b.y}
        g:work_to{z = G_z_cur}
        g:work_to{x = e.e.x, y = e.e.y}
    end,
    solid = function(e)
        g:walk_to{x = e.p1.x, y = e.p1.y}
        g:work_to{z = G_z_cur}
        g:work_to{x = e.p2.x, y = e.p2.y}
        g:work_to{x = e.p3.x, y = e.p3.y}
        g:work_to{x = e.p4.x, y = e.p4.y}
    end,
    circle = function(e)
        local ang
        local c = e.b
        local r = e.r

        g:walk_to{x = c.x + r, y = c.y}
        g:work_to{z = G_z_cur}

        for ang = 10,360,10 do
            g:work_to{x = c.x + r*cos(ang), y = c.y + r*sin(ang)}
        end
    end,
    arc = function(e)
        local ang
        local c = e.b
        local r = e.r
        
        local ba = e.ba
        local ea = e.ea
        print("ba,ea = ", ba, ea, e.isccw)

        g:walk_to{x = c.x + r*math.cos(ba), y = c.y + r*math.sin(ba)}
        g:work_to{z = G_z_cur}

        for ang = ba,ea,math.pi/18 do
            g:work_to{x = c.x + r*math.cos(ang), y = c.y + r*math.sin(ang)}
        end
        g:work_to{x = c.x + r*math.cos(ea), y = c.y + r*math.sin(ea)}
    end,
    polyline = function(e)
        local pts = e.points
        if pts and #pts > 0 then
            g:walk_to{x = pts[1].x, y = pts[1].y}
            g:work_to{z = G_z_cur}
            local i
            for i = 2,#pts do
                g:work_to{x = pts[i].x, y = pts[i].y}
            end
        end
    end,
}


local function entity(e)
    if e and e.type then
        local foo = ent_tab[e.type]
        if foo then
            g:walk_to{z = G_z_wlk}
            foo(e)
        end
    end
end


  local function get_l(v1, v2)
    local v1x, v1y, v1z = v1.x, v1.y, v1.z
    local v2x, v2y, v2z = v2.x, v2.y, v2.z
    local dx, dy, dz = (v2x - v1x), (v2y - v1y), (v2z - v1z)
    
    return math.sqrt(dx*dx + dy*dy + dz*dz)
  end


local function sort_lns(lns_in)
  local lns_out = {}
  local min_l
  local min_i
  local min_p
  
  local i --= 1
  local ln, ln_p
  
  if #lns_in < 1 then return {} end
  
  ln = lns_in[1]
  table.remove(lns_in, 1)
  table.insert(lns_out, ln)
  ln_p = ln[2]
    
  while #lns_in > 0 do
    min_l, min_i, min_p = math.huge, math.maxinteger, math.maxinteger
    
    i = 1
    while i <= #lns_in do
      local tln = lns_in[i]
      
      local l1 = get_l(ln_p, tln[1])
      local l2 = get_l(ln_p, tln[2])
      --print(i, l1, l2, tln[1], tln[2], ln_p)
      
      if l1 < l2 and l1 < min_l then
        min_l = l1
        min_i = i
        min_p = 2
      elseif l2 < min_l then
        min_l = l2
        min_i = i
        min_p = 1
      end
      
      i = i + 1
    end
    --print(min_i, #lns_in)
    ln = lns_in[min_i]
    ln_p = ln[min_p]
    if ln_p == 1 then
      ln[1], ln[2] = ln[2], ln[1]
    end
    table.remove(lns_in, min_i)
    table.insert(lns_out, ln)

  end
  
  return lns_out
end



local function parse_obj(pars)  
  local sizeW = tonumber(pars['Size W']) or 10
  local sizeH = tonumber(pars['Size H']) or 10
    
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars['Size Z']) or 5
  local dz  = tonumber(pars['Step of depth (Z)']) or 5
  local frq = tonumber(pars.Frequency) or 40
  --local n_pas = tonumber(pars.Passes) or 10
  
  local obj_f_name = pars['<FILE><NAME>Obj file<MASK>%.[Oo][Bb][Jj]$']

--  local x0, y0 =
--            r_bigger + r_smaller,
--            r_bigger / math.sqrt(2)

  local z
  

    
  local f = io.open(obj_f_name, "r")
  if not f then return end

  f:close()

  local i, j, k, l
  

  local o = obj.do_parse(obj_f_name)
  if not o then return end
  
  collectgarbage()
  
  G_z_wlk = z_wlk
  G_z_cur = 0

  g.lib.header(g, frq)
  g:walk_to{z = z_wlk}

  local i, v, j, f
  local tdz = (o.max.z - o.min.z)*dz / z_end
  
  local kx = sizeW / (o.max.x - o.min.x)
  local ky = sizeH / (o.max.y - o.min.y)
  local kz = z_end / (o.max.z - o.min.z)
  --print("k", kx, ky, kz, tdz)

  local i = 0
  local ln_p, ln
  for z = o.max.z, o.min.z, -tdz do
    --print(i, z, dz)
    i = i + 1
    local slice_lns = sort_lns(  calculate_slice(o, z)  )
    if #slice_lns > 0 then
      ln = slice_lns[1]
      ln_p = ln[2]
      
      g:walk_to {x = ln[1].x * kx, y = ln[1].y * ky, }
      g:work_to {z = -(o.max.z - z) * kz, }
      g:work_to {x = ln[2].x * kx, y = ln[2].y * ky, }
      
      for i = 1,#slice_lns do
        local ln = slice_lns[i]
        
        if get_l(ln_p, ln[1]) > 0.1 then
          g:walk_to{z = z_wlk}
          g:walk_to {x = ln[1].x * kx, y = ln[1].y * ky, }
          g:work_to {z = -(o.max.z - z) * kz }
        else
          g:work_to {x = ln[1].x * kx, y = ln[1].y * ky, }
        end
        g:work_to {x = ln[2].x * kx, y = ln[2].y * ky, }
        ln_p = ln[2]
      end
      g:walk_to {z = z_wlk }
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
