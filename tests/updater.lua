-- Model systemu plików i zdarzeń Mudleta: żaden plik profilu nie jest dotykany.
local real_loadfile = loadfile
local function scenario(mode)
    local plugin, staging, backup = "memory/plugins/UNICORN", "memory/UNICORN-update", "memory/UNICORN-backup"
    local fs = { memory=true, ["memory/plugins"]=true, [plugin]=true, [plugin.."/le"]=true,
        [staging]=true, [staging.."/le"]=true }
    local manifest = 'return {"version", "le.config", "le.sample"}'
    fs[plugin.."/init.lua"] = manifest
    fs[plugin.."/version.lua"] = 'le.version = "1.0.0"'
    fs[plugin.."/le/config.lua"] = 'le.config.cleanup()'
    fs[plugin.."/le/sample.lua"] = 'le.sample = "old"'
    fs[plugin.."/obsolete.lua"] = 'old extra file'
    fs[staging.."/init.lua"] = manifest
    fs[staging.."/version.lua"] = 'le.version = "1.0.1"'
    fs[staging.."/le/config.lua"] = 'le.config.cleanup()'
    fs[staging.."/le/sample.lua"] = 'le.sample = "new"'
    local staged = {}
    for path, content in pairs(fs) do
        if path:sub(1,#staging) == staging then staged[path] = content; fs[path] = nil end
    end
    if mode == "syntax" then staged[staging.."/le/sample.lua"] = 'local =' end
    if mode == "missing" then staged[staging.."/le/sample.lua"] = nil end
    if mode == "version" then staged[staging.."/version.lua"] = 'le.version = "9.0.0"' end
    if mode == "manifest" then staged[staging.."/init.lua"] = 'return {}' end
    if mode == "runtime" or mode == "rollback" then staged[staging.."/le/sample.lua"] = 'error("runtime")' end
    local handlers, timers, next_id, logs = {}, {}, 0, {}
    local function id() next_id = next_id + 1; return next_id end
    local function noop() end
    le = {version="1.0.0", ui={output=function(_, text) logs[#logs+1] = text end}}
    getMudletHomeDir = function() return "memory" end
    registerAnonymousEventHandler = function(event, fn)
        local key=id(); handlers[key]={event=event, fn=fn}; return key
    end
    killAnonymousEventHandler = function(key) handlers[key]=nil end
    tempAlias = id; killAlias = noop
    tempTimer = function(_, fn) local key=id(); timers[key]=fn; return key end
    killTimer = function(key) timers[key]=nil end
    getHTTP = noop; downloadFile = noop
    unzipAsync = function() for path, value in pairs(staged) do fs[path] = value end end
    io.open = function(path, access)
        assert(access == "rb", "updater must not overwrite individual files")
        if type(fs[path]) ~= "string" then return nil end
        return {read=function() return fs[path] end, close=noop}
    end
    loadfile = function(path)
        if type(fs[path]) ~= "string" then return nil, "missing "..path end
        return loadstring(fs[path], path)
    end
    require = function(name)
        local relative = name:gsub("^UNICORN%.", ""):gsub("%.", "/")
        local chunk, err = loadfile(plugin.."/"..relative..".lua")
        assert(chunk, err); return chunk()
    end
    os.remove = function(path) fs[path]=nil; return true end
    os.rename = function(source, target)
        if (mode == "backup" and target == backup)
            or (mode == "install" and source == staging)
            or (mode == "rollback" and source == backup) then return nil, "locked" end
        if not fs[source] or fs[target] then return nil, "path" end
        local moved = {}
        for path, value in pairs(fs) do
            if path == source or path:sub(1,#source+1) == source.."/" then
                moved[target..path:sub(#source+1)] = value
            end
        end
        for path in pairs(moved) do fs[source..path:sub(#target+1)] = nil end
        for path, value in pairs(moved) do fs[path] = value end
        return true
    end
    lfs = {
        attributes=function(path) return fs[path] == true and "directory" or (fs[path] and "file") end,
        dir=function(path)
            local names = {}
            for item in pairs(fs) do
                if item:sub(1,#path+1) == path.."/" then
                    local name = item:sub(#path+2)
                    if not name:find("/",1,true) then names[#names+1]=name end
                end
            end
            local index=0
            return function() index=index+1; return names[index] end
        end,
        rmdir=function(path) fs[path]=nil; return true end,
    }
    assert(real_loadfile("le/config.lua"))()
    local function emit(event, argument)
        local callbacks={}
        for _, handler in pairs(handlers) do if handler.event == event then callbacks[#callbacks+1]=handler.fn end end
        for _, callback in ipairs(callbacks) do callback(event, argument) end
    end
    le.config.update.remote_version = "1.0.1"
    le.config.installUpdate()
    emit("sysDownloadDone", "memory/UNICORN-update.zip")
    emit("sysUnzipDone")
    local reload = le.config.update.reload_timer
    if reload then timers[reload]() end
    if mode == "success" then
        assert(le.version == "1.0.1" and le.sample == "new")
        assert(fs[backup.."/version.lua"] == 'le.version = "1.0.0"')
        assert(fs[plugin.."/obsolete.lua"] == nil)
    elseif mode == "rollback" then
        assert(fs[backup.."/version.lua"] == 'le.version = "1.0.0"')
        assert(not fs[plugin])
        -- Kolejna próba nie może skasować jedynej kopii poprzedniej wersji.
        le.version = "1.0.0"
        le.config.update.remote_version = "1.0.1"
        le.config.installUpdate(); emit("sysDownloadDone", "memory/UNICORN-update.zip"); emit("sysUnzipDone")
        assert(fs[backup.."/version.lua"] == 'le.version = "1.0.0"')
    else
        assert(fs[plugin.."/version.lua"] == 'le.version = "1.0.0"', mode)
        assert(fs[plugin.."/le/sample.lua"] == 'le.sample = "old"', mode)
        assert(fs[plugin.."/obsolete.lua"] == 'old extra file', mode)
    end
    assert(not le.config.update.installing)
end
for _, mode in ipairs({"syntax", "missing", "version", "manifest", "backup", "install", "runtime", "rollback", "success"}) do
    scenario(mode)
end
print("OK: staging validation, directory replacement, reload failure, rollback and retained recovery copy")
