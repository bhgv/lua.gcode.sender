local ui = require "tek.ui"
local List = require "tek.class.list"

--print(ui.ProgDir)


return ui.Group:new
{
  Orientation = "vertical",
--  Width = 75+120+32,
  Children = 
  {
    ui.Group:new
    {
      Orientation = "vertical",
      Width = "free",
      Children = 
      {
          ui.Group:new
          {
            --Legend = "t",
            Children = 
            {
                ui.CheckMark:new
                {
                  Text = "AutoUpdate drawing",
                  onSelect = function(self)
                    ui.CheckMark.onSelect(self)
--                    local lst_wgt = self:getById("editor cmd list")
--                    local n = lst_wgt.SelectedLine
--                    self:getById("send from"):setValue("Text", tostring(n))
                  end,
                },
                ui.Button:new
                {
                  Style = "font:\b; color:olive;",
                  Text = "Update drawing",
                  onClick = function(self)
                    ui.Button.onClick(self)
--                    local cmd = self:getById("gedit"):getText()
--                    Sender:newcmd("SINGLE")
--                    Sender:newcmd(cmd)
                  end,
                },
--                ui.Text:new{Class = "caption",Style="color:gray;", Text="  Send: ", Width=70,},
            }
          },

          ui.ListView:new
          {
            --Id = "editor cmd list",
            VSliderMode = "auto",
            HSliderMode = "auto",
            Headers = { "N", "gcode commands" },
            Child = gLstWdgtM,
          },
          ui.Input:new
          {
            Id = "gedit",
          },
          ui.Group:new
          {
            Children = 
            {
                ui.Button:new
                {
                  Text = "New",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local lst_wgt = self:getById("editor cmd list")
                    local n = lst_wgt.SelectedLine + 1
                    table.insert(GTXT, n, "")
                    lst_wgt:addItem({{ "", "" }}, n)
                  end,
                },
                ui.Button:new
                {
                  Text = "Update",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local cmd = self:getById("gedit"):getText()
                    local lst_wgt = self:getById("editor cmd list")
                    local n = lst_wgt.SelectedLine
                    GTXT[n] = cmd
                    lst_wgt:changeItem({{ "", cmd }}, n)
                  end,
                },
                ui.Button:new
                {
                  Text = "Delete",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local lst_wgt = self:getById("editor cmd list")
                    local n = lst_wgt.SelectedLine
                    table.remove(GTXT, n)
                    lst_wgt:remItem(n)
                  end,
                },
            }
          },
      
      
          ui.Group:new
          {
            Children = 
            {
                ui.Button:new
                {
                  Style = "font:\b; color:olive;",
                  Text = "Send selected",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local cmd = self:getById("gedit"):getText()
                    Sender:newcmd("SINGLE")
                    Sender:newcmd(cmd)
                  end,
                },
                ui.Text:new{Class = "caption",Style="color:gray;", Text="  Send: ", Width=70,},
                ui.Button:new
                {
                  Text = "from sel",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local lst_wgt = self:getById("editor cmd list")
                    local n = lst_wgt.SelectedLine
                    _G.Flags.SendFrom = n
                    self:getById("send from"):setValue("Text", tostring(n))
                  end,
                },
                ui.Text:new{Text="", Width=60, Id="send from"},
                ui.Button:new
                {
                  Text = "to sel",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local lst_wgt = self:getById("editor cmd list")
                    local n = lst_wgt.SelectedLine
                    _G.Flags.SendTo = n+1
                    self:getById("send to"):setValue("Text", tostring(n))
                  end,
                },
                ui.Text:new{Text="", Width=60, Id="send to"},
            }
          },

      
      },
    },
  }
}

