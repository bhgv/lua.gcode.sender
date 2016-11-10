
local ui = require "tek.ui"


local function complexcontrol(tmpl)
  local wgt
  
      if tmpl:match("^<ImageLoader>") then
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
        
      elseif tmpl:match("^<FILE>") then
        local name = tmpl:match('<NAME>([^<>]+)')
        local mask = tmpl:match('<MASK>([^<>]+)') or ""
        --print(name, mask)
        wgt = ui.Group:new {
            Legend = name or "Select a file:",
            
            int_type = tmpl, --"<FILE>",
            control_param = "", 
            
            Children = {
              ui.Button:new {
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
                    Text = "",
                    
                    onClick = function(self)
                      ui.Button.onClick(self)
                      
                      local app = self.Application
                      app:addCoroutine(
                                    function()
                                      local status, path, select = app:requestFile{
                                              Title = name or "Select a file",
                                              Path = self.old_path or ".", 
                                              SelectMode = "single",
                                              DisplayMode = "all",
                                              Filter = mask or "",
                                              --Lister = require "conf.gui.classes.filtereddirlist",
                                      }
                                      if status == "selected" then
                                        local f_path = path .. "/" .. select[1]
                                        self.old_path = path
                                        wgt.control_param = f_path
                                        self:setValue("Text", f_path)
                                      end
                                    end 
                      )
                    end,
              },
            },
        }
        
      end


  return wgt
end



return complexcontrol

