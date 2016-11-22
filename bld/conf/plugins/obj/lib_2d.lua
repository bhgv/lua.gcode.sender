-------------------------
-- copyright by bhgv 2016
-------------------------


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
    if min_p == 1 then
      ln[1], ln[2] = ln[2], ln[1]
    end
    table.remove(lns_in, min_i)
    table.insert(lns_out, ln)

  end
  
  return lns_out
end



local function slice2scanline(slice, y)
  local sl4y = {}
  local i, ln, x
  
  for i,ln in ipairs(slice) do
    local t = (ln[1].y - y) * (ln[2].y - y)
    if t <= 0 then
      t = ln[2].y - ln[1].y
      if t == 0 then t = 0.001 end
      x = ln[1].x + (y - ln[1].y)*(ln[2].x - ln[1].x) / t
      table.insert(sl4y, x)
    end
  end
  table.sort(sl4y)
  
  return sl4y
end


return {
  get_l = get_l,
  sort_lns = sort_lns,
  slice2scanline = slice2scanline,
}

