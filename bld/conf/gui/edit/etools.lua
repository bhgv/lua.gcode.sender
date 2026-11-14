
local ui = require "tek.ui"

--print(ui.ProgDir)

local actions = require "conf.gui.edit.actions"

local function do_seek(mask, from)
  for i = math.max(1, from or 1), #GTXT do
    local ok, found = pcall(string.find, GTXT[i], mask)
    if not ok then return nil, found end
    if found then return i end
  end
  return nil, "No match"
end

local function do_replace(mask, repl, from)
  local n, err = do_seek(mask, from)
  if not n then return nil, err end
  local ok, text = pcall(string.gsub, GTXT[n], mask, repl)
  if not ok then return nil, text end
  return n, text
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
      local n, err = do_seek(msk, from)
      if not n then
        App:getById("status main"):setValue("Text", tostring(err))
        return
      end
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
      local n, ln = do_replace(msk, repl or "", from)
      if not n then
        App:getById("status main"):setValue("Text", tostring(ln))
        return
      end
      lst_wgt:setValue("SelectedLine", n)
      actions.commit(ln, false)
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


local transformCoords = require "conf.utils.transform_coords"

transformInput = ui.Input:new{Width = 200,}
local transformOk = symButSm("\u{e0cc}", 
  function(self) 
    local transf = _G.Flags.Transformations 
    
    local inp = transformInput:getText()
    local op = transf.CurOp
    local x, y, z, a
    
    --print (inp)
    if op == "move" then
      local tr_mv = transf.Move
      x = inp:match("[xX]%s*=%s*([%+%-]?%s*%d*%.?%d*)")
      y = inp:match("[yY]%s*=%s*([%+%-]?%s*%d*%.?%d*)")
      z = inp:match("[zZ]%s*=%s*([%+%-]?%s*%d*%.?%d*)")
      tr_mv.x, tr_mv.y, tr_mv.z = tonumber(x), tonumber(y), tonumber(z)
      --print("Move", x, y, z)
      
    elseif op == "scaleXY" then
      local tr_sc = transf.Scale
      x = inp:match("[xX]%s*=%s*([%+%-]?%s*%d*%.?%d*)")
      y = inp:match("[yY]%s*=%s*([%+%-]?%s*%d*%.?%d*)")
      z = inp:match("[zZ]%s*=%s*([%+%-]?%s*%d*%.?%d*)")
      tr_sc.x, tr_sc.y, tr_sc.z = tonumber(x) or tr_sc.x, tonumber(y) or tr_sc.y, tonumber(z) or tr_sc.z
      --print("Scale", x, y, z)
      
    elseif op == "mirrorX" then
      transf.Mirror.h = inp:lower():match("h%s*=%s*yes") ~= nil
    elseif op == "mirrorY" then
      transf.Mirror.v = inp:lower():match("v%s*=%s*yes") ~= nil
    elseif op == "rotate" then
      a = inp:match("[Aa][nN][gG][lL]?[eE]?%s*=%s*([%+%-]?%s*%d*%.?%d*)")
      if tonumber(a) then transf.Rotate = math.rad(tonumber(a)) end
      --print("Rotate", a)
    end
    
    Display.Bnd = require("conf.utils.transform_bounds")(Display.Bnd0)

    Display.Changed = true
    
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

