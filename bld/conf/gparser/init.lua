
--local ui = require "tek.ui"

gparser = require "gcodeparser"
if _G.Flags and _G.Flags.ApproximateArcs == nil then
  _G.Flags.ApproximateArcs = true
end

GTXT = gparser.new_store()
GTXT_parsed = gparser.new_store()

require "conf.gparser.vparse"
require "conf.gparser.sparse"

