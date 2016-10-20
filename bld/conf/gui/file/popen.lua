local ui = require "tek.ui"
local List = require "tek.class.list"

--print(ui.ProgDir)

local ico_new = ui.loadImage("conf/icons/new32.ppm")
local ico_popen = ui.loadImage("conf/icons/serial32.ppm")
local ico_save = ui.loadImage("conf/icons/save32.ppm")

local mk_nm = ""
local port_nm = ""
local baud_nm = ""


wjt_portslist = ui.PopList:new
      {
        Id = "Port:",
        Width = 140,
        SelectedLine = 1,
        ListObject = List:new
        {
          Items = {}
        },
        onSelect = function(self)
          ui.PopList.onSelect(self)
          local item = self.ListObject:getItem(self.SelectedLine)
          if item then
            port_nm = item[1][1]
          end
        end,
      }


wjt_baudslist = ui.PopList:new
      {
        Id = "Baud:",
        Width = 140,
        SelectedLine = 1,
        ListObject = List:new
        {
          Items = {}
        },
        onSelect = function(self)
          ui.PopList.onSelect(self)
          local item = self.ListObject:getItem(self.SelectedLine)
          if item then
-- 											self:getById("japan-combo"):setValue("SelectedLine", self.SelectedLine)
            baud_nm = item[1][1]
--            self:getById("popup-show"):setValue("Text", item[1][1])
          end
        end,
      }


local get_mks = function()
  local lst = MKs:list()
  local i, mk
  local out = {}
  for i,mk in ipairs(lst) do
    out[#out + 1] = {{ mk }}
  end
  return out
end


local set_ports_bauds = function(mk_type)
  mk_nm = mk_type
  
  local mk = MKs:get(mk_type)
  local lst = mk:info()
  local i, v
  local out = {}
  for i,v in ipairs(lst.ports) do
    out[#out + 1] = {{ "" .. v }}
  end
  wjt_portslist:setList(List:new { Items = out })
  wjt_portslist:setValue("SelectedLine", 1)
  
  out = {}
  for i,v in ipairs(lst.bauds) do
    out[#out + 1] = {{ "" .. v }}
  end
  wjt_baudslist:setList(List:new { Items = out })
end





return ui.Group:new
{
  Orientation = "vertical",
--  Width = 75+120+32,
  Children = 
  {
    StatPort,
    ui.Group:new
    {
	Children = 
	{
	    ui.Group:new
	    {
		--Orientation = "vertical",
		Columns = 2,
		Rows = 3,
		Children = 
		{
      ui.Text:new
      {
        Class = "caption",
        Width = 75,
        Text = "Device:",
      },
      ui.PopList:new
      {
        Id = "Dev:",
        Width = 140,
        SelectedLine = 1,
        ListObject = List:new
        {
          Items = get_mks()
        },
        onSelect = function(self)
          ui.PopList.onSelect(self)
          local item = self.ListObject:getItem(self.SelectedLine)
          if item then
            set_ports_bauds(item[1][1])
          end
        end,

      },
      
      ui.Text:new
      {
        Class = "caption",
        Width = 75,
        Text = "Port:",
      },
      wjt_portslist,
          
      ui.Text:new
      {
        Class = "caption",
        Width = 75,
        Text = "Baud:",
      },
      wjt_baudslist,
    }
  },
  
  ui.ImageWidget:new 
  {
    Image = ico_popen,
		Width = 32,
		Height = 32,
		Mode = "button",
		Style = "padding: 1",
--		ImageAspectX = 2,
--		ImageAspectY = 3,
		onClick = function(self)
			ui.ImageWidget.onClick(self)
      --print(port_nm, baud_nm)
			Sender:newcmd("PORT")
			Sender:newcmd(mk_nm)
			Sender:newcmd(port_nm)
			Sender:newcmd(baud_nm)
			StatPort:setValue("Text", "Connected to: " .. port_nm)
      
      MK = MKs:get(mk_nm)
      MKstate = "STOP"
      
      --print ("nm=", mk_nm, "MKs=", MKs, "MK=", MK)
      
      --exec.sendmsg("sender", "PORT")
      --exec.sendmsg("sender", "/dev/ttyUSB0")
--[[
			if PORT == nil then
			    -- Open /dev/ttyUSB0 with baudrate 115200, and defaults of 8N1, no flow control
			    PORT = rs232("/dev/ttyUSB0", 115200)
--			    PORT:write("Hello World!")
			    PORT:write("$$\n")
			    -- Read up to 128 bytes with 500ms timeout
			    local buf
          repeat
            buf = PORT:read(128, 500)
            print(string.format("read %d bytes: _%s_", #buf, buf))
          until(buf == "")
          
          Sender:start()
			else
			    PORT:close()
			    PORT = nil
			end
]]
		end
  },
	},
    },
  }
}

