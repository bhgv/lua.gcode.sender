local ui = require "tek.ui"
local exec = require "tek.lib.exec"

--print(ui.ProgDir)

local complexcontrol = require "conf.gui.plugins.lib.complexcontrol"


local function preparePluginParamsDlg(task, name, par_str)
  local k, v
  local chlds = {}
  local gr1, gr2
  
  --print(par_str)
  
  local pars = {}
  for k,v in par_str:gmatch("%s*([^=]+)=([^\n]*)[;\n]+") do
    pars[k] = v
  end
  
  for k,v in pairs(pars) do -- par_str:gmatch("%s*([^=]+)=%s*([^\n]+)[;\n]+") do
    if k:match("^<") then
      --print(k,v)
      local wgt = complexcontrol(k)
      --[==[
      if k == "<ImageLoader>" then
        wgt = ui.Group:new {
            Legend = "Select an image:",
            
            int_type = "<ImageLoader>",
            control_param = "", 
            
            Children = {
              ui.ImageWidget:new {
                    Height = "fill",
                    Mode = "button",
                    Style = [[
                            background-color: #dfc; 
                            margin: 2;
                            padding: 8;
                            border-width: 1;
                            border-focus-width: 2;
                            min-width: 30;
                            min-height: 30;
                    ]],
                    Image = nil,
                    im_hlp = require "conf.utils.image_helper",
--                    int_type = "<ImageLoader>",
--                    control_param = "", 
                    
                    onClick = function(self)
                      ui.ImageWidget.onClick(self)
                      
                      local app = self.Application
                      app:addCoroutine(
                                    function()
                                      local status, path, select = app:requestFile{
                                              Title = "Select an image (*.ppm)",
                                              Path = self.old_path or "./conf/icons", 
                                              SelectMode = "single",
                                              DisplayMode = "all",
                                              Filter = "%.ppm%s*$",
                                              --Lister = require "conf.gui.classes.filtereddirlist",
                                      }
                                      if status == "selected" then
                                        local img_path = path .. "/" .. select[1]
                                        local f = self.im_hlp:loadImage(img_path)
                                        if f ~= nil then
--                                          self:setValue("control_param", img_path)
                                          self.old_path = path
                                          wgt.control_param = img_path
                                          self:setValue("Image", f)
                                        end
                                      end
                                    end 
                      )
                    end,
              },
            },
        }
      end
      ]==]
      
      table.insert(chlds, wgt)
      --table.insert(chlds, ui.Text:new{Text=k,})
      --table.insert(chlds, ui.Input:new{Text=v,})
    end
  end
  gr1 = ui.Group:new{Orientation="vertical", Children=chlds,}

  chlds = {}
  for k,v in pairs(pars) do -- par_str:gmatch("%s*([^=]+)=%s*([^\n]*)[;\n]+") do
    if not k:match("^<") then
      table.insert(chlds, ui.Text:new{Text=k,})
      table.insert(chlds, ui.Input:new{Text=v,})
    end
  end
  gr2 = ui.Group:new{Columns=2, Children=chlds,}
  
  dlg = {}
  if name and name ~= "" then
    dlg[1] = ui.Text:new{Text=name,Class = "caption",}
  end
  if gr1 then
    table.insert(dlg, gr1)
  end
  if gr2 then
    table.insert(dlg, gr2)
  end
  --local b_name = "Execute"
  --if
  table.insert(dlg, 
                ui.Button:new{
                    plug_task = task, 
                    par_complex = gr1,
                    par_group = gr2, --chlds, --gr,
                    Text = "Execute", --(pars.subtype == "Filter" and "Attach") or "Execute",
                    onClick = function(self)
                      ui.Button.onClick(self)
                      
                      local out = ""
                      local lst
                      if self.par_group then
                        lst = self.par_group:getChildren()
                        --print("exec", #lst)
                        if lst and #lst > 0 then
                          local i
                          --out = ""
                          for i = 1, #lst, 2 do
                            out = out .. lst[i].Text .. "=" .. lst[i+1]:getText() .. "\n"
                          end
                        end
                      end
                      
                      if self.par_complex then
                        lst = self.par_complex:getChildren()
                        --print("exec", #lst)
                        if lst and #lst > 0 then
                          local i
                          --out = out or ""
                          for i = 1, #lst do
                            local it = lst[i]
                            if it.int_type then
                              --print(it.int_type .. "=" .. it.control_param)
                              out = out .. it.int_type .. "=" .. it.control_param .. "\n"
                            end
                          end
                        end
                      end
                      
                      if out then
                        --print(out)
                        exec.sendmsg(self.plug_task, "<EXECUTE>" .. out)
                      end
                    end,
                }
  )
  table.insert(dlg, 
                ui.Button:new{
                    plug_task = task, 
                    par_complex = gr1,
                    par_group = gr2, --chlds, --gr,
                    Text = "Save as default",
                    onClick = function(self)
                      ui.Button.onClick(self)
                      
                      local out
                      local lst
                      if self.par_group then
                        lst = self.par_group:getChildren()
                        --print("exec", #lst)
                        if lst and #lst > 0 then
                          local i
                          out = ""
                          for i = 1, #lst, 2 do
                            out = out .. lst[i].Text .. "=" .. lst[i+1]:getText() .. "\n"
                          end
                        end
                      end
                      
                      if self.par_complex then
                        lst = self.par_complex:getChildren()
                        --print("exec", #lst)
                        if lst and #lst > 0 then
                          local i
                          out = out or ""
                          for i = 1, #lst do
                            local it = lst[i]
                            if it.int_type then
                              --print(it.int_type .. "=" .. it.control_param)
                              out = out .. it.int_type .. "=" .. it.control_param .. "\n"
                            end
                          end
                        end
                      end
                      
                      if out then
                        --print(out)
                        exec.sendmsg(self.plug_task, "<SAVE>" .. out)
                      end
                    end,
                }
  )
  return ui.Group:new{Orientation = "vertical",Legend="Parameters:",Children = dlg, }
end


local function cr_plugpars(grp)
  local ppars =
          ui.Group:new
          {
            Orientation = "vertical",
          --  Width = 75+120+32,
            Pars_group = grp,
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
                      local grp, task, nxt_lvl
                      grp, task, nxt_lvl = ud:match("^<PLUGIN>([^<]*)<NAME>([^<]*)(<.*)")
                      --print(self.Pars_group, grp, task, nxt_lvl)
                      if grp and self.Pars_group == grp and nxt_lvl then
                        if nxt_lvl:match("^<REM PARAMS>") then
                          --self:setValue("Children", {})
                          local lst = self:getChildren()
                          local i,v 
                          for i = #lst,1,-1 do
                            v = lst[i]
                            self:remMember(v)
                          end
                        elseif nxt_lvl:match("^<SHOW PARAMS>") then
                          local name
                          name, nxt_lvl = nxt_lvl:match("^<SHOW PARAMS>([^<]*)<BODY>(.*)")
                          self:addMember(
                                preparePluginParamsDlg(task, name, nxt_lvl)
                          )
                        --[[
                        elseif nxt_lvl:match("^<GCODE>") then
                          nxt_lvl = nxt_lvl:match("^<GCODE>(.*)")
                          local t = {}
                          local ln
                          --print(nxt_lvl)
                          for ln in nxt_lvl:gmatch("([^\n]+)\n") do
                            table.insert(t, ln)
                          end
                          GTXT = t
                          initialiseEditor()
                          do_vparse()
                        ]]
                        end
                      end
                      
                      return msg
            end,
          }
  
  Plugins.Gui.PlugPars[grp] = ppars
  
  return ppars
end


return cr_plugpars --Plugins.Gui.PlugPars