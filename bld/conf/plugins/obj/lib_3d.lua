-------------------------
-- copyright by bhgv 2016
-------------------------


local obj = require "luaObj"


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






return {
  obj = obj,
  calculate_slice = calculate_slice,
  
}

