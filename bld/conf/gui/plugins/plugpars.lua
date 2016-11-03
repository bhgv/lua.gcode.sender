local ui = require "tek.ui"
local exec = require "tek.lib.exec"
--local List = require "tek.class.list"

--print(ui.ProgDir)

Plugins.Gui.PlugPars = ui.Group:new
{
  Orientation = "vertical",
--  Width = 75+120+32,
  Children = 
  {
  },
  setup = function(self, app, win)
            ui.Group.setup(self, app, win)
            app:addInputHandler(ui.MSG_USER, self, self.msgUser)
  end,
  cleanup = function(self)
            ui.Group.cleanup(self)
            self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
  end,
  msgUser = function(self, msg)
            local ud = msg[-1]
            --print("ud", ud)
            local task, nxt_lvl
            task, nxt_lvl = ud:match("^<PLUGIN>([^<]*)(<.*)")
            if nxt_lvl then
              if nxt_lvl:match("^<REM PARAMS>") then
                --self:setValue("Children", {})
                local lst = self:getChildren()
                local i,v 
                for i = #lst,1,-1 do
                  v = lst[i]
                  self:remMember(v)
                end
              elseif nxt_lvl:match("^<SHOW PARAMS>") then
                nxt_lvl = nxt_lvl:match("^<SHOW PARAMS>(.*)")
                local k, v
                local chlds = {}
                for k,v in nxt_lvl:gmatch("%s*([^=]+)=%s*([^\n]+)[;\n]+") do
                  table.insert(chlds, ui.Text:new{Text=k,})
                  table.insert(chlds, ui.Input:new{Text=v,})
                end
                local gr = ui.Group:new{Columns=2, Children=chlds,}
                self:addMember(gr)
                self:addMember(
                  ui.Button:new{
                    plug_task = task, 
                    par_group = gr, --chlds, --gr,
                    Text = "Execute",
                    onClick = function(self)
                      ui.Button.onClick(self)
                      
                      local out
                      local lst = self.par_group:getChildren()
                      --print("exec", #lst)
                      if lst and #lst > 0 then
                        local i
                        out = ""
                        for i = 1, #lst, 2 do
                          out = out .. lst[i].Text .. "=" .. lst[i+1]:getText() .. "\n"
                        end
                        exec.sendmsg(self.plug_task, "<EXECUTE>" .. out)
                      end
                    end,
                  }
                )
              end
            end
            
            return msg
  end,
}


return Plugins.Gui.PlugPars
