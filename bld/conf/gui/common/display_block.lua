
ui = require "tek.ui"



local disp_percent_view = ui.Text:new{Text="100%", Width=40,}

_G.Flags.ShowScale = function(n)
  disp_percent_view:setValue("Text", string.format("%0.2f", n) .. "%")
end

Display = require "conf.gui.common.display"


local posX = ui.Text:new {Width=60}
local posY = ui.Text:new {Width=60}



local projXY, projXYZ

projXY = symButSm("\u{e0e0}", function(self) 
            projXYZ:setValue("Selected", false)
            _G.Flags.DisplayProection = "xy"
            Display.Changed = true
        end)
projXY:setValue("Mode", "touch")
projXY:setValue("Selected", true)
  
projXYZ = symButSm("\u{e0e1}", function(self) 
            projXY:setValue("Selected", false)
            _G.Flags.DisplayProection = "xyz"
            Display.Changed = true
        end)
projXYZ:setValue("Mode", "touch")


local modeMv, modeEd

modeEd = symButSm(--[["\u{e089}"]] "\u{e0a3}", function(self) 
            modeMv:setValue("Selected", false)
            _G.Flags.DisplayMode = "select"
        end)
modeEd:setValue("Mode", "touch")

modeMv = symButSm("\u{e0a0}", function(self) 
            modeEd:setValue("Selected", false)
            _G.Flags.DisplayMode = "drag"
        end)
modeMv:setValue("Mode", "touch")
modeMv:setValue("Selected", true)


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
        projXY,
        projXYZ,
        
        ui.Text:new{Text="scale:", Width=20, Class = "caption"},
        symButSm("\u{e0de}", function(self) 
            local n = _G.Flags.DispScale --tonumber(disp_percent_view.Text:match("(%d*%.?%d*)"))
            n = n/1.1
            if n < 10 then n = 10 end
            _G.Flags.DispScale = n
            --disp_percent_view:setValue("Text", string.format("%0.2f", n) .. "%")
            _G.Flags.ShowScale(n)
            if _G.Flags.AutoRedraw then
              Display.Changed = true
            end
        end),
        disp_percent_view,
        symButSm("\u{e0dd}", function(self) 
            local n = _G.Flags.DispScale --tonumber(disp_percent_view.Text:match("(%d*%.?%d*)"))
            n = n*1.1
            _G.Flags.DispScale = n
            --disp_percent_view:setValue("Text", string.format("%0.2f", n) .. "%")
            _G.Flags.ShowScale(n)
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
        modeEd,
        modeMv,
      
        ui.Text:new{Text="pos X:", Width=10,Class = "caption"},
        posX,
        ui.Text:new{Text=" Y:", Width=10,Class = "caption"},
        posY,
      }
    },
    
    Display,
  }
}


_G.Flags.showMouseXY = function(x, y)
  if x then
    posX:setValue("Text", string.format("%0.2f", x))
  end
  if y then
    posY:setValue("Text", string.format("%0.2f", y))
  end
end
