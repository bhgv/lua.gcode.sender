
--local ui = require "tek.ui"

gparser = require "gcodeparser"

GTXT = gparser.new_store()
GTXT_parsed = gparser.new_store()

require "conf.gparser.vparse"
require "conf.gparser.sparse"

