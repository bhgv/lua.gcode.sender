local gparser = require "gcodeparser"

return {
  read = function(filename)
    local f, err = io.open(filename, "rb")
    if not f then return nil, err end
    local text, read_err = f:read("*a")
    local closed, close_err = f:close()
    if not text then return nil, read_err end
    if not closed then return nil, close_err end
    local store = gparser.new_store()
    store:load(text)
    return store
  end,

  write = function(filename, store)
    local f, err = io.open(filename, "wb")
    if not f then return nil, err end
    for i = 1, #store do
      local written, write_err = f:write(store[i], "\n")
      if not written then
        f:close()
        return nil, write_err
      end
    end
    return f:close()
  end,
}
