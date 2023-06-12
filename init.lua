do
  -- Get the gpu and proxy it to the screen
  local gpu = component.proxy(component.list("gpu")())
  local screen = component.proxy(component.list("screen")())
  gpu.bind(screen.address)
  gpu.setResolution(gpu.maxResolution())
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  local w, h = gpu.maxResolution()
  gpu.fill(1, 1, w, h, " ")
  -- Draw the mOS logo
  gpu.set(1, 1, "mOS loader 1.0")
  computer.pullSignal(2)
  local function playNote(frequency, duration)
    computer.beep(frequency, duration * 1.7)
  end


  
  -- Define the notes and their corresponding frequencies and durations
  local notes = {
    { frequency = 423.25, duration = 0.1 },
    { frequency = 559.25, duration = 0.1 },
    { frequency = 683.99, duration = 0.2 },
    { frequency = 780, duration = 0.1 },
    { frequency = 559.25, duration = 0.1 }
  }
  
  -- Play the notes one by one
  for i, note in ipairs(notes) do
    playNote(note.frequency, note.duration)
  end
  local addr, invoke = computer.getBootAddress(), component.invoke
  local function loadfile(file)
    local handle = assert(invoke(addr, "open", file))
    local buffer = ""
    repeat
      local data = invoke(addr, "read", handle, math.huge)
      buffer = buffer .. (data or "")
    until not data
    invoke(addr, "close", handle)
    return load(buffer, "=" .. file, "bt", _G)
  end
  loadfile("/lib/core/boot.lua")(loadfile)
end

while true do
  local reason, err = xpcall(require("shell").getShell(), function(msg)
    return tostring(msg).."\n"..debug.traceback()
  end)
  local gpu = component.gpu
  if not reason then
    w,h = gpu.getResolution()
    computer.beep(1350, 1.6)
    gpu.fill(1, 1, w, h, " ")
    if not require("shell").getShell() then
      error("Shell not found")
    else
      error(err)
    end
  end
end
