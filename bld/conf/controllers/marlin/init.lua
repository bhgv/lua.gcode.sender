local exec = require "tek.lib.exec"
local rs232 = require('periphery').Serial
local lfs = require "lfs"
local PORT
local msg_buffer = ""
local pending = 0
local blocked = false
local waiting_user = false
local query_position = true

local ports = {
  "/dev/ttyACM0", "/dev/ttyACM1", "/dev/ttyACM2", "/dev/ttyACM3", "/dev/ttyACM4",
  "/dev/ttyUSB0", "/dev/ttyUSB1", "/dev/ttyUSB2", "/dev/ttyUSB3", "/dev/ttyUSB4",
}

local function temperatures(line)
  local out = {}
  for name,current in line:gmatch("([TB]%d*):%s*([+%-]?%d*%.?%d+)") do out[name .. "Cur"]=tonumber(current) end
  for name, current, target in line:gmatch("([TB]%d*):%s*([+%-]?%d*%.?%d+)%s*/%s*([+%-]?%d*%.?%d+)") do
    out[name .. "Cur"], out[name .. "Dst"] = tonumber(current), tonumber(target)
    if name == "T" or (name == "T0" and not out.tCur) then
      out.tSrc, out.tCur, out.tDst = name, tonumber(current), tonumber(target)
    end
  end
  -- Heating keepalive may omit the target temperature.
  if not out.tCur then
    local current = line:match("%f[%w]T:%s*([+%-]?%d*%.?%d+)")
    if current then out.tSrc, out.tCur = "T", tonumber(current) end
  end
  return out
end

local function position(line)
  -- Count X/Y/Z are step counts, not machine coordinates in mm.
  if line:match("^Count%s") then return end
  local coordinates = line:match("^(.-)%s+Count%s") or line
  local x = coordinates:match("%f[%w]X:%s*([+%-]?%d*%.?%d+)")
  local y = coordinates:match("%f[%w]Y:%s*([+%-]?%d*%.?%d+)")
  local z = coordinates:match("%f[%w]Z:%s*([+%-]?%d*%.?%d+)")
  local e = coordinates:match("%f[%w]E:%s*([+%-]?%d*%.?%d+)")
  if x and y and z then return {wX=tonumber(x),wY=tonumber(y),wZ=tonumber(z),ePos=tonumber(e)} end
end

return {
  out_access = false,
  home_command = "G28",
  StatPort_contents = require "conf.controllers.marlin.StatPort_contents",
  FileButtons_add = require "conf.controllers.marlin.FileButtons_add",
  ControlButtons_add = require "conf.controllers.marlin.ControlButtons_add",
  TerminalButtons_add = require "conf.controllers.marlin.TerminalButtons_add",

  info = function(self)
    return {name="marlin",ports=ports,bauds={115200,250000,57600}}
  end,

  open = function(self, port, speed)
    if not lfs.attributes(port) then return false end
    local ok, serial = pcall(rs232,port,speed)
    if not ok then return false end
    PORT = serial
    pending, msg_buffer, blocked, query_position, waiting_user = 0,"",false,true,false
    self.out_access = PORT ~= nil
    return PORT
  end,

  send = function(self, command)
    assert(not blocked, "Marlin is halted; reset or reconnect first")
    PORT:write(command)
    pending = pending + 1
    self.out_access = false
    return ""
  end,

  read = function(self)
    local line, rest = msg_buffer:match("^([^\r\n]*)[\r\n]+(.*)$")
    if not line then
      msg_buffer = msg_buffer .. (PORT:read(256,50) or "")
      line, rest = msg_buffer:match("^([^\r\n]*)[\r\n]+(.*)$")
    end
    if not line then return {} end
    msg_buffer = rest
    local msg = {msg=line,raw=line .. "\n"}
    if line:match("^ok$") or line:match("^ok%s") then
      pending = math.max(0,pending-1)
      msg.ok = true
    end
    local values = self:status_parse(line).stat
    msg.stat = next(values) ~= nil
    if line:match("^Error:") or line:match("^echo:Unknown command:") or line:match("^!!") then
      msg.err = true
      if line:lower():match("halt") or line:lower():match("kill") or line:match("^!!") then blocked=true end
    elseif line:match("^Resend:") or line:match("^rs%s") then
      blocked, msg.err = true,true
      msg.msg = "Error: Marlin requested resend; reconnect to resynchronize: " .. line
    elseif line == "start" then
      pending, blocked, waiting_user = 0,false,false
      msg.err = true -- A reset invalidates the host's current job.
      msg.msg = "Error: Marlin restarted"
    elseif line:match("^echo:busy: paused for user") or line:match("^busy: paused for user") then
      waiting_user, msg.action = true,"pause"
    elseif line:match("^//action:pause") then msg.action = "pause"
    elseif line:match("^//action:resume") then msg.action = "resume"
    elseif line:match("^//action:cancel") then msg.action = "cancel" end
    self.out_access = not blocked and pending == 0
    return msg
  end,

  help = function(self)
    self:send("M115\n")
    local text, acknowledged = "",false
    for i=1,100 do
      local reply = self:read()
      text = text .. (reply.raw or "")
      if reply.ok then acknowledged=true; break end
      if reply.err and reply.msg ~= "Error: Marlin restarted" then return {msg=text,err=true} end
    end
    return {msg=text,raw=text,ok=acknowledged,err=not acknowledged}
  end,

  init = function(self)
    local out = self:help()
    if out.err then return out end
    exec.sendmsg("sender","NEW")
    exec.sendmsg("sender","CALCULATE")
    for _,command in ipairs{"G21","G90"} do
      exec.sendmsg("sender","SINGLE"); exec.sendmsg("sender",command)
    end
    return out
  end,

  status_query = function(self)
    -- Marlin queries are normal acknowledged commands. Never inject one
    -- while a print/heating command is awaiting its own ok.
    if not self.out_access or blocked then return end
    self:send(query_position and "M114\n" or "M105\n")
    query_position = not query_position
  end,

  status_parse = function(self,line)
    local out = position(line) or {}
    for key,value in pairs(temperatures(line)) do out[key]=value end
    return {stat=out}
  end,

  pause = function(self)
    -- Pause the host stream. Already accepted planner moves finish normally.
  end,
  resume = function(self)
    if waiting_user and not blocked then
      self:send("M108\n")
      waiting_user = false
    end
  end,
  stop = function(self)
    if blocked then return end
    waiting_user = false
    self:send("M108\n")
    self:send("M410\n")
  end,
  emergency = function(self)
    PORT:write("M112\n")
    blocked, self.out_access = true,false
  end,

  go_xyz = function(self,dir)
    local command = "G0"
    for _,axis in ipairs{'x','y','z'} do
      if dir[axis] then command = command .. axis:upper() .. dir[axis] end
    end
    if command == "G0" then return end
    for _,line in ipairs{"G91",command,"G90"} do Sender:newcmd("SINGLE"); Sender:newcmd(line) end
  end,
  set_xyz = function(self,dir)
    local command = "G92"
    for _,axis in ipairs{'x','y','z'} do
      if dir[axis] then command = command .. axis:upper() .. dir[axis] end
    end
    if command ~= "G92" then Sender:newcmd("SINGLE"); Sender:newcmd(command) end
  end,
}
