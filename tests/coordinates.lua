package.path='./bld/?.lua;./bld/?/init.lua;' .. package.path
package.loaded['tek.ui']={}
Flags={ApproximateArcs=true,Transformations={Scale={x=1,y=1,z=1},Move={x=0,y=0,z=0},Rotate=0}}
Display={}
require 'conf.gparser'
local function parse(s) GTXT:load(s); local ok,err=do_vparse(); assert(ok,err) end
local function near(a,b) assert(math.abs(a-b)<0.0001) end
parse('G0 X10 Y20\nG92 X0\nG1 X1\nG91 X2\nG92.1\nG90 X5')
assert(#Display.Points==4)
near(Display.Points[2].x,11);near(Display.Points[3].x,13);near(Display.Points[4].x,5)
assert(GTXT_parsed[2]:match('G92 ') and GTXT_parsed[2]:match('X0%.0000'))
assert(GTXT_parsed[3]:match('X1%.0000'))
Flags.Transformations.Rotate=math.pi/2
Flags.Transformations.Move={x=100,y=200,z=0}
parse('G0 X10\nG92 X0\nG1 X2')
near(Display.Points[2].x,12)
assert(GTXT_parsed[2]:match('X100%.0000') and GTXT_parsed[2]:match('Y200%.0000'))
assert(GTXT_parsed[3]:match('Y202%.0000'))
Flags.Transformations.Rotate=0
Flags.Transformations.Move={x=0,y=0,z=0}
parse('G20 G0 X1\nG92 X0\nG21 G1 X25.4')
near(Display.Points[2].x,50.8)
parse('G0 X10\nG92 X1\nG3 X0 Y1 I-1 J0')
near(Display.Points[#Display.Points].x,9)
local previous=GTXT_parsed
GTXT:load('G53 G0 X0')
local ok,err=do_vparse()
assert(not ok and err:match('G53') and GTXT_parsed==previous)
parse('F2 G20 G0 X1\nG21\n\nG1 X50.8')
assert(type(Flags.ModalStates)=='userdata')
assert(Flags.ModalStates[4]:match('G21') and Flags.ModalStates[4]:match('F50%.800000'))
local sent={}
Sender={newcmd=function(_,s) sent[#sent+1]=s end}
do_sparse(4,4)
assert(sent[4]:match('G21') and sent[4]:match('G90') and sent[4]:match('G94'))
assert(sent[4]:match('F50%.800000') and not sent[4]:match('X'))
assert(sent[7]:match('X50%.8000'))
parse('G0 X10\nG92 X0\nG1 X1')
sent={}
assert(not pcall(do_sparse,3,3) and #sent==0)
parse('G0 X10\nG92 X0\nG92.1\nG1 X1')
do_sparse(4,4)
assert(#sent>0)
GTXT:load('G55 G0 X1')
assert(not do_vparse())
print('G92 coordinate-frame and range-state tests passed')
