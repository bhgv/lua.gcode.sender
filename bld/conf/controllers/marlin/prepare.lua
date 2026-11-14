local gparser = require "gcodeparser"
local modal = {G17=true,G18=true,G19=true,G20=true,G21=true,G90=true,G91=true,
  ['G91.1']=true,G93=true,G94=true,M82=true,M83=true}

-- Marlin executes one primary command per serial line, unlike GRBL blocks.
return function(text)
  local out = gparser.new_store()
  for line in text:gmatch('[^\n]+') do
    local commands = 0
    local body = line:gsub('%f[%a]([GM]%d+%.?%d*)',function(word)
      if modal[word] then out[#out+1]=word; return '' end
      commands=commands+1
      return word
    end)
    assert(commands <= 1, 'Marlin needs one primary G/M command per source block')
    body=body:match('^%s*(.-)%s*$')
    if body ~= '' then out[#out+1]=body end
  end
  return out:concat('\n')
end
