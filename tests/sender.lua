package.path = './bld/?.lua;./bld/?/init.lua;' .. package.path
local sent, events = {}, {}
local controller = {out_access=true}
function controller:open() return true end
function controller:init() return {msg='connected'} end
function controller:status_query() end
function controller:send(cmd) sent[#sent + 1] = cmd; self.out_access=false end
function controller:pause() events[#events + 1]='pause' end
function controller:resume() events[#events + 1]='resume' end
function controller:stop() events[#events + 1]='stop' end
local co
package.loaded['tek.ui'] = {}
package.loaded['tek.lib.exec'] = {
  run = function(task) co=coroutine.create(task.func); return co end,
  waitmsg = function() return coroutine.yield() end,
  sendport = function() end,
}
package.loaded['tek.lib.visual'] = {getTime=function() return 0,0 end}
package.loaded['conf.controllers'] = {get=function() return controller end}
package.loaded['conf.log'] = {msg=function() end}
package.loaded['ascii85'] = {}
package.loaded['conf.sender.lib'] = {
  split=function() end, display_tx=function() end,
  cnc_read_parse=function()
    controller.out_access=true
    return {ok=true}
  end,
}
local sender=require 'conf.sender'
sender:start()
local function step(msg)
  local ok, err=coroutine.resume(co, msg)
  assert(ok, err)
end
local function ticks(n) for i=1,n do step() end end
step()
step('PORT'); step('grbl'); step('mock'); step('115200')
ticks(5)
step('SINGLE'); step('G90')
step('SINGLE'); step('G21')
step('SINGLE'); step('M5')
ticks(30)
assert(table.concat(sent, '') == 'G90\nG21\nM5\n')
sent={}
step('NEW'); step('G1 X1'); step('G1 X2'); step('G1 X3'); step('FIN')
step('RESUME')
-- Pause after the first block has been sent, before the rest of the job.
while #sent == 0 do step() end
step('PAUSE')
local count=#sent
ticks(10)
assert(#sent == count and events[#events] == 'pause')
step('SINGLE'); step('G0 X99')
ticks(10)
assert(#sent == count)
step('RESUME'); ticks(30)
assert(table.concat(sent, '') == 'G1 X1\nG1 X2\nG1 X3\n')
step('STOP'); ticks(3)
assert(events[#events] == 'stop')
-- Requests before opening a controller must also be harmless.
local previous=co
sender:start(); step(); step('PAUSE'); step('RESUME'); step('STOP')
step('PORT'); step(); step(); step()
assert(coroutine.status(previous) == 'suspended')
print('sender flow tests passed')
