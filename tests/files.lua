package.path = './bld/?.lua;./bld/?/init.lua;' .. package.path
local parser = require 'gcodeparser'
local files = require 'conf.gparser.file'
local store = parser.new_store()
store:load('G90\r\n\r\nG1 X2\nM5')
local filename = 'tests/build/file-test.gcode'
assert(files.write(filename, store))
local loaded = assert(files.read(filename))
assert(type(loaded) == 'userdata' and #loaded == #store)
assert(loaded:concat('|') == store:concat('|'))
store:clear()
assert(files.write(filename, store))
assert(#assert(files.read(filename)) == 0)
assert(not files.read(filename .. '/missing'))
assert(not files.write(filename .. '/missing', store))
-- A device that rejects writes also exposes buffered close errors.
local full = io.open('/dev/full', 'wb')
if full then
  full:close()
  store[1] = 'G90'
  assert(not files.write('/dev/full', store))
end

-- Failure to create the sibling temporary must preserve an existing target.
local longname='tests/build/' .. string.rep('x',250)
local original=assert(io.open(longname,'wb'))
assert(original:write('original program'))
original:close()
assert(not files.write(longname,store))
original=assert(io.open(longname,'rb'))
assert(original:read('*a')=='original program')
original:close()
os.remove(longname)

local ui = {Group={new=function(self, args) return args end}}
package.loaded['tek.ui'] = ui
symBut = function(icon, callback) return callback end
GTXT, GTXT_parsed = parser.new_store(), parser.new_store()
GTXT:load('G1 X2\nM5')
local redraws = 0
initialiseEditor = function() end
do_vparse = function() redraws=redraws+1; return true end
Flags = {isEdited=true}
local status
local app = {
  getById=function() return {setValue=function(_, _, text) status=text end} end,
  addCoroutine=function(_, fn) fn() end,
  requestFile=function() return 'selected', 'tests/build', {'file-test.gcode'} end,
}
local panel = require 'conf.gui.common.panel_file'
local button = {Application=app}
GFNAME = filename
panel.Children[3](button)
assert(status == 'Saved ' .. filename and not Flags.isEdited)
assert(#assert(files.read(filename)) == 2)
panel.Children[1](button)
assert(#GTXT == 0 and #GTXT_parsed == 0 and GFNAME == nil and redraws == 1)
panel.Children[2](button)
assert(GFNAME == filename and #GTXT == 2 and redraws == 2)
Flags.isEdited=true
GFNAME=filename .. '/missing'
panel.Children[3](button)
assert(Flags.isEdited and status:match('Save failed'))
GFNAME=nil
panel.Children[3](button)
assert(GFNAME == filename and not Flags.isEdited)
os.remove(filename)
print('file operations tests passed')
