-- Uruchom: fengari tests/online.lua (z katalogu głównego repozytorium).
local real_time = os.time
local now = real_time({ year = 2026, month = 9, day = 20, hour = 23, min = 59, sec = 50 })
os.time = function(parts)
    if parts then return real_time(parts) end
    return now
end

local files, json_values, handlers, triggers, timers, aliases = {}, {}, {}, {}, {}, {}
local next_id = 0
local function id()
    next_id = next_id + 1
    return next_id
end

io.exists = function(path) return files[path] ~= nil end
io.open = function(path, mode)
    if mode == "r" then
        if files[path] == nil then return nil end
        return {
            read = function() return files[path] end,
            close = function() return true end,
        }
    end
    return {
        write = function(_, value) files[path] = value end,
        close = function() return true end,
    }
end

yajl = {
    to_string = function(value)
        local key = "json-" .. id()
        json_values[key] = value
        return key
    end,
    to_value = function(key) return json_values[key] end,
}

getMudletHomeDir = function() return "memory" end
cecho = function() end
le = { ui = { output = function() end } }

Geyser = { Label = {} }
function Geyser.Label:new(config)
    return setmetatable({
        config = config,
        visible = true,
        setStyleSheet = function(self, style) self.style = style end,
        echo = function(self, value) self.html = value end,
        hide = function(self) self.visible = false end,
        show = function(self) self.visible = true end,
        resize = function(self, width, height) self.width, self.height = width, height end,
    }, { __index = self })
end

tempAlias = function(_, callback) local key = id(); aliases[key] = callback; return key end
killAlias = function(key) aliases[key] = nil end
tempRegexTrigger = function(pattern, callback)
    local key = id()
    triggers[key] = { pattern = pattern, callback = callback }
    return key
end
killTrigger = function(key) triggers[key] = nil end
registerAnonymousEventHandler = function(event, callback)
    local key = id()
    handlers[key] = { event = event, callback = callback }
    return key
end
killAnonymousEventHandler = function(key) handlers[key] = nil end
tempTimer = function(_, callback)
    local key = id()
    timers[key] = callback
    return key
end
killTimer = function(key) timers[key] = nil end

local function emit(event)
    for _, handler in pairs(handlers) do
        if handler.event == event then handler.callback() end
    end
end

local function fire_line(fragment)
    for _, trigger in pairs(triggers) do
        if trigger.pattern:find(fragment, 1, true) then
            trigger.callback()
            return
        end
    end
    error("Brak triggera dla " .. fragment)
end

local function count_entries(values)
    local count = 0
    for _ in pairs(values) do count = count + 1 end
    return count
end

dofile("le/czas.lua")
local online = le.czas.Online
assert(not online.active, "sam start Mudleta nie może naliczać czasu")
now = now + 5
online.tick()
assert(online.total() == 0)

gmcp = { room = { info = { map = { domain = "Ishtar" } } } }
emit("gmcp.room.info")
assert(online.active)
now = now + 10
online.tick()
assert(online.weeks["2026-09-14"] == 5)
assert(online.weeks["2026-09-21"] == 5)
online.weeks["2026-09-14"] = 5 * 3600
le.czas.data.domain = "ishtar"
le.czas.data.anchors.ishtar = { game_sec = 0, real_ts = now }
le.czas.UI.update()
assert(le.czas.UI.clock.html:find("width:0%%", 1, false), "nowy tydzień nie wyzerował paska")
now = now + 15
online.tick()
assert(online.total() == 20)

fire_line("Opuszczasz realny swiat")
assert(not online.active)
now = now + 100
online.tick()
assert(online.total() == 20, "czas po wylogowaniu nie może się naliczać")

emit("gmcp.room.info")
now = now + 3600
online.tick()
assert(online.total() == 110, "uśpienie nie może naliczyć całej przerwy")

local before = count_entries(handlers)
dofile("le/czas.lua")
assert(count_entries(handlers) == before, "przeładowanie dodało zdublowane handlery")
assert(le.czas.Online.active, "gorące przeładowanie przerwało aktywną sesję")
now = now + 5
online.tick()
assert(online.total() == 115)

online.weeks["2026-09-21"] = 5 * 3600
le.czas.UI.update()
assert(le.czas.UI.clock.html:find("width:100%%", 1, false))
assert(le.czas.UI.clock.html:find("#20242A", 1, true), "pełny pasek nie używa subtelnego koloru")

-- Zasymuluj zatrzymany timer. Świeży event GMCP ma go odtworzyć.
local dead_timer = le.czas.timer
killTimer(dead_timer)
le.czas.timer_last_tick = now - 10
emit("gmcp.room.info")
assert(le.czas.timer ~= dead_timer and timers[le.czas.timer], "GMCP nie odtworzył zatrzymanego timera")

emit("sysDisconnectionEvent")
assert(not online.active)
now = now + 5
online.tick()
assert(online.total() == 5 * 3600)

emit("gmcp.room.info")
fire_line("Zbyt dluga nieaktywnosc")
assert(not online.active, "bezczynność nie zatrzymała sesji")

emit("gmcp.room.info")
emit("sysConnectionEvent")
assert(not online.active, "nowe połączenie nie zatrzymało starej sesji")
emit("gmcp.room.info")
emit("sysExitEvent")
assert(not online.active, "zamknięcie klienta nie zatrzymało sesji")

local saved = files[online.path]
assert(saved, "brak zapisu tygodniowego czasu")
online.loaded = false
online.weeks = {}
online.load()
assert(online.total() == 5 * 3600, "zapis nie odtworzył wyniku")

dofile("le/czas.lua")
assert(not online.active, "stary pakiet GMCP nie może rozpocząć nowej sesji")
files[online.path] = "uszkodzony-json"
online.loaded = false
online.weeks = {}
online.load()
assert(online.read_only, "uszkodzony zapis powinien przełączyć licznik w tryb tylko do odczytu")
online.dirty = true
assert(not online.save())
assert(files[online.path] == "uszkodzony-json", "uszkodzony plik został nadpisany")
print("OK: tygodnie, logout, idle, disconnect, exit, zapis, pasek HTML, watchdog i przeładowanie")
