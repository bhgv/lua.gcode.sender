local ui = require "tek.ui"


return function()

  return ui.Group:new
  {
    Children =
    {
      ui.Text:new{Text="Setti\nngs:", Style="font::10;",Width=10,Class = "caption",},
      ui.Group:new
      {
        Rows = 2,
        Columns = 2,
        Children =
        {
          symButSm(
            "EPROM->",
            function(self)
              Sender:newcmd("SINGLE")
              Sender:newcmd("M501") -- disable software endstops
            end,
            nil,
            true
          ),
        
          symButSm(
            "Default->",
            function(self)
            end,
            nil,
            true
          ),
--[[        
        symButSm(
          "EPROM->Settings",
          function(self)
          end,
          nil,
          false
        ),
]]
        },
      },
    },
  }
end
