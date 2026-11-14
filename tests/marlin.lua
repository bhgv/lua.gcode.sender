package.path='./bld/?.lua;./bld/?/init.lua;' .. package.path
local chunks,writes={},{}
local port={write=function(_,s) writes[#writes+1]=s end,read=function() return table.remove(chunks,1) or '' end}
package.loaded['periphery']={Serial=function() return port end}
package.loaded['lfs']={attributes=function() return {} end}
package.loaded['tek.lib.exec']={sendmsg=function() end}
package.loaded['tek.ui']={}
for _,name in ipairs{'StatPort_contents','ControlButtons_add','FileButtons_add','TerminalButtons_add'} do
  package.loaded['conf.controllers.marlin.' .. name]={}
end
local m=require 'conf.controllers.marlin'
assert(m:open('mock',115200))
local function receive(s) chunks[#chunks+1]=s; return m:read() end
m:send('M117 Mixed Case\n')
assert(writes[#writes]=='M117 Mixed Case\n' and not m.out_access)
assert(not receive('o').msg)
assert(receive('k N12 P15 B127\r\n').ok and m.out_access)
m:status_query();assert(writes[#writes]=='M114\n')
local n=#writes;m:status_query();assert(#writes==n)
local r=receive('X:1 Y:-2.5 Z:3 E:4.2 Count X:80 Y:-200 Z:1200\n')
assert(r.stat and not r.ok and not m.out_access)
local s=m:status_parse(r.msg).stat
assert(s.wX==1 and s.wY==-2.5 and s.ePos==4.2 and s.mX==nil)
assert(not m:read().msg)
assert(receive('ok\n').ok and m.out_access)
m:status_query();assert(writes[#writes]=='M105\n')
r=receive('ok T:200.5 /210 B:59 /60 T0:200.5 /210 T1:21 /0 @:30\n')
assert(r.ok and r.stat and m.out_access)
s=m:status_parse(r.msg).stat
assert(s.tCur==200.5 and s.tDst==210 and s.BCur==59 and s.BDst==60 and s.T1Cur==21)
assert(next(m:status_parse('Count X:80 Y:90 Z:100').stat)==nil)
m:send('M109 S210\n')
assert(receive('echo:busy: processing\n').msg and not m.out_access)
assert(receive('T:205 /210 B:60 /60\n').stat and not m.out_access)
n=#writes;m:status_query();assert(#writes==n)
assert(receive('ok\n').ok and m.out_access)
m:send('M9999\n')
assert(receive('echo:Unknown command: "M9999"\n').err and not m.out_access)
assert(receive('ok\n').ok and m.out_access)
m:send('G1 X1\n')
m:pause();n=#writes;m:resume();assert(#writes==n)
m:stop()
assert(writes[#writes-1]=='M108\n' and writes[#writes]=='M410\n')
receive('ok\nok\nok\n');m:read();m:read();assert(m.out_access)
m:send('M0\n')
assert(receive('echo:busy: paused for user\n').action=='pause' and not m.out_access)
m:resume();assert(writes[#writes]=='M108\n')
receive('ok\nok\n');m:read();assert(m.out_access)
assert(receive('//action:pause\n').action=='pause')
assert(receive('//action:resume\n').action=='resume')
assert(receive('//action:cancel\n').action=='cancel')
m:emergency();assert(writes[#writes]=='M112\n' and not m.out_access)
receive('ok\n');assert(not m.out_access)
assert(not pcall(function() m:send('G0 X0\n') end))
assert(receive('start\n').err and m.out_access)
m:send('G1 X2\n')
assert(receive('Resend: 5\n').err and not m.out_access)
receive('ok\n');assert(not m.out_access)
m:open('mock',250000)
chunks[1]='FIRMWARE_NAME:Marlin 2.1\nCap:EMERGENCY_PARSER:1\nok\n'
local info=m:help();assert(info.ok and info.msg:match('Marlin 2.1') and m.out_access)
m:open('mock',115200)
assert(m:help().err and not m.out_access)

-- Check actual preparation of a small slicer-style program.
Flags={Controller='marlin',ApproximateArcs=true,Transformations={
  Scale={x=1,y=1,z=1},Move={x=0,y=0,z=0},Rotate=0}}
Display={}
require 'conf.gparser'
GTXT:load('G28\nM117 Printing Mixed Case\nG21\nG90\nM82\nM104 S200\nM109 S200\nG92 E0\nG0 X1 Y0\nG3 X0 Y1 I-1 J0 E2\nM84 X Y E')
assert(do_vparse())
assert(GTXT_parsed[1]=='G28' and GTXT_parsed[2]=='M117 Printing Mixed Case')
assert(GTXT_parsed[8]:match('E0%.00000') and not GTXT_parsed[8]:match('X'))
local count,last=0,0
for line in GTXT_parsed[10]:gmatch('[^\n]+') do
  count=count+1
  local e=tonumber(line:match('E([%d%.%-]+)'))
  assert(e>=last);last=e
end
assert(count>10 and math.abs(last-2)<0.00001)
assert(GTXT_parsed[11]=='M84 X Y E')
GTXT:load('M83\nG0 X1 Y0\nG3 X0 Y1 I-1 J0 E2')
assert(do_vparse())
local total=0
for line in GTXT_parsed[3]:gmatch('[^\n]+') do total=total+tonumber(line:match('E([%d%.%-]+)')) end
assert(math.abs(total-2)<0.001)
local sent={}
Sender={newcmd=function(_,command) sent[#sent+1]=command end}
assert(not pcall(do_sparse,2,3) and #sent==0)
m:go_xyz{x=1,y=-2}
assert(table.concat(sent,'|')=='SINGLE|G91|SINGLE|G0X1Y-2|SINGLE|G90')
GTXT:load('G21 G90\nM83\nG1 G91 X1 E1')
assert(do_vparse())
assert(GTXT_parsed[1]=='G21\nG90')
assert(GTXT_parsed[3]:match('^G91\nG1'))
GTXT:load('M104 S200 M140 S60')
assert(not do_vparse())
Flags.Transformations.Scale.x=2
GTXT:load('M201 X500 Y600 Z100 E5000\nG1 X1 Y2 E1\nM92 E420\nG10\nG11\nG29')
assert(do_vparse())
assert(#Display.Points==1)
assert(GTXT_parsed[1]:match('X500') and GTXT_parsed[1]:match('E5000'))
assert(GTXT_parsed[2]:match('X2%.0000'))
assert(GTXT_parsed[3]:match('E420'))
assert(GTXT_parsed[4]=='G10' and GTXT_parsed[6]=='G29')
print('Marlin serial and extrusion tests passed')
