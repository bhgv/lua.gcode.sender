
local ui = require "tek.ui"
local files = require "conf.gparser.file"


return ui.Group:new
{
  Orientation = "horisontal",
  Children = 
  {
    symBut(
      "\u{E052}",
      function(self)
        require("conf.gui.edit.actions").reset_history()
        GTXT:clear()
        GTXT_parsed:clear()
        GFNAME = nil
        initialiseEditor()
        do_vparse()
        _G.Flags.isEdited = false
        self.Application:getById("status main"):setValue("Text", "New program")
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
                  
                  local filename = path .. "/" .. select[1]
                  local store, err = files.read(filename)
                  if store then
                    GTXT = store
                    require("conf.gui.edit.actions").reset_history()
                    GFNAME = filename
                    initialiseEditor()
                    local parsed, parse_err = do_vparse()
                    _G.Flags.isEdited = false
                    if not parsed then
                      app:getById("status main"):setValue("Text", tostring(parse_err))
                      return
                    end
                    app:getById("status main"):setValue("Text", GFNAME)
                  else
                    app:getById("status main"):setValue("Text", "Open failed: " .. tostring(err))
                  end
                end
            end 
        )
      end
    ),

    symBut(
      "\u{E03d}",
      function(self)
        local app = self.Application
        app:addCoroutine(function()
          require("conf.gui.edit.actions").flush()
          local filename = GFNAME
          if not filename then
            local status, path, selection = app:requestFile {
              Path = self.old_path or os.getenv("HOME"),
              SelectMode = "single",
              SelectText = "Save",
              Title = "Save G-code",
              Location = "program.gcode",
            }
            if status ~= "selected" or not selection[1] then return end
            filename = path .. "/" .. selection[1]
          end
          local saved, err = files.write(filename, GTXT)
          if saved then
            GFNAME = filename
            _G.Flags.isEdited = false
            app:getById("status main"):setValue("Text", "Saved " .. filename)
          else
            app:getById("status main"):setValue("Text", "Save failed: " .. tostring(err))
          end
        end)
      end
    ),
  }
}

