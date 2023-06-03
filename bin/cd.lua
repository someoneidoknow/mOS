local filesystem = require("filesystem")
local args = {...}

if args[1] == "" then
    print("Usage: cd <path>")
    return
end

local function findPreviousPath(path)
    -- Remove trailing slashes if any
    path = path:gsub("/$", "")
    
    -- Split the path into individual components
    local components = {}
    for component in path:gmatch("[^/]+") do
        table.insert(components, component)
    end
    
    -- Remove the last component
    table.remove(components)
    
    -- Join the remaining components to form the previous path
    local previousPath = "/" .. table.concat(components, "/")
    
    return previousPath
end
if args[1] == ".." then
    if path == "/" then
        return
    end
    chdir(findPreviousPath(path))
    return
end
local path1 = shell.resolve(args[1])
print(path1)
if not filesystem.exists(path1) then
    if filesystem.exists(path.."/"..args[1]) and filesystem.isDirectory(path.."/"..args[1]) then
        if path == "/" then
            chdir("/"..args[1])
        else
            chdir(path.."/"..args[1])
        end
        return
    end
    print("No such file or directory")
    return
end
chdir(path1)