

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
  end,
}
