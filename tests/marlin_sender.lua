package.path='./bld/?.lua;./bld/?/init.lua;' .. package.path
local chunks,writes,messages,notices={},{},{},{}
local fault
local port={
  write=function(_,text)
    writes[#writes+1]=text
    if text=='M115\n' then chunks[#chunks+1]='FIRMWARE_NAME:Marlin 2.1\nok\n'
    elseif text=='M114\n' then chunks[#chunks+1]='X:0 Y:0 Z:0 E:0 Count X:0 Y:0 Z:0\nok\n'
    elseif text=='M105\n' then chunks[#chunks+1]='ok T:20 /0 B:20 /0\n'
    elseif text=='M112\n' then chunks[#chunks+1]='Error:Printer halted. kill() called!\n'
    elseif fault and text:match('G1 X2') then chunks[#chunks+1]='Error:Test failure\nok\n'
    else chunks[#chunks+1]='ok\n' end
  end,
  read=function() return table.remove(chunks,1) or '' end,
}
package.loaded['periphery']={Serial=function() return port end}
package.loaded['lfs']={attributes=function() return {} end}
package.loaded['tek.ui']={}
for _,name in ipairs{'StatPort_contents','ControlButtons_add','FileButtons_add','TerminalButtons_add'} do
  package.loaded['conf.controllers.marlin.' .. name]={}
end
local co
package.loaded['tek.lib.exec']={
  run=function(task) co=coroutine.create(task.func);return co end,
  waitmsg=function() if #messages>0 then return table.remove(messages,1) end;return coroutine.yield() end,
  sendmsg=function(_,msg) messages[#messages+1]=msg;return true end,
  sendport=function(_,_,msg) notices[#notices+1]=msg end,
}
package.loaded['tek.lib.visual']={getTime=function() return 0,0 end}
package.loaded['conf.log']={msg=function() end}
package.loaded['ascii85']={}
local marlin=require 'conf.controllers.marlin'
package.loaded['conf.controllers']={get=function() return marlin end}
local sender=require 'conf.sender'
sender:start()
local function step(msg) local ok,err=coroutine.resume(co,msg);assert(ok,err) end
local function ticks(n) for i=1,n do step() end end
step();step('PORT');step('Marlin');step('mock');step('115200');ticks(60)
assert(marlin.out_access)
local ready=false
for _,msg in ipairs(notices) do if msg:match('Connected to') then ready=true end end
assert(ready)
writes={}
step('NEW');step('G1 X1 E1');step('G1 X2 E2');step('G1 X3 E3');step('FIN');step('RESUME');ticks(60)
assert(table.concat(writes,'')=='G1 X1 E1\nG1 X2 E2\nG1 X3 E3\n')
fault=true;writes={}
step('NEW');step('G1 X1');step('G1 X2');step('G1 X3');step('FIN');step('RESUME');ticks(60)
assert(table.concat(writes,'')=='G1 X1\nG1 X2\n')
step('EMERGENCY');ticks(10)
assert(writes[#writes]=='M112\n' and not marlin.out_access)
print('actual Marlin driver and sender integration passed')
