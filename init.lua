do
  -- Get the gpu and proxy it to the screen
  local gpu = component.proxy(component.list("gpu")())
  local screen = component.proxy(component.list("screen")())
  gpu.bind(screen.address)
  gpu.setResolution(gpu.maxResolution())
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  -- Draw the mOS logo
  gpu.set(1, 1, "mOS loader 1.0")
  computer.pullSignal(2)
  local function playNote(frequency, duration)
    computer.beep(frequency, duration * 1.7)
  end


  
  -- Define the notes and their corresponding frequencies and durations
  local notes = {
    { frequency = 523.25, duration = 0.1 },
    { frequency = 659.25, duration = 0.1 },
    { frequency = 783.99, duration = 0.2 },
    { frequency = 880, duration = 0.1 },
    { frequency = 659.25, duration = 0.1 }
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
  computer = require("computer")
  component = require("component")
  -- Load mBOOT.lua config
  local config = loadfile("/etc/mBOOT.lua")()
  local filetoexec = config.bootfile
  local reason, err = xpcall(loadfile(filetoexec), debug.traceback)
  local gpu = component.gpu
  if not reason then
    w,h = gpu.getResolution()
    gpu.fill(1, 1, w, h, " ")
    -- Detect if error starts with "attempt to call a nil value"
    if err:sub(1, 27) == "attempt to call a nil value" then
      err = "Could not find file " .. filetoexec .. " to boot. mOS may be corrupted."
    end
    computer.beep(1350, 1.6)
    gpu.set(1, 1, "Error: " .. err)
    gpu.set(1, 2,"Press any key or click to retry")
    os.sleep(0.5)
    while true do
      local event, _, _, key = computer.pullSignal()
      -- Key down or mouse click
      if event == "key_down" or event == "touch" then
        break
      end
    end
  end
end
