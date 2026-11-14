local transform = require "conf.utils.transform_coords"

return function(bounds)
  local out = {xmin=math.huge,ymin=math.huge,zmin=math.huge,
    xmax=-math.huge,ymax=-math.huge,zmax=-math.huge}
  for _,x in ipairs{bounds.xmin,bounds.xmax} do
    for _,y in ipairs{bounds.ymin,bounds.ymax} do
      for _,z in ipairs{bounds.zmin,bounds.zmax} do
        local p = transform{x=x,y=y,z=z}
        for _,axis in ipairs{'x','y','z'} do
          out[axis..'min'] = math.min(out[axis..'min'],p[axis])
          out[axis..'max'] = math.max(out[axis..'max'],p[axis])
        end
      end
    end
  end
  return out
end
