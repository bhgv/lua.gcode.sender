
ui = require "tek.ui"


return ui.Group:new
{
  Orientation = "horisontal",
  Children = 
  {
    symBut(
      "\u{E052}",
      function(self)
        print("new!", self)
      end
    ),

    symBut(
      "\u{E03c}",
      function(self)
        local app = self.Application
        app:addCoroutine(function()
                --List = require "tek.class.list"
--                local NumberedList = require "conf.gui.classes.numberedlist"
                local status, path, select = app:requestFile
                {
                  Path = self.old_path or os.getenv("HOME"), 
                  SelectMode = 
                --		    "multi",
                        "single",
                  DisplayMode = 
                        "all" 
                --		    or "onlydirs"
                }
                if status == "selected" then
                  self.old_path = path
                  
                  GFNAME = path .. "/" .. select[1]
                  app:getById("status main"):setValue("Text", "Opening " .. GFNAME)
                  --print(status, path, table.concat(select, ", "))
                  local f = io.open(GFNAME, "r")
                  if f ~= nil then
                    local txt = f:read("*a")
                    GSTXT = txt
                    f:close()
                    local l 
                    GTXT = {}
                    local lst = {}
                    for l in txt:gmatch("[^\u{a}\u{d}]+") do
                      table.insert(GTXT, l)
                    end
                    initialiseEditor()
                    do_vparse()
                  end
                  app:getById("status main"):setValue("Text", GFNAME)
                end
            end 
        )
      end
    ),

    symBut(
      "\u{E03d}",
      function(self)
    --		self:setValue("Image", self.Pressed and RadioImage2 or RadioImage1)
      end
    ),
  }
}

