local gparser = require "gcodeparser"

local function selectLine(n)
  local list = App:getById("editor cmd list")
  list:setValue("CursorLine", n)
  list:setValue("SelectedLine", n)
  local input = App:getById("gedit")
  input:setValue("Text", GTXT[n] or "")
  if input.Window then input.Window:setFocusElement(input) end
end

local function changed(old_count, n)
  _G.Flags.isEdited = true
  updateEditorRange(old_count)
  local ok, err = do_vparse(_G.Flags.AutoRedraw ~= false)
  if not ok then n = math.min(#GTXT, tonumber(tostring(err):match("line (%d+)")) or n) end
  selectLine(n)
  if ok then
    App:getById("status main"):setValue("Text", "Checked " .. #GTXT .. " lines")
  end
  return ok, err
end

local undo_stack, redo_stack = {}, {}
local history_source

local function snapshot()
  return {store=GTXT:clone(), selected=App:getById("editor cmd list").SelectedLine,
    from=_G.Flags.SendFrom, to=_G.Flags.SendTo}
end

local function remember()
  if history_source ~= GTXT then undo_stack, redo_stack = {}, {} end
  history_source = GTXT
  undo_stack[#undo_stack+1] = snapshot()
  if #undo_stack > 20 then table.remove(undo_stack,1) end
  redo_stack = {}
end

local function restore(stack, other)
  if history_source ~= GTXT or #stack == 0 then return false end
  other[#other+1] = snapshot()
  local state = table.remove(stack)
  GTXT:copy_from(state.store)
  local items = {}
  for i=1,#GTXT do items[i] = {} end
  App:getById("editor cmd list"):setList(require("conf.gui.classes.numberedlist"):new{Store=GTXT,Items=items})
  _G.Flags.SendFrom, _G.Flags.SendTo = state.from, state.to
  return changed(#GTXT, math.max(0,math.min(state.selected or 0,#GTXT)))
end

return {
  reset_history = function()
    undo_stack, redo_stack, history_source = {}, {}, GTXT
  end,
  undo = function() return restore(undo_stack,redo_stack) end,
  redo = function() return restore(redo_stack,undo_stack) end,
  flush = function()
    if not _G.Flags.EditorReady then return true end
    local input = App:getById("gedit")
    local n = App:getById("editor cmd list").SelectedLine
    local text = input:getText()
    if text ~= (GTXT[n or 0] or "") then
      return require("conf.gui.edit.actions").commit(text, false)
    end
    return true
  end,
  commit = function(text, advance)
    local list = App:getById("editor cmd list")
    remember()
    local old_count = #GTXT
    local n = list.SelectedLine
    if not n or n < 1 or n > #GTXT then n = #GTXT + 1 end
    local lines = gparser.new_store()
    lines:load(text)
    if #lines == 0 then lines[1] = "" end
    if n > #GTXT then
      GTXT:insert(n, lines[1])
      list:addItem({{"", ""}}, n)
    else
      GTXT[n] = lines[1]
      list:changeItem({{"", ""}}, n)
    end
    for i = 2, #lines do
      GTXT:insert(n + i - 1, lines[i])
      list:addItem({{"", ""}}, n + i - 1)
    end
    n = n + #lines - 1
    if advance then
      n = n + 1
      GTXT:insert(n, "")
      list:addItem({{"", ""}}, n)
    end
    return changed(old_count, n)
  end,

  insert = function()
    local list = App:getById("editor cmd list")
    remember()
    local count = #GTXT
    local n = math.max(1, math.min(count + 1, (list.SelectedLine or 0) + 1))
    GTXT:insert(n, "")
    list:addItem({{"", ""}}, n)
    return changed(count, n)
  end,

  remove = function()
    local list = App:getById("editor cmd list")
    local n = list.SelectedLine
    if not n or n < 1 or n > #GTXT then return end
    remember()
    local count = #GTXT
    GTXT:remove(n)
    list:remItem(n)
    return changed(count, math.min(n, #GTXT))
  end,
}
