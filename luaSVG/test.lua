
print(arg[1])

f = io.open(arg[1], "r")
txt = f:read("*a")
f:close()

svg = require "luaSVG"

o = svg.do_parse(txt)

for i,v in ipairs(o) do
  print("\n",i,v,"\n-----------------------")
  for k,vv in ipairs(v) do
    print(k,vv,"\nooooo")
    for l,vvv in pairs(vv) do
      for m,vvvv in pairs(vvv) do
        print(m, vvvv, vvvv.x, vvvv.y)
      end
    end
  end
end



