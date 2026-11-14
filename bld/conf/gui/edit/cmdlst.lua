local ui = require "tek.ui"
local List = require "tek.class.list"
local actions = require "conf.gui.edit.actions"


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
                  Selected = true,
                  onSelect = function(self)
                    ui.CheckMark.onSelect(self)
                    _G.Flags.AutoRedraw = self.Selected
                    if self.Selected then do_vparse() end
--                    local lst_wgt = self:getById("editor cmd list")
--                    local n = lst_wgt.SelectedLine
--                    self:getById("send from"):setValue("Text", tostring(n))
                  end,
                },
                ui.CheckMark:new
                {
                  Text = "Approximate arcs (G1)",
                  Selected = _G.Flags.ApproximateArcs ~= false,
                  onSelect = function(self)
                    ui.CheckMark.onSelect(self)
                    _G.Flags.ApproximateArcs = self.Selected
                    do_vparse(_G.Flags.AutoRedraw ~= false)
                  end,
                },
                ui.Button:new
                {
                  Style = "font:\b; color:olive;",
                  Text = "Update drawing",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    do_vparse()
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
            Tooltip = "Enter: save line and insert next. Update: save line. Send sel: send to controller.",
            onEnter = function(self)
              ui.Input.onEnter(self)
              actions.commit(self:getText(), true)
            end
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
                    actions.insert()
                  end,
                },
                ui.Button:new
                {
                  Text = "Update",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    actions.commit(self:getById("gedit"):getText(), false)
                  end,
                },
                ui.Button:new
                {
                  Text = "Delete",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    actions.remove()
                  end,
                },
                ui.Button:new
                {
                  Text = "Undo",
                  onClick = function(self) ui.Button.onClick(self); actions.undo() end,
                },
                ui.Button:new
                {
                  Text = "Redo",
                  onClick = function(self) ui.Button.onClick(self); actions.redo() end,
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
                  Text = "Send sel",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local cmd = self:getById("gedit"):getText()
                    Sender:newcmd("SINGLE")
                    Sender:newcmd(cmd)
                  end,
                },
                ui.Text:new{Class = "caption",Style="color:gray;", Text=" Send: ", Width=40,},
                ui.Button:new
                {
                  Text = "from sel",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local lst_wgt = self:getById("editor cmd list")
                    local n = lst_wgt.SelectedLine
                    if not n or n < 1 or n > #GTXT then return end
                    _G.Flags.SendFrom = n
                    self:getById("send from"):setValue("Text", tostring(n))
                  end,
                },
                ui.Text:new{Text="", Width=40, Id="send from"},
                ui.Button:new
                {
                  Text = "to sel",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local lst_wgt = self:getById("editor cmd list")
                    local n = lst_wgt.SelectedLine
                    if not n or n < 1 or n > #GTXT then return end
                    _G.Flags.SendTo = n --+1
                    self:getById("send to"):setValue("Text", tostring(n))
                  end,
                },
                ui.Text:new{Text="", Width=40, Id="send to"},
            }
          },

      
      },
    },
  }
}

