
local ui = require "tek.ui"

--print(ui.ProgDir)

local function do_seek(mask, from)
  local gt = GTXT
  local i,ln
  if from == 0 then from = 1 end
  for i = from,#gt do
    ln = gt[i]
    --print(i, ln)
    if ln:match(mask) then
      return i
    end
  end
  return from
end

local function do_replace(mask, repl, from)
  local gt = GTXT
  local i,ln
  if from == 0 then from = 1 end
  for i = from,#gt do
    ln = gt[i]
    --print(i, ln)
    if ln:match(mask) then
      return i, ln:gsub(mask, repl)
    end
  end
  return from, gt[from]
end


local seekTo = ui.Input:new{
  Width=100, 
  Style=[[
          font::11;
          margin: 0;
          padding: 0;
  ]],
  Text ="",
}
local replaceWith = ui.Input:new{
  Width=100, 
  Style=[[
          font::11;
          margin: 0;
          padding: 0;
  ]],
  Text="",
}

local seekToB = symBut("\u{e0e2}", 
  function(self) 
    local lst_wgt = self:getById("editor cmd list")
    local msk = seekTo:getText()
    if msk and msk ~= "" then
      local from = lst_wgt.SelectedLine or 1
      local n = do_seek(msk, from)
      
      lst_wgt:setValue("CursorLine", n)
      lst_wgt:setValue("SelectedLine", n)
    end
  end
)
local replaceWithB = symBut("\u{e0e4}", 
  function(self) 
    local lst_wgt = self:getById("editor cmd list")
    local msk = seekTo:getText()
    local repl = replaceWith:getText()
    if msk and msk ~= "" then
      local from = lst_wgt.SelectedLine or 1
      if repl and repl ~= "" then
        local n, ln = do_replace(msk, repl, from)
        
        GTXT[n] = ln
        lst_wgt:changeItem({{ "", ln }}, n)
        
        if _G.Flags.AutoRedraw then
          do_vparse()
        end
        
        lst_wgt:setValue("CursorLine", n)
        lst_wgt:setValue("SelectedLine", n)
      else
        local n = do_seek(msk, from)
        
        lst_wgt:setValue("CursorLine", n)
        lst_wgt:setValue("SelectedLine", n)
      end
    end
  end
)

return ui.Group:new
{
  Orientation = "horisontal",
  Children = 
  {
    require "conf.gui.common.panel_file",
    ui.Group:new{
      Columns = 2,
      Children = {
        ui.Text:new{Text="Seek to:", Style="font::10;",Width=20,Class = "caption",},
        seekTo,
        ui.Text:new{Text="Replace:", Style="font::10;",Width=20,Class = "caption",},
        replaceWith,
      },
    },
    seekToB,
    replaceWithB,
    
    
  },
}

