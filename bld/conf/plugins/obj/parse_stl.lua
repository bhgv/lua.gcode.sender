
------------------------------------------------------------
-- stl reader algo from http://lua-users.org/wiki/StlToObj



local function minmax(x, y, z, min, max)
  if x < min.x then min.x = x end
  if y < min.y then min.y = y end
  if z < min.z then min.z = z end

  if x > max.x then max.x = x end
  if y > max.y then max.y = y end
  if z > max.z then max.z = z end
end


local function parse_stl(stl_filename)
  local verts = {}
  local faces = {}
  local normals = {}
  local v_i = 1
  
  --local x, y, z
  local min = {
    x = math.huge,
    y = math.huge,
    z = math.huge,
  }
  local max = {
    x = -math.huge,
    y = -math.huge,
    z = -math.huge,
  }
  --/////////////////////////////////////////////////////////////////
  -- parse stl file
  local file_stl = io.open(stl_filename, "r")

  local cur_face = {}
  local count = 0
  for line in file_stl:lines() do
    if string.find(line, "^%s*facet normal") then
      local x,y,z = string.match(line, "(%S+)%s(%S+)%s(%S+)$")
      x, y, z = tonumber(x), tonumber(y), tonumber(z)
      minmax(x, y, z, min, max)
      
      table.insert( normals, {x = x, y = y, z = z} )
      --table.insert( cur_face, #verts)
    end
    if string.find(line, "^%s*vertex") then
      local x,y,z = string.match(line, "(%S+)%s(%S+)%s(%S+)$")
      x, y, z = tonumber(x), tonumber(y), tonumber(z)
      minmax(x, y, z, min, max)
      
      table.insert( verts, {x = x, y = y, z = z} )
      table.insert( cur_face, #verts)
      count = count + 1
      
      if count == 3 then
        table.insert(faces, 
                    {
                      p1 = cur_face[1], 
                      p2 = cur_face[2], 
                      p3 = cur_face[3], 
                    }
        )
        cur_face = {}
        count = 0
      end
      
    end
  end
  file_stl:close()

  return { verts = verts, faces = faces, normals = normals, min = min, max = max, }
end


return parse_stl

