
local ctrlrs = {
    Grbl = require "conf.controllers.grbl",
    Marlin = require "conf.controllers.marlin",
}

return {
    list = function()
	local ctl_lst = {}
	for k,v in pairs(ctrlrs) do
	    ctl_lst[#ctl_lst+1] = k
	end
	return ctl_lst
    end,

    get = function(self, ctl_name)
	return ctrlrs[ctl_name]
    end,
}
