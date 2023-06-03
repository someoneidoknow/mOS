local fs = require("filesystem")
local filesystem = fs
local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
term.setCursorBlink(true) -- Enable cursor blinking
path = "/home"
local gpu = component.gpu
w,h = gpu.getResolution()
gpu.fill(1, 1, w, h, " ")
-- Create an event to mount a filesystem when it is inserted, and unmount it when it is removed
local function onComponentAdded(address, componentType)
    if componentType == "filesystem" then
        -- Proxy the component to get its label, then mount it
        local proxy = component.proxy(address)
        local label = proxy.getLabel()
        fs.mount(address, "/mnt/".. label)
    end
end

local function onComponentRemoved(address, componentType)
    if componentType == "filesystem" then
        local proxy = component.proxy(address)
        local label = proxy.getLabel()
        fs.umount("/mnt/".. label)
    end
end

-- Function to check if connected filesystems exist, if not, unmount them

-- Register the event listeners
event.listen("component_added", onComponentAdded)
event.listen("component_removed", onComponentRemoved)

shell = {}

function shell.resolve(path1, ext)
    checkArg(1, path1, "string")
    if filesystem.exists(path1) and filesystem.isDirectory(path1) then
      if path == "/" then
        return "/"..path1
      end
    elseif filesystem.exists(path.."/"..path1) and filesystem.isDirectory(path.."/"..path1) then
        if path == "/" then
            return "/"..path1
        else
            return path.."/"..path1
        end
      elseif filesystem.exists("/"..path1) and filesystem.isDirectory("/"..path1) then
        return "/"..path1
      end
    local dir = path1
    if dir:find("/") ~= 1 then
      dir = fs.concat(path1, dir)
    end
    local name = fs.name(path1)
    dir = fs[name and "path" or "canonical"](dir)
    local fullname = fs.concat(dir, name or "")
  
    if not ext then
      return fullname
    elseif name then
      checkArg(2, ext, "string")
      -- search for name in PATH if no dir was given
      -- no dir was given if path has no /
      local search_in = path:find("/") and dir or path
      for search_path in string.gmatch(search_in, "[^:]+") do
        -- resolve search_path because they may be relative
        local search_name = fs.concat(shell.resolve(search_path), name)
        if not fs.exists(search_name) then
          search_name = search_name .. "." .. ext
        end
        -- extensions are provided when the caller is looking for a file
        if fs.exists(search_name) and not fs.isDirectory(search_name) then
          return search_name
        end
      end
    end
  
    return nil, "file not found"
  end
  
  function shell.parse(...)
    local params = table.pack(...)
    local args = {}
    local options = {}
    local doneWithOptions = false
    for i = 1, params.n do
      local param = params[i]
      if not doneWithOptions and type(param) == "string" then
        if param == "--" then
          doneWithOptions = true -- stop processing options at `--`
        elseif param:sub(1, 2) == "--" then
          local key, value = param:match("%-%-(.-)=(.*)")
          if not key then
            key, value = param:sub(3), true
          end
          options[key] = value
        elseif param:sub(1, 1) == "-" and param ~= "-" then
          for j = 2, unicode.len(param) do
            options[unicode.sub(param, j, j)] = true
          end
        else
          table.insert(args, param)
        end
      else
        table.insert(args, param)
      end
    end
    return args, options
  end

function chdir(dir)
    path = dir
end

function pwd()
    return path
end

function ls(dir)
    local listing = {files = {}, dirs = {}}
    for file in fs.list(dir) do
        if fs.isDirectory(fs.concat(dir, file)) then
            listing.dirs[#listing.dirs + 1] = file
        else
            listing.files[#listing.files + 1] = file
        end
    end
    return listing
end

function formatListing(listing)
    local result = ""
    for _, dir in ipairs(listing.dirs) do
      result = result .. "\27[34m" .. dir .. "\27[0m\n"
    end
    for _, file in ipairs(listing.files) do
      result = result .. "\27[32m" .. file .. "\27[0m\n"
    end
    return result
end


function cat(file)
    local handle, reason = io.open(file)
    if not handle then
        return nil, reason
    end
    local contents = handle:read("*a")
    handle:close()
    return contents
end

function print(...)
    local args = table.pack(...)
    for i = 1, args.n do
        args[i] = tostring(args[i])
    end
    io.write(table.concat(args, "\t") .. "\n")
end

-- Start the shell
while true do
    -- show the prompt
    io.write("\27[36m" .. path .. "\27[0m> ")
    -- read the input
    local command = io.read()
    -- split the input by spaces
    local args = {}
    for arg in command:gmatch("%S+") do
        table.insert(args, arg)
    end
    if not args[1] == "" or args[1] ~= nil then
        -- Call the command from /bin/
        local program, reason1 = loadfile("/bin/" .. args[1] .. ".lua")
        if not program then
            -- Try loading from the current directory
            program, reason1 = loadfile(fs.concat(path, args[1]))
        end
        if program then
            local command = args[1]
            table.remove(args, 1)
            -- Change the current directory of the program to the current path
            local env = setmetatable({chdir = chdir, pwd = pwd, ls = ls, cat = cat}, {__index = _G})
            -- Run the program with the arguments
            local result, reason2 = xpcall(function()
                if program then
                    -- Change the current directory of the program to the current path
                    local env = setmetatable({chdir = chdir, pwd = pwd, ls = ls, cat = cat, formatListing = formatListing}, {__index = _G})
                    -- Run the program with the arguments
                    program(table.unpack(args, 1))
                else
                    io.stderr:write(reason1 .. "\n")
                end
            end, debug.traceback)

            if not result then
                io.stderr:write(reason2 .. "\n")
            end
        else
            io.stderr:write(reason1 .. "\n")
        end
    else
        io.write("Invalid command\n")
    end
end