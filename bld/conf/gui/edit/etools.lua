
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




local transformModeBtns
local transformInput

local transformUnselOtherModes = function(self)
  local i,b
  for i,b in ipairs(transformModeBtns) do
    if b ~= self then
      b:setValue("Selected", false)
    end
  end
end


local symBut = symButSm

local noopModel = symBut("\u{e089}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", "")
    transf.CurOp = "none"
    --[[  {
    Move = {x=0, y=0, z=0},
    Rotate = 0,
    Scale = {x=1.0, y=1.0, z=1.0},
    Mirror = {h=false, v=true},
    }  ]]

  end
)
noopModel:setValue("Selected", true)

local moveModel = symBut("\u{e0a0}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", 
                  string.format( "X=%.2f, Y=%.2f, Z=%.2f",
                                  transf.Move.x,
                                  transf.Move.y,
                                  transf.Move.z 
                  )
    )
    transf.CurOp = "move"
  end
)
local scaleModel = symBut("\u{e0b4}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", 
                  string.format( "X=%.2f, Y=%.2f, Z=%.2f",
                                  transf.Scale.x,
                                  transf.Scale.y,
                                  transf.Scale.z 
                  )
    )
    transf.CurOp = "scaleXY"
  end
)
local scaleXModel = symBut("\u{e0b5}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", 
                  string.format( "X=%.2f",
                                  transf.Scale.x 
                  )
    )
    transf.CurOp = "scaleX"
  end
)
local scaleYModel = symBut("\u{e0b6}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", 
                  string.format( "Y=%.2f",
                                  transf.Scale.y 
                  )
    )
    transf.CurOp = "scaleY"
  end
)
local rotateModel = symBut("\u{e0b3}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", 
                  string.format( "Angle=%.2f",
                                  math.deg(transf.Rotate)
                  )
    )
    transf.CurOp = "rotate"
  end
)
local mirrorXModel = symBut("\u{e0e6}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", 
                                  "h=" ..
                                  ((transf.Mirror.h and "yes") or "no")
    )
    transf.CurOp = "mirrorX"
  end
)
local mirrorYModel = symBut("\u{e0e7}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    transformUnselOtherModes(self)
    transformInput:setValue("Text", 
                                  "v=" ..
                                  ((transf.Mirror.v and "yes") or "no")
    )
    transf.CurOp = "mirrorY"
  end
)



transformInput = ui.Input:new{Width = 200,}
local transformOk = symButSm("\u{e0cc}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    --[[  {
    Move = {x=0, y=0, z=0},
    Rotate = 0,
    Scale = {x=1.0, y=1.0, z=1.0},
    Mirror = {h=false, v=true},
    }  ]]

  end
)

_G.Flags.TransformInput = transformInput


transformModeBtns = {
    noopModel,
    moveModel,
    scaleModel,
--    scaleXModel,
--    scaleYModel,
    rotateModel,
    mirrorXModel,
    mirrorYModel
}


local i,b
for i,b in ipairs(transformModeBtns) do
  b:setValue("Mode", "touch")
end


return ui.Group:new
{
  Orientation = "horisontal",
  Children = 
  {
    require "conf.gui.common.panel_file",
    
    ui.Spacer:new{},
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
    
    ui.Spacer:new{},
    ui.Text:new{Text="edit\ntools:", Style="font::10;",Width=10,Class = "caption",},
    
    ui.Group:new{
      Rows = 2,
      Children = transformModeBtns,
    },
    
    ui.Spacer:new{},
    transformInput,
    transformOk,
  },
}

