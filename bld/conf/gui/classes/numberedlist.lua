
local List = require "tek.class.list"


local NumberedList = List:newClass({_NAME="_numberedlist"})

--[[
function NumberedList.new(class, self)
  local o = List:new(self)
  return o
end
]]

-- Keep only layout/selection metadata in Lua; read text from the native store.
local function nativeItem(self, itm, lnr)
  itm.Line = lnr
  if getmetatable(itm) then return itm end
  return setmetatable(itm, {
    __index = function(row, key)
      if key == 1 then return {tostring(row.Line), self.Store[row.Line]} end
    end,
  })
end

function NumberedList:getItem(lnr)
  local itm = List.getItem(self, lnr)
  if itm then
    if self.Store then
      return nativeItem(self, itm, lnr)
    end
    itm[1][1] = tostring(lnr)
  end
  return itm
end

function NumberedList:addItem(entry, lnr)
  return List.addItem(self, self.Store and {} or entry, lnr)
end

function NumberedList:changeItem(entry, lnr)
  if self.Store then return self:getItem(lnr) ~= nil end
  return List.changeItem(self, entry, lnr)
end

return NumberedList
