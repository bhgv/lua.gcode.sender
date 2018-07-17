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
              Sender:newcmd("M501")
            end,
            nil,
            true
          ),
          symButSm(
            "Default->",
            function(self)
              Sender:newcmd("SINGLE")
              Sender:newcmd("M502")
            end,
            nil,
            true
          ),
          symButSm(
            "->EPROM",
            function(self)
              Sender:newcmd("SINGLE")
              Sender:newcmd("M500")
            end,
            nil,
            true
          ),
          symButSm(
            "->Terminal",
            function(self)
              Sender:newcmd("SINGLE")
              Sender:newcmd("M503")
            end,
            nil,
            true
          ),
        },
      },
    },
  }
end
