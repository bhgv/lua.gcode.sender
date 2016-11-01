local ui = require "tek.ui"
local List = require "tek.class.list"

--print(ui.ProgDir)


return ui.Group:new
{
  Orientation = "vertical",
--  Width = 75+120+32,
  Children = 
  {
--  ui.Text:new
--    {
--	Text = "Not Connected",
--	Id = "pstat",
--    },
    ui.Group:new
    {
      Orientation = "vertical",
      Width = "free",
      Children = 
      {
        StatPort,
        
        ui.Group:new
        {
          Legend = "Terminal",
          Orientation = "vertical",
          Children =
          {
            ui.ListView:new
            {
              VSliderMode = "auto",
              HSliderMode = "auto",
              Headers = { "dir", "command", "resp"},
              Child = ui.Lister:new
              {
                --Id = "the-list",
                SelectMode = "single",
        --				ListObject = gcmdLst,
                
                onSelectLine = function(self)
                  ui.Lister.onSelectLine(self)
                  local line = self:getItem(self.SelectedLine)
                  if line then
                    App:getById("user cmd"):setValue("Text", line[1][2])
                    --self.Window:setRecord(line[1])
                  end
                end,
                    
                setup = function(self, app, win)
                  ui.Lister.setup(self, app, win)
                  --print(app, win)
                  app:addInputHandler(ui.MSG_USER, self, self.msgUser)
                end,
                
                cleanup = function(self)
                  ui.Lister.cleanup(self)
                  self.Application:remInputHandler(ui.MSG_USER, self, self.msgUser)
                end,
                
                msgUser = function(self, msg)
                  local ud = msg[-1]
                  --print(ud)
                  local cmd = ud:match("<PORT TX>(.*)")
                  if cmd ~= nil then
        --            cmd = cmd:match("([^\n]*)")
                    --print("cmd=" .. cmd)
                    self:addItem {{"Tx", cmd, ""}} --:match("[^\r\n]*")}}
                    if self:getN() > 100 then 
                      self:remItem(1) 
                    end
                    self:setValue("CursorLine", self:getN())
                  else
                    cmd = ud:match("<PORT RX>(.+)")
                    if cmd ~= nil then
                      local i = self:getN()
                      local line = self:getItem(i)
                      if line ~= nil then
                        line[1][3] = cmd
                        self:remItem(i)
                        self:addItem(line)
                      end
                    else
                      cmd = ud:match("<PORT RX MSG>(.+)")
                      if cmd ~= nil then
                        --cmd, t = cmd:match("([^\n]*)\r?\n?")
                        --print("rx=", cmd, t)
                        self:addItem {{"", cmd}} --:match("[^\r\n]*")}}
                        if self:getN() > 100 then 
                          self:remItem(1) 
                        end
        --              self:moveLine(self:getN(), true)
                        self:setValue("CursorLine", self:getN())
                      else
                        cmd = ud:match("<MESSAGE>error:[^%(]*%(ln%: (%d+)%)")
                        if cmd ~= nil then
                          self:setValue("SelectedLine", self:getN())
                        end
                      end
                    end
                  end
                  --self:setValue("Text", userdata)
                  return msg
                end,

              },
            },
            
            ui.Input:new
            {
              Id = "user cmd",
            },
            
            ui.Group:new
            {
              Children = 
              {
                ui.Button:new
                {
                  Text = "Send",
                  onClick = function(self)
                    ui.Button.onClick(self)
                    local ed = self:getById("user cmd")
                    local cmd = ed:getText()
                    ed:setValue("Text", " ")
                    --print(cmd)
                    Sender:newcmd("SINGLE")
                    Sender:newcmd(cmd)
                --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
                  end
                },
              }
            },
          },
        },
      },
    },
  }
}

