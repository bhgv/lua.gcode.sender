local ui = require "tek.ui"
local Group = ui.Group




gLstWdgtM = ui.Lister:new
{
            Id = "editor cmd list",
            SelectMode = "single", --"multi",
--						ListObject = gcmdLst,
            
						onSelectLine = function(self)
							ui.Lister.onSelectLine(self)
              local lineno = self.SelectedLine
							local line = self:getItem(lineno)
							if line then
                App:getById("gedit"):setValue("Text", line[1][2])
								--self.Window:setRecord(line[1])
                --self.sel_line_no
							end
						end,
            
            setup = function(self, app, win)
              ui.Lister.setup(self, app, win)
              --print(app, win)
              app:addInputHandler(ui.MSG_USER, self, self.msgUser)
            end,
            
            cleanup = function(self)
              ui.Lister.cleanup(self)
              self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
            end,
            
            msgUser = function(self, msg)
              local ud = msg[-1]
              
              cmd = ud:match("<MESSAGE>error:[^%(]*%(ln%: (%d+)%)")
              if cmd then --~= nil and _G.Flags.SendFrom and _G.Flags.SendTo then
                local i = tonumber(cmd)
                self:setValue("SelectedLine", i)
                self:setValue("CursorLine", i)

              else
                cmd = ud:match("<EDITOR SEL LN>(%d+)")
                if cmd then
                  --print(cmd)
                  local i = tonumber(cmd)
                  self:setValue("SelectedLine", i)
                  self:setValue("CursorLine", i)
                end
              end
              return msg
            end,
}
          
initialiseEditor = function()
  local NumberedList = require "conf.gui.classes.numberedlist"

  local i,ln
  local lst = {}
  
  for i,ln in ipairs(GTXT) do
    table.insert(lst, {{ "", ln }})
  end
  
  gLstWdgtM:setList(NumberedList:new { Items = lst })
  
  _G.Flags.SendFrom = 1
  _G.Flags.SendTo = #GTXT --+ 1
  
  App:getById("send to"):setValue("Text", tostring(#GTXT))
  App:getById("send from"):setValue("Text", "1")
end




return		Group:new -- edit
		{
		    Orientation = "vertical",
		    Children =
		    {
			Group:new
			{
			    Orientation = "horisontal",
			    Children =
			    {
				require "conf.gui.edit.etools",
			    },
			},
			Group:new
			{
			    Children =
			    {
				require "conf.gui.edit.cmdlst",
				ui.Handle:new { },
				ui.Group: new 
				{
				    Children =
				    {
					DisplayBlock,
				    }
				}
			    },
			}
		    }
		}
