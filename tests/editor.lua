package.path='./bld/?.lua;./bld/?/init.lua;./bld/share/lua/5.3/?.lua;' .. package.path
local parser=require 'gcodeparser'
local function widget(args)
  args=args or {}
  function args:setValue(key, value) self[key]=value end
  function args:getText() return self.Text or '' end
  function args:getById(id) return App:getById(id) end
  return args
end
local class={new=function(_, args) return widget(args) end, onEnter=function() end, onClick=function() end, onSelect=function() end}
package.loaded['tek.ui']={Group=class, Input=class, Button=class, Text=class, CheckMark=class, ListView=class}
Flags={AutoRedraw=true, SendFrom=1, SendTo=0, Transformations={
  Move={x=0,y=0,z=0}, Scale={x=1,y=1,z=1}, Rotate=0,
}}
Display={}
require 'conf.gparser'
local NumberedList=require 'conf.gui.classes.numberedlist'
local list=widget{SelectedLine=0, ListObject=NumberedList:new{Store=GTXT}}
function list:addItem(entry,n) return self.ListObject:addItem(entry,n) end
function list:changeItem(entry,n) return self.ListObject:changeItem(entry,n) end
function list:remItem(n) return self.ListObject:remItem(n) end
local input=widget{Text=''}
local status=widget()
local widgets={['editor cmd list']=list, gedit=input, ['status main']=status,
  ['send from']=widget(), ['send to']=widget()}
App={getById=function(_,id) return assert(widgets[id],id) end}
updateEditorRange=function(old_count)
  if Flags.SendTo == old_count then Flags.SendTo=#GTXT end
end
local sent={}
Sender={newcmd=function(_,cmd) sent[#sent+1]=cmd end}
gLstWdgtM=list
local tree=require 'conf.gui.edit.cmdlst'
local buttons={}
local function collect(node)
  if node.Text then buttons[node.Text]=node end
  if node.Id == 'gedit' then widgets.gedit=node; input=node end
  for _,child in ipairs(node.Children or {}) do collect(child) end
end
collect(tree)
local function enter(text) input.Text=text; input:onEnter() end
local function click(name) buttons[name]:onClick() end
-- Enter builds the program from an empty native store, without serial traffic.
enter('G90 G21')
assert(GTXT[1]=='G90 G21' and GTXT[2]=='' and list.SelectedLine==2)
enter('G1 X10 Y20')
enter('X30')
assert(#GTXT==4 and Display.Points[2].x==30 and Flags.SendTo==4)
assert(#sent==0 and Flags.isEdited)
-- Update can create a first row too; multi-line input inserts native rows.
list.SelectedLine=0
input.Text='M5'
click('Update')
assert(GTXT[5]=='M5')
list.SelectedLine=2
input.Text='G1 X1 Y2\r\nX3\nX4'
click('Update')
assert(GTXT[2]=='G1 X1 Y2' and GTXT[3]=='X3' and GTXT[4]=='X4')
assert(list.SelectedLine==4 and #sent==0)
-- Validation stays active with preview refresh disabled.
Flags.AutoRedraw=false
local points=Display.Points
input.Text='X8'
click('Update')
assert(Display.Points==points and GTXT_parsed[4]:match('X8%.0000'))
Flags.Transformations.Scale.x=nil
input.Text='X9'
click('Update')
assert(status.Text:match('Parse failed') and GTXT[4]=='X9')
Flags.Transformations.Scale.x=1
Flags.AutoRedraw=true
click('Update drawing')
assert(Display.Points ~= points)
-- Delete all rows; the input clears and another program can be entered.
while #GTXT>0 do list.SelectedLine=1; click('Delete') end
assert(list.SelectedLine==0 and input.Text=='' and #GTXT_parsed==0)
click('New')
assert(#GTXT==1 and list.SelectedLine==1 and input.Text=='')
input.Text='G1 X7'
click('Update')
assert(Display.Points[1].x==7 and #sent==0)
local files=require 'conf.gparser.file'
assert(files.write('tests/build/editor.gcode',GTXT))
assert(assert(files.read('tests/build/editor.gcode'))[1]=='G1 X7')
os.remove('tests/build/editor.gcode')
do_sparse(1,1)
assert(sent[1]=='NEW' and sent[2]:match('X7%.0000'))
-- Exercise the existing search/replace toolbar, including deletion by replacement.
package.loaded['tek.ui'].Spacer=class
Flags.Transformations.Mirror={h=false,v=false}
local icons={}
symBut=function(icon, fn) local b=widget{onClick=fn}; icons[icon]=b; return b end
symButSm=symBut
local tools=require 'conf.gui.edit.etools'
local fields=tools.Children[3].Children
local find, replace=fields[2],fields[4]
local seek, substitute=icons['\u{e0e2}'],icons['\u{e0e4}']
find.Text='X7'; replace.Text=''
substitute:onClick()
assert(GTXT[1]=='G1 ' and status.Text:match('Checked'))
local previous=GTXT[1]
find.Text='['
seek:onClick()
assert(GTXT[1]==previous and status.Text:match('malformed'))
find.Text='does not exist'
substitute:onClick()
assert(GTXT[1]==previous and status.Text=='No match')
list.SelectedLine=1
local valid_parsed=GTXT_parsed
input.Text='G1 X'
click('Update')
assert(GTXT[1]=='G1 X' and status.Text:match('Parse failed'))
assert(GTXT_parsed==valid_parsed)
input.Text='G1 X12'
click('Update')
assert(status.Text:match('Checked') and Display.Points[1].x==12)
Flags.EditorReady=true
App.addCoroutine=function(_,fn) fn() end
GFNAME='tests/build/draft.gcode'
input.Text='G1 X42'
local file_panel=require 'conf.gui.common.panel_file'
file_panel.Children[3].Application=App
file_panel.Children[3]:onClick()
assert(GTXT[1]=='G1 X42' and assert(files.read(GFNAME))[1]=='G1 X42')
os.remove(GFNAME)
input.Text='G1 X'
local ok, err=require('conf.gui.edit.actions').flush()
assert(not ok and err:match('line %d+, column %d+'))
assert(status.Text:match('line %d+, column %d+'))
local count=#sent
package.loaded['tek.lib.exec']={}
local run_panel=require 'conf.gui.common.panel_run'
run_panel.Children[2].Application=App
MKstate='STOP'
run_panel.Children[2]:onClick()
assert(#sent==count and MKstate=='STOP')
input.Text='G1 X43'
run_panel.Children[2]:onClick()
assert(GTXT[1]=='G1 X43' and MKstate=='RUN' and sent[#sent]=='RESUME')
print('editor from scratch tests passed')
