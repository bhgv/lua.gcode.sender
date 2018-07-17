
local ui = require "tek.ui"



local posInd = function(typ)
  local out = ui.Text:new {
      Width=60,
      setup = function(self, app, win)
	      ui.Text.setup(self, app, win)
          --print(app, win)
          app:addInputHandler(ui.MSG_USER, self, self.msgUser)
      end,
      cleanup = function(self)
          ui.Text.cleanup(self)
          --self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
      end,
      msgUser = function(self, msg)
          local ud = msg[-1]
          --print("ud", ud)
          if ud:match("<STATUS>") then
            local cmd = ud:match("<" .. typ .. ">([^<]*)")
            if cmd ~= nil then
--              cmd = cmd:match("([^\n]*)")
              --print("cmd=" .. cmd)
              self:setValue("Text", cmd)
            end
          end
          return msg
      end,
  }
  
  return out
end



local StatPort_contents = ui.Group:new
{
  Orientation = "vertical",
  Legend = "Status",
  Children = 
  {
    ui.Text:new
    {
      Class = "caption",
      Width = 150,
      Style = "font:/b:14; color:navy;", --olive;", --navy;",
      Text = "Not Connected",
      setup = function(self, app, win)
          ui.Text.setup(self, app, win)
          app:addInputHandler(ui.MSG_USER, self, self.msgUser)
      end,
      cleanup = function(self)
          ui.Text.cleanup(self)
          --self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
      end,
      msgUser = function(self, msg)
                      local ud = msg[-1]
                      --print("ud", ud)
                      local cmd = ud:match("<MESSAGE>(.*)")
                      if cmd then
                        --print("cmd=" .. cmd)
                        if 
                          cmd:match("^echo:") 
                        then
                          --MKstate = "PAUSE"
                          cmd = cmd:match("^echo:(.*)")
                        elseif 
                          cmd:match("^error:") 
                        then
                          --MKstate = "PAUSE"
                        elseif 
                          cmd:match("^Pause")
                        then
                          --MKstate = "PAUSE"
                          cmd = "status: " .. cmd
                        elseif 
                          cmd:match("^Stop")
                        then
                          --MKstate = "STOP"
                          cmd = "status: " .. cmd
                        elseif 
                          cmd:match("^Run")
                        then
                          cmd = "status: " .. cmd
                        end
                        
                        self:setValue("Text", cmd)
                      end
                      return msg
                    end,

    },
    
    ui.Group:new
    {
      Rows = 2, --3,
      Columns = 4,
      Children = 
      {
          ui.Text:new{Class = "caption",Width=60, Text="WPos:"},
          posInd("wX"), posInd("wY"), posInd("wZ"), 
--          ui.Text:new{Class = "caption",Width=60, Text="MPos:"},
--          posInd("mX"), posInd("mY"), posInd("mZ"), 
          ui.Text:new{Class = "caption",Width=60, },
          ui.Button:new{Width=60, Text="x = 0",
            onClick = function(self)
              ui.Button.onClick(self)
              MK:set_xyz{x=0,}
            end,
          }, 
          ui.Button:new{Width=60, Text="y = 0",
            onClick = function(self)
              ui.Button.onClick(self)
              MK:set_xyz{y=0,}
            end,
          }, 
          ui.Button:new{Width=60, Text="z = 0",
            onClick = function(self)
              ui.Button.onClick(self)
              MK:set_xyz{z=0,}
            end,
          }, 
      },
    }
  },
}


return StatPort_contents
