
g = require "conf.gen.gcode"


local lobe_roots = function(pars) 
  g:start()
  g:absolute()
  g:walk_to{x=10, z=5}
  g:work_to{x=20, y=-10, z=6}
  g:walk_to{x=5, z=-15}
  g:work_to{x=10, y=10}
  g:finish()
end


return {
  name = "TEst2",
  type = "plugin", 
  gui = "button",
  image = nil,
  symbol = "\u{e003}",
  params = {
    tes= 24,
    zus= 3
  },
  exec = function(self, pars)
    for k,v in pairs(pars) do
      print("exec ", k, v)
    end
    lobe_roots(pars)
  end,
}
