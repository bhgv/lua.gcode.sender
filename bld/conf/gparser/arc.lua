local tau = math.pi * 2

local function sweep(a, b, clockwise)
  local value = (b - a) % tau
  if clockwise then value = value - tau end
  return value
end

return function(start, finish, words, clockwise, tolerance)
  local cx, cy
  local a, angle, radius
  if words.r then
    assert(not words.i and not words.j, "Arc cannot combine R with I/J")
    local dx, dy = finish.x - start.x, finish.y - start.y
    local distance = math.sqrt(dx*dx + dy*dy)
    radius = math.abs(words.r)
    assert(distance > 0 and radius > 0 and distance <= radius*2, "Invalid arc radius")
    local height = math.sqrt(math.max(0, radius*radius - distance*distance/4))
    for _, sign in ipairs{1, -1} do
      cx = (start.x + finish.x)/2 - sign*dy*height/distance
      cy = (start.y + finish.y)/2 + sign*dx*height/distance
      a = math.atan(start.y - cy, start.x - cx)
      angle = sweep(a, math.atan(finish.y - cy, finish.x - cx), clockwise)
      if (words.r >= 0 and math.abs(angle) <= math.pi + 1e-10)
        or (words.r < 0 and math.abs(angle) >= math.pi - 1e-10) then break end
    end
  else
    assert(words.i or words.j, "Arc requires I/J or R")
    cx, cy = start.x + (words.i or 0), start.y + (words.j or 0)
    radius = math.sqrt((start.x-cx)^2 + (start.y-cy)^2)
    assert(radius > 0, "Invalid arc center")
    local end_radius = math.sqrt((finish.x-cx)^2 + (finish.y-cy)^2)
    assert(math.abs(radius-end_radius) <= math.max(0.002, radius*0.001), "Arc endpoints have different radii")
    a = math.atan(start.y-cy, start.x-cx)
    angle = sweep(a, math.atan(finish.y-cy, finish.x-cx), clockwise)
    if math.abs(angle) < 1e-10 then angle = clockwise and -tau or tau end
  end
  local fractions = {}
  tolerance = tolerance or 0.01
  assert(tolerance > 0 and tolerance < math.huge, "Invalid arc tolerance")
  local step = 2*math.acos(math.max(-1, 1-math.min(tolerance/radius, 2)))
  assert(step > 0, "Arc tolerance is too small")
  local count = math.max(1, math.ceil(math.abs(angle)/math.min(math.pi/36,step)))
  assert(count <= 100000, "Arc approximation requires too many segments")
  for i=1,count do fractions[#fractions+1] = i/count end
  -- Include extrema exactly, rather than estimating bounds from chord endpoints.
  for i=0,3 do
    local delta = sweep(a, i*math.pi/2, clockwise)
    local t = delta/angle
    if t > 0 and t < 1 then fractions[#fractions+1] = t end
  end
  table.sort(fractions)
  local points = {}
  for _,t in ipairs(fractions) do
    local theta = a + angle*t
    points[#points+1] = {x=cx+radius*math.cos(theta), y=cy+radius*math.sin(theta), z=start.z+(finish.z-start.z)*t,fraction=t}
  end
  points[#points] = {x=finish.x,y=finish.y,z=finish.z,fraction=1}
  return points
end
