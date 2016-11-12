
dxf = require "luaDXF2"


--for k,v in pairs(dxf) do
--    print(k, v)
--end

fn = arg[1]
if fn then

    local o = dxf.do_parse(fn)

print(#o, o)
    for i,v in pairs(o) do
print(i,v.type)
--	if v.type == "point" then
--	    print(i,v.type, v.b.x, v.b.y)
--	elseif v.type == "line" then
--	    print(i,v.type, v.b.x, v.b.y, "-->", v.e.x, v.e.y)
--	end
    end

    for i,v in ipairs(o) do
	print(i,v.type,"\n---- FACES -----")
	for ii,vv in ipairs(v.faces) do
	    print(ii, vv.type)
	    for iii,vvv in ipairs(vv) do
		print(iii, vvv.x, vvv.y, vvv.z)
	    end
	end
	print("---- LINES -----")
	for ii,vv in ipairs(v.lines) do
	    print(ii, vv.type)
	    for iii,vvv in ipairs(vv) do
		print(iii, vvv.x, vvv.y, vvv.z)
	    end
	end
    end
end

print("end prog")
