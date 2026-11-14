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

return {
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
    local count = #GTXT
    GTXT:remove(n)
    list:remItem(n)
    return changed(count, math.min(n, #GTXT))
  end,
}
