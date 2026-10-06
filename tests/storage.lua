local files, failure = {}, nil
io.exists = function(path) return files[path] ~= nil end
yajl = { to_string = function(value)
    if failure == "encode" then error("encode") end
    return value
end }
io.open = function(path)
    if failure == "open" then return nil, "open" end
    files[path] = ""
    return {
        write = function(_, value)
            if failure == "write" then return nil, "disk full" end
            files[path] = value
            return true
        end,
        close = function() if failure == "close" then return nil, "close" end; return true end,
    }
end
os.remove = function(path) files[path] = nil; return true end
os.rename = function(source, target)
    if (failure == "backup" and target == "data.bak")
        or ((failure == "install" or failure == "restore") and source == "data.tmp")
        or (failure == "restore" and source == "data.bak") then return nil, "rename" end
    if files[target] or not files[source] then return nil, "path" end
    files[target], files[source] = files[source], nil
    return true
end
dofile("le/storage.lua")
for _, mode in ipairs({"encode", "open", "write", "close", "backup", "install", "restore"}) do
    files, failure = {data = "old"}, mode
    assert(not le.storage.write_json("data", "new"), mode)
    assert(files.data == "old" or files["data.bak"] == "old", mode .. " lost old data")
    if mode ~= "restore" then assert(files.data == "old", mode) end
end
files, failure = {data = "old"}, nil
assert(le.storage.write_json("data", "new"))
assert(files.data == "new" and files["data.bak"] == "old")
assert(le.storage.write_json("data", "newer"))
assert(files.data == "newer" and files["data.bak"] == "new")
files = {}
assert(le.storage.write_json("data", "first"))
assert(files.data == "first")
print("OK: JSON, open/write/close failures, replacement, rollback and backup preservation")
