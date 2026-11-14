package.path='./bld/?.lua;./bld/?/init.lua;' .. package.path
package.loaded['tek.ui']={}
Flags={ApproximateArcs=true,ArcTolerance=0.01,Transformations={
  Move={x=0,y=0,z=0},Scale={x=1,y=1,z=1},Rotate=0,Mirror={h=false,v=false},
}}
Display={}
require 'conf.gparser'
local function parse(source)
  GTXT:load(source)
  local ok,err=do_vparse()
  assert(ok,err)
end
local function near(a,b) assert(math.abs(a-b)<0.00011,tostring(a)..' != '..tostring(b)) end
parse('G0 X1 Y0\nG3 X0 Y1 I-1 J0 F100')
assert(#Display.Points>10 and GTXT_parsed[2]:match('G1'))
assert(not GTXT_parsed[2]:match('[IJR]'))
near(Display.Bnd.xmax,1);near(Display.Bnd.ymax,1)
local count=#Display.Points
Flags.ArcTolerance=0.00001
parse('G0 X1 Y0\nG3 X0 Y1 I-1 J0 F100')
assert(#Display.Points>count)
Flags.ArcTolerance=0.01
parse('G0 X1 Y0\nG2 I-1 J0 Z2')
near(Display.Bnd.xmin,-1);near(Display.Bnd.ymin,-1)
near(Display.Bnd.xmax,1);near(Display.Bnd.ymax,1)
near(Display.Bnd.zmin,0);near(Display.Bnd.zmax,2)
parse('G0 X1 Y0\nG3 X0 Y1 R1')
local minor=#Display.Points
parse('G0 X1 Y0\nG3 X0 Y1 R-1')
assert(#Display.Points>minor)
parse('G0 X1 Y0\nG91 G2 I-1 J0 Z2')
local x,y,z=0,0,0
for line in GTXT_parsed[2]:gmatch('[^\n]+') do
  x=x+tonumber(line:match('X([%d%.%-]+)'))
  y=y+tonumber(line:match('Y([%d%.%-]+)'))
  z=z+tonumber(line:match('Z([%d%.%-]+)'))
end
near(x,0);near(y,0);near(z,2)
Flags.Transformations.Scale.x=2
parse('G0 X1 Y0\nG3 X0 Y1 I-1 J0') -- Ellipse is representable as G1.
Flags.ApproximateArcs=false
assert(not do_vparse()) -- It cannot be sent as a circular G2/G3.
Flags.Transformations.Scale.x=1
Flags.Transformations.Rotate=math.pi/2
Flags.Transformations.Move={x=100,y=200,z=0}
parse('G0 X1 Y0\nG3 X0 Y1 I-1 J0')
assert(GTXT_parsed[2]:match('G3') and GTXT_parsed[2]:match('J%-1%.0000'))
Flags.Transformations.Mirror.h=true
parse('G0 X1 Y0\nG3 X0 Y1 I-1 J0\nG2 X1 Y0 I0 J-1')
assert(GTXT_parsed[2]:match('G2') and GTXT_parsed[3]:match('G3'))
Flags.ApproximateArcs=true
Flags.Transformations.Mirror.h=false
Flags.Transformations.Rotate=0
Flags.Transformations.Move={x=0,y=0,z=0}
parse('G0 X1 Y0\nG3 X0 Y1 I-1 J0')
local sent={}
Sender={newcmd=function(_,s) sent[#sent+1]=s end}
do_sparse(2,2)
assert(sent[2]=='SOURCE' and sent[3]=='2')
assert(sent[4]:match('G1') and not sent[4]:match('\n'))
assert(#sent>10 and sent[#sent]=='CALCULATE')
local previous=GTXT_parsed
GTXT:load('G0 X1 Y0\nG3 X0 Y1 R0.1')
assert(not do_vparse() and GTXT_parsed==previous)
GTXT:load('G0 X1 Y0\nG18 G3 X0 Y1 I-1 J0')
assert(not do_vparse())
GTXT:load('G0 X1 Y0\nG93 G3 X0 Y1 I-1 J0 F1')
assert(not do_vparse())
Flags.ApproximateArcs=true
parse('G2\nG0 X1 Y0\nG3 X0 Y1 I-1 J0')
assert(GTXT_parsed[1]:match('G1') and not GTXT_parsed[1]:match('G2'))
local bounds=require 'conf.utils.transform_bounds'
Flags.Transformations.Rotate=math.pi/4
local b=bounds{xmin=0,xmax=2,ymin=0,ymax=1,zmin=0,zmax=0}
assert(b.xmin<0 and b.xmax>1 and b.ymax>2)
Flags.Transformations.Mirror.h=true
b=bounds{xmin=0,xmax=2,ymin=0,ymax=1,zmin=0,zmax=0}
assert(b.xmin<=b.xmax and b.ymin<=b.ymax)
Flags.Transformations.Mirror.h=false
Flags.Transformations.Rotate=0
Flags.Transformations.Move={x=0,y=0,z=0}
parse('G20 G0 X1 Y0\nG3 X0 Y1 I-1 J0\nG21 G1 X25.4 Y0')
near(Display.Points[#Display.Points].x,25.4)
near(Display.Bnd.ymax,25.4)
assert(GTXT_parsed[3]:match('X25%.4000'))
Flags.ApproximateArcs=false
parse('G20 G0 X1 Y0\nG3 X0 Y1 I-1 J0')
assert(GTXT_parsed[2]:match('I%-1%.0000') and GTXT_parsed[2]:match('Y1%.0000'))
parse('G21 G0 X25.4\nG20 G91 G1 X1')
near(Display.Points[2].x,50.8)
assert(GTXT_parsed[2]:match('X1%.0000'))
print('arc geometry, transforms and approximation tests passed')
