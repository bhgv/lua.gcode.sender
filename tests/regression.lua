package.path = './bld/?.lua;./bld/?/init.lua;./bld/share/lua/5.3/?.lua;' .. package.path
local parser = require 'gcodeparser'
local store = parser.new_store()
assert(type(store) == 'userdata' and #store == 0)
store:load('G90\r\n\r\nG1 X1\nM5')
assert(#store == 4 and store[2] == '' and store[4] == 'M5')
store:insert(2, 'G21')
store[3] = 'G0 X0'
store:remove(4)
assert(store:concat('|') == 'G90|G21|G0 X0|M5')
assert(store:concat('\n', 2, 3) == 'G21\nG0 X0')
assert(not pcall(function() store[0] = 'bad' end))
assert(not pcall(function() store:remove(10) end))
local other = parser.new_store()
other[1] = 'independent'
store:clear()
assert(#store == 0 and other[1] == 'independent')

local line = 'G1 ' .. string.rep('X1 ', 1000)
local callbacks = 0
parser.set_callback_dict {cmd = function() callbacks = callbacks + 1 end}
for i = 1, 100 do
  local out = parser:do_parse(line .. '\n\nM5')
  assert(type(out) == 'userdata' and #out == 3 and #out[1] > 256 and out[2] == '')
end
assert(callbacks == 100200)
parser.set_callback_dict {cmd = function() error('callback failure') end}
assert(not pcall(function() parser:do_parse('G1 X1') end))
parser.set_callback_dict {}
assert(parser:do_parse('M5')[1]:match('M5'))
assert(#parser:do_parse('') == 0)

package.loaded['tek.ui'] = {}
Flags = {Transformations = {
  Scale = {x=1, y=1, z=1}, Rotate=0, Move={x=0, y=0, z=0},
}}
Display = {}
require 'conf.gparser'
GTXT:load('G90\n\nG1 X10 Y20\nX30\nM5\n')
do_vparse()
assert(#GTXT_parsed == #GTXT and GTXT_parsed[2] == '')
assert(GTXT_parsed[4]:match('Y20%.0000'))
local messages = parser.new_store()
Sender = {newcmd = function(self, cmd) messages[#messages + 1] = cmd end}
GTXT[3] = 'G1 X15 Y25'
do_sparse(4, 4)
assert(messages[1] == 'NEW' and messages[2]:match('Y25%.0000') and messages[3] == 'FIN')
assert(Flags.Rel_gcode2display[4])
GTXT:clear()
do_vparse()
assert(#GTXT_parsed == 0 and #Display.Points == 0)
assert(Display.Bnd.xmin == 0 and Display.Bnd.zmax == 0)

GTXT:load('G1 X1 Z-1\nX2 Z-2\nG0 X3 Z5\nX4 Z6')
do_vparse()
assert(Display.Points[2].iswork and Display.Points[2].p == 0xff)
assert(not Display.Points[3].iswork and not Display.Points[4].iswork)
assert(Display.Bnd.zmin == -2 and Display.Bnd.zmax == -1)

GTXT:load('G90 G1 X10 Y20\nG91 X2\nY3\nX-1 G91\nG90 X5')
do_vparse()
assert(Display.Points[2].x == 12 and Display.Points[2].y == 20)
assert(Display.Points[3].x == 12 and Display.Points[3].y == 23)
assert(Display.Points[4].x == 11 and Display.Points[5].x == 5)
assert(GTXT_parsed[2]:match('X2%.0000') and GTXT_parsed[2]:match('Y0%.0000'))
Flags.Transformations.Move = {x=100, y=200, z=300}
Flags.Transformations.Rotate = math.pi / 2
GTXT:load('G91 G1 X2\nY3')
do_vparse()
assert(GTXT_parsed[1]:match('Y2%.0000'))
assert(GTXT_parsed[2]:match('X%-3%.0000'))
assert(not GTXT_parsed[1]:match('100') and not GTXT_parsed[1]:match('200'))
Flags.Transformations.Move = {x=0, y=0, z=0}
Flags.Transformations.Rotate = 0

local NumberedList = require 'conf.gui.classes.numberedlist'
store:load('G90\nM5')
local list = NumberedList:new {Store=store, Items={{}, {}}}
local row = list:getItem(1)
row[4], row[5], row[3] = 0, 10, true
assert(rawget(row, 1) == nil and row[1][2] == 'G90')
store[1] = 'G21'
assert(list:getItem(1)[1][2] == 'G21' and list:getItem(1)[3])
store:insert(2, 'G0 X0')
list:addItem({{'', 'must not be cached'}}, 2)
assert(list:getItem(2)[1][2] == 'G0 X0' and rawget(list.Items[2], 1) == nil)
store:remove(1)
list:remItem(1)
assert(list:getN() == 2 and list:getItem(1)[1][2] == 'G0 X0')

local generated
package.loaded['tek.lib.exec'] = {sendport = function(_, _, text) generated = text end}
local generator = require 'conf.gen.gcode'
generator:start()
generator:set_param('relative')
generator:walk_to{x=1}
generator:spindle_freq(1000)
generator:speed(200)
generator:speed(-10)
generator:finish()
assert(generated:match('G91 G0 X1%.0000') and generated:match('S1000') and generated:match('F200'))
generator:start()
generator:work_to{y=2}
generator:finish()
assert(generated:match('G90 G1 Y2%.0000'))

-- Exercise actual controller code using fragmented/coalesced serial responses.
local chunks, writes = {}, {}
local port = {
  write = function(self, s) writes[#writes + 1] = s end,
  read = function() return table.remove(chunks, 1) or '' end,
}
package.loaded['periphery'] = {Serial = function() return port end}
package.loaded['lfs'] = {attributes = function() return {} end}
package.loaded['tek.lib.exec'] = {sendmsg = function() end}
package.loaded['conf.controllers.grbl.StatPort_contents'] = {}
local grbl = require 'conf.controllers.grbl'
assert(grbl:open('mock', 115200))
local function receive(text)
  chunks[#chunks + 1] = text
  return grbl:read()
end
local old = grbl:status_parse('<Idle,MPos:1.000,-2.000,3.000,WPos:0.000,-4.000,2.000,Buf:0,RX:0>')
assert(old.mX == 1 and old.wY == -4)
local new = grbl:status_parse('<Hold:0|MPos:10,20,30|FS:0,0|WCO:1,2,3|Bf:15,128>')
assert(new.state == 'Hold:0' and new.wX == 9 and new.wZ == 27)
new = grbl:status_parse('<Jog|WPos:2,3,4,5|Future:xyz>')
assert(new.mX == 3 and new.mZ == 7)
grbl:send('G1 X1\n')
grbl:status_query()
assert(writes[#writes] == '?' and not grbl.out_access)
assert(not receive('o').msg)
assert(receive('k\r\n<Idle|MPos:1,2,3>\r\n').ok and grbl.out_access)
assert(grbl:read().stat)
grbl:send('G1 X2\n')
assert(receive('[MSG:hello]\r\n').msg and not grbl.out_access)
assert(receive('error:20\n').err and grbl.out_access)
assert(receive('ALARM:1\r\n').err and not grbl.out_access)
assert(receive("Grbl 1.1h ['$' for help]\r\n").err)
assert(grbl.version == '1.1h')
new = grbl:status_parse('<Idle|MPos:10,20,30>')
assert(new.wX == nil) -- Reset must discard cached WCO.
chunks[1] = '$10=1\r\nok\r\n'
local help = grbl:help()
assert(help.raw:match('%$10=1') and grbl.out_access)
for _, command in ipairs(writes) do assert(not command:match('%$10=')) end
grbl:stop()
assert(writes[#writes] == string.char(24) and not grbl.out_access)
receive('ok\n')
assert(not grbl.out_access)
receive("Grbl 1.1h ['$' for help]\n")
assert(grbl.out_access)

local status_message
package.loaded['tek.lib.exec'].sendport = function(_, _, text) status_message = text end
require('conf.sender.lib'):cnc_stat(grbl:status_parse('<Idle|MPos:1,2,3|WCO:0,0,0>'))
assert(status_message:match('<mX>1') and status_message:match('<wZ>3'))
require('conf.sender.lib'):cnc_stat({stat={tCur=25}})
assert(status_message:match('<tCur>25'))
print('regression tests passed')
