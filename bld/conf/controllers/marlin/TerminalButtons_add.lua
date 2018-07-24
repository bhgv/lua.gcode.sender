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

      ui.Group:new
      {
        Rows = 2,
        Columns = 2,
        Children =
        {
            ui.Text:new{Text="Extr Temp:", Style="font::10;",Width=20,Class = "caption",},
            ui.Input:new
            {
              --Id = "user cmd",
              onEnter = function(self)
                ui.Input.onEnter(self)
                local num = tonumber(self:getText())
                --self:setValue("Text", " ")
                print(num)
                if num then
                  Sender:newcmd("SINGLE")
                  Sender:newcmd("M104 S" .. num)
                end
              end
            },

            ui.Text:new{Text="Bed Temp:", Style="font::10;",Width=20,Class = "caption",},
            ui.Input:new
            {
              --Id = "user cmd",
              onEnter = function(self)
                ui.Input.onEnter(self)
                local num = tonumber(self:getText())
                --self:setValue("Text", " ")
                print(num)
                if num then
                  Sender:newcmd("SINGLE")
                  Sender:newcmd("M140 S" .. num)
                end
              end
            },
        },
      },
    },
  }
end
