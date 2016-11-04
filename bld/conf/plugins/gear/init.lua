
local g = require "conf.gen.gcode"


local cos = function(a)
  return math.cos(math.rad(a))
end
local sin = function(a)
  return math.sin(math.rad(a))
end




	----------------------------------------------------------------------
local function involute_intersect_angle(Rb, R)
		return math.sqrt(R*R - Rb*Rb) / Rb - math.acos(Rb/R)
end

	----------------------------------------------------------------------
local function point_on_circle(radius, angle)
		return {x = radius * math.cos(angle), y = radius * math.sin(angle) }
end

	----------------------------------------------------------------------
	-- N   = no of teeth
	-- phi = pressure angle
	-- PC  = Circular Pitch
	----------------------------------------------------------------------
local function calc(N, phi, Pc)
		-- Pitch Circle
		local D = N * Pc / math.pi
		local R = D / 2.0

		-- Diametrical pitch
		local Pd = N / D

		-- Base Circle
		local Db = D * math.cos(phi)
		local Rb = Db / 2.0

		-- Addendum
		local a = 1.0 / Pd

		-- Outside Circle
		local Ro = R + a
		local Do = 2.0 * Ro

		-- Tooth thickness
		local T = math.pi*D / (2*N)

		-- undercut?
		local U = 2.0 / (math.sin(phi) * (math.sin(phi)))
		local needs_undercut = N < U
		-- sys.stderr.write("N:%s R:%s Rb:%s\n" % (N,R,Rb))

		-- Clearance
		local c = 0.0
		-- Dedendum
		local b = a + c

		-- Root Circle
		local Rr = R - b
		local Dr = 2.0*Rr

		local two_pi = 2.0*math.pi
		local half_thick_angle = two_pi / (4.0*N)
		local pitch_to_base_angle = involute_intersect_angle(Rb, R)
		local pitch_to_outer_angle = involute_intersect_angle(Rb, Ro) -- pitch_to_base_angle

		local points = {}
    local x
		for x = 1,N do
			c = x * two_pi / N

			-- angles
			local pitch1 = c - half_thick_angle
			local base1  = pitch1 - pitch_to_base_angle
			local outer1 = pitch1 + pitch_to_outer_angle

			local pitch2 = c + half_thick_angle
			local base2  = pitch2 + pitch_to_base_angle
			local outer2 = pitch2 - pitch_to_outer_angle

			-- points
			local b1 = point_on_circle(Rb, base1)
			local p1 = point_on_circle(R,  pitch1)
			local o1 = point_on_circle(Ro, outer1)
			local o2 = point_on_circle(Ro, outer2)
			local p2 = point_on_circle(R,  pitch2)
			local b2 = point_on_circle(Rb, base2)

			if Rr >= Rb then
				local pitch_to_root_angle = pitch_to_base_angle - involute_intersect_angle(Rb, Rr)
				local root1 = pitch1 - pitch_to_root_angle
				local root2 = pitch2 + pitch_to_root_angle
        
				local r1 = point_on_circle(Rr, root1)
				local r2 = point_on_circle(Rr, root2)

				table.insert(points, r1)
				table.insert(points, p1)
				table.insert(points, o1)
				table.insert(points, o2)
				table.insert(points, p2)
				table.insert(points, r2)
			else
				local r1 = point_on_circle(Rr, base1)
				local r2 = point_on_circle(Rr, base2)
        
				table.insert(points, r1)
				table.insert(points, b1)
				table.insert(points, p1)
				table.insert(points, o1)
				table.insert(points, o2)
				table.insert(points, p2)
				table.insert(points, b2)
				table.insert(points, r2)
      end
    end

    return points
end


local function draw_gear_pass(x0, y0, points, z)
  local pt1 = points[1]
  
  g:walk_to{x = x0 + pt1.x, y = y0 + pt1.y } 
  g:work_to{z = z}
  
  local i
  for i = 2,#points do
    local pt = points[i]
		g:work_to{x = pt.x, y = y0 + pt.y }
  end
  g:work_to{x = x0 + pt1.x, y = y0 + pt1.y } 
end


local function draw_shaft_pass(x0, y0, z, shft_r, step_deg)
  local a
  
  g:walk_to{x = x0 - shft_r, y = y0 + 0 } -- to begin
  g:walk_to{z = z} -- to walk pos

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




local gear_simple = function(pars)
  local N = tonumber(pars["N teeth"]) --or 10
  local Cs = tonumber(pars["Circular step"]) --or 10
  local phi = tonumber(pars["Pressure angle"]) --or 0
  phi = math.pi * phi / 180
  
  local z_wlk = tonumber(pars["Walk Z"]) or 10
  local z_end = tonumber(pars.Depth) or 5
  local frq = tonumber(pars.Frequency) or 40
  local n_pas = tonumber(pars.Passes) or 10
  
  local dz = z_end / n_pas
  local z_cur
  
  local shft_dia = tonumber(pars["Shaft diam"]) or 10
  
  local x0, y0 =
            0,
            0
  
  
  local pts = calc(N, phi, Cs) -- (N, phi, Pc)
  
  header(frq)
  g:walk_to{z = z_wlk} -- to walk pos

  for z_cur = 0, z_end, dz do
    draw_shaft_pass(x0, y0, -z_cur, shft_dia/2, 5)
  end
  g:walk_to{z = z_wlk} -- to walk pos

  for z_cur = 0, z_end, dz do
    draw_gear_pass(x0, y0, pts, -z_cur)
  end
  
  footer(z_wlk)
end




return {
  name = "simple Gear",
  type = "plugin", 
  gui = "button",
  image = nil,
  symbol = "\u{e041}",
  
  params = {
    ["N teeth"] = 10,
    ["Circular step"] = 5,
    ["Pressure angle"] = 0,
    Frequency = 40,
    ["Walk Z"] = 10,
    Depth = 5,
    Passes = 5,
    ["Shaft diam"] = 8,
  },
  
  exec = function(self, pars)
    --for k,v in pairs(pars) do
    --  print("exec ", k, v)
    --end
    gear_simple(pars)
  end,
}
