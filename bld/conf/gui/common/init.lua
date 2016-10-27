
ui = require "tek.ui"


symBut = function(txt, foo, color)
  local style = "font:ui-icons:20; width:24; color:olive;" --olive;" --navy;"
  local par = {}
--  if par.Style then
--    style = style .. par.Style
--  end
  par.Style = style
  par.Text = txt
  par.onClick = function(self)
    ui.Button.onClick(self)
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
    foo(self)
  end
  
  return ui.Button:new(par)
end


symButSm = function(txt, foo, color)
  local style = "font:ui-icons:12; width:12; color:olive;" --olive;" --navy;"
  local par = {}
--  if par.Style then
--    style = style .. par.Style
--  end
  par.Style = style
  par.Text = txt
  par.Class = "caption"
  par.onClick = function(self)
    ui.Button.onClick(self)
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
    foo(self)
  end
  
  return ui.Button:new(par)
end



local disp_percent_view = ui.Text:new{Text="100%", Width=20,}

Display = require "conf.gui.display"

DisplayBlock = ui.Group:new
{
  Orientation = "vertical",
  Children =
  {
    ui.Group:new
    {
      Children =
      {
        ui.Text:new{Text="view:", Width=20, Class = "caption"},
        symButSm("\u{e0e0}", function(self) end),
        symButSm("\u{e0e1}", function(self) end),
        ui.Text:new{Text="scale:", Width=20, Class = "caption"},
        symButSm("\u{e0de}", function(self) 
            local n = _G.Flags.DispScale --tonumber(disp_percent_view.Text:match("(%d*%.?%d*)"))
            n = n/1.1
            _G.Flags.DispScale = n
            disp_percent_view:setValue("Text", string.format("%0.2f", n) .. "%")
            if _G.Flags.AutoRedraw then
              Display.Changed = true
            end
        end),
        disp_percent_view,
        symButSm("\u{e0dd}", function(self) 
            local n = _G.Flags.DispScale --tonumber(disp_percent_view.Text:match("(%d*%.?%d*)"))
            n = n*1.1
            _G.Flags.DispScale = n
            disp_percent_view:setValue("Text", string.format("%0.2f", n) .. "%")
            if _G.Flags.AutoRedraw then
              Display.Changed = true
            end
        end),
        symButSm("\u{e08f}", function(self) 
            _G.Flags.DispScale = 100
            disp_percent_view:setValue("Text", "100%")
            if _G.Flags.AutoRedraw then
              Display.Changed = true
            end
        end),
        ui.Text:new{Text="mode:", Width=20,Class = "caption"},
        symButSm("\u{e089}", function(self) 
            _G.Flags.DisplayMode = "select"
        end),
--        symButSm("\u{e0a8}", function(self) end),
        symButSm("\u{e0a0}", function(self) 
            _G.Flags.DisplayMode = "drag"
        end),
      }
    },
    
    Display,
  }
}





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
											self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
										end,
      msgUser = function(self, msg)
											local ud = msg[-1]
                      --print("ud", ud)
                      if ud:match("<STATUS>") then
                        local cmd = ud:match("<" .. typ .. ">([^<]*)")
                        if cmd ~= nil then
--                          cmd = cmd:match("([^\n]*)")
                          --print("cmd=" .. cmd)
                          self:setValue("Text", cmd)
                        end
                      end
											return msg
										end,
  }
  
  return out
end





StatPort = ui.Group:new
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
											self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
										end,
      msgUser = function(self, msg)
											local ud = msg[-1]
                      --print("ud", ud)
                      local cmd = ud:match("<MESSAGE>(.*)")
                      if cmd then
                        --print("cmd=" .. cmd)
                        self:setValue("Text", cmd)
                      end
											return msg
										end,

    },
    
    ui.Group:new
    {
      Rows = 3,
      Columns = 4,
      Children = 
      {
          ui.Text:new{Class = "caption",Width=60, Text="WPos:"},
          posInd("wX"), posInd("wY"), posInd("wZ"), 
          ui.Text:new{Class = "caption",Width=60, Text="MPos:"},
          posInd("mX"), posInd("mY"), posInd("mZ"), 
          ui.Text:new{Class = "caption",Width=60, },
          ui.Button:new{Width=60, Text="x = 0"}, ui.Button:new{Width=60, Text="y = 0"}, ui.Button:new{Width=60, Text="z = 0"}, 
      },
    },

  }
}

