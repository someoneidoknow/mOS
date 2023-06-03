args,ops = shell.parse(...)

if not args[1] then
    local listing = ls(path)
    listing = formatListing(listing)
    io.write(listing)
    return
end

local path = shell.resolve(args[1])
local listing = ls(path)
listing = formatListing(listing)
io.write(listing)
