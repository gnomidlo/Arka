-- le.czas: niezależny zegar, kalendarz i panel wydarzeń dla Mudleta.

le = le or {}
le.czas = le.czas or {}
le.czas.UI = le.czas.UI or {}

le.czas.config = {
    clock = { name = "LeCzasClockLabel", x = "-280px", y = "-790px", width = "260px", height = "158px" },
    event = { name = "LeCzasEventLabel", x = "-280px", y = "-628px", width = "260px", height = "64px" },
    clock_style = [[
        background-color: rgba(12, 14, 18, 220);
        border: none;
        border-left: 3px solid #79C9D3;
        border-radius: 0px;
        padding: 8px 10px;
        font-family: 'DejaVu Sans Mono', 'Consolas', monospace;
    ]],
    event_style = [[
        background-color: rgba(12, 14, 18, 220);
        border: none;
        border-left: 3px solid #B6A2E1;
        border-radius: 0px;
        padding: 6px 10px;
        font-family: 'DejaVu Sans Mono', 'Consolas', monospace;
    ]],
    minimum_event_gap = 600,
    maximum_samples = 10,
    outlier_minutes = 180,
    sun_colors = { sunrise = "#B7A56E", sunset = "#8793A6" },
    sky_icon_colors = { sun = "#B7A56E", moon = "#8793A6", unknown = "#777C86" },
    domain_colors = { imperium = "#AA9668", ishtar = "#79A8AD" },
    log_bracket_color = "sky_blue",
    log_colors = { detected = "steel_blue", saved = "powder_blue", skipped = "slate_gray", rejected = "light_pink", info = "pale_green" },
}

-- Wbudowane dane kalendarzy gry; moduł nie korzysta z zewnętrznego źródła w czasie działania.
le.czas.cal = {
    imperium = {
        totalDays = 400,
        seasonMap = {
            { name = "Hexentag",     startDay = 1 },
            { name = "Nachhexen",    startDay = 2 },
            { name = "Jahrdrung",    startDay = 34 },
            { name = "Mitterfruhl",  startDay = 67 },
            { name = "Pflugzeit",    startDay = 68 },
            { name = "Sigmarszeit",  startDay = 101 },
            { name = "Sommerzeit",   startDay = 134 },
            { name = "Sonnenstill",  startDay = 167 },
            { name = "Vorgeheim",    startDay = 168 },
            { name = "Geheimnistag", startDay = 201 },
            { name = "Nachgeheim",   startDay = 202 },
            { name = "Erntezeit",    startDay = 234 },
            { name = "Mitterherbst", startDay = 267 },
            { name = "Brauzeit",     startDay = 268 },
            { name = "Kaltezeit",    startDay = 301 },
            { name = "Ulrichszeit",  startDay = 334 },
            { name = "Mondstill",    startDay = 367 },
            { name = "Vorhexen",     startDay = 368 },
        },
        events = {
            { day = 1,   hour = 17, desc = "Hexensnacht",              color = "tomato" },
            { day = 2,   hour = 0,  desc = "Rytual wiedzm",            color = "tomato" },
            { day = 14,  hour = 17, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 18,  hour = 0,  desc = "Poczatek wiosny",          color = "PaleGreen" },
            { day = 39,  hour = 18, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 64,  hour = 18, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 89,  hour = 19, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 114, hour = 20, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 118, hour = 0,  desc = "Poczatek lata",            color = "LawnGreen" },
            { day = 139, hour = 21, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 164, hour = 21, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 189, hour = 22, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 214, hour = 20, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 218, hour = 0,  desc = "Poczatek jesieni",         color = "gold" },
            { day = 239, hour = 20, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 264, hour = 20, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 289, hour = 19, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 314, hour = 18, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 319, hour = 0,  desc = "Poczatek zimy",            color = "SkyBlue" },
            { day = 339, hour = 17, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 364, hour = 17, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 389, hour = 16, desc = "Poczatek nowiu",           color = "light_slate_blue" },
            { day = 200, hour = 22, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 201, hour = 21, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 202, hour = 21, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 225, hour = 21, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 226, hour = 21, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 227, hour = 21, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 250, hour = 20, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 251, hour = 20, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 252, hour = 20, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 275, hour = 19, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 276, hour = 19, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 277, hour = 19, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 300, hour = 18, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 301, hour = 18, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
            { day = 302, hour = 18, desc = "Szansa na Geheimnisnacht", color = "sky_blue" },
        },
    },
    ishtar = {
        totalDays = 360,
        seasonMap = {
            { name = "Saovine", startDay = 1 },
            { name = "Yule",    startDay = 46 },
            { name = "Imbaelk", startDay = 91 },
            { name = "Birke",   startDay = 136 },
            { name = "Blathe",  startDay = 181 },
            { name = "Feainn",  startDay = 226 },
            { name = "Lammas",  startDay = 271 },
            { name = "Velen",   startDay = 316 },
        },
        events = {
            { day = 1,   hour = 0,  desc = "Saovine (pozna jesien)", color = "gold" },
            { day = 1,   hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 1,   hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 1,   hour = 7,  desc = "Koniec Saovine",         color = "tomato" },
            { day = 25,  hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 25,  hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 46,  hour = 0,  desc = "Yule (wczesna zima)",    color = "SkyBlue" },
            { day = 49,  hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 49,  hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 73,  hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 73,  hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 91,  hour = 0,  desc = "Imbaelk (pozna zima)",   color = "SkyBlue" },
            { day = 97,  hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 97,  hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 121, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 121, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 136, hour = 0,  desc = "Birke (wczesna wiosna)", color = "PaleGreen" },
            { day = 145, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 145, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 169, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 169, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 180, hour = 20, desc = "Poczatek Belleteyn",     color = "tomato" },
            { day = 181, hour = 0,  desc = "Blathe (pozna wiosna)",  color = "PaleGreen" },
            { day = 181, hour = 20, desc = "Koniec Belleteyn",       color = "tomato" },
            { day = 193, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 193, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 217, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 217, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 226, hour = 0,  desc = "Feainn (wczesne lato)",  color = "LawnGreen" },
            { day = 241, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 241, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 265, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 265, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 271, hour = 0,  desc = "Lammas (pozne lato)",    color = "LawnGreen" },
            { day = 289, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 289, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 313, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 313, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 316, hour = 0,  desc = "Velen (wczesna jesien)", color = "gold" },
            { day = 337, hour = 0,  desc = "Poczatek pelni",         color = "LightCyan" },
            { day = 337, hour = 2,  desc = "Spiskowcy wychodza",     color = "violet" },
            { day = 360, hour = 18, desc = "Poczatek Saovine",       color = "tomato" },
        },
        sunrise = { Saovine = 6, Yule = 8, Imbaelk = 7, Birke = 6, Blathe = 5, Feainn = 4, Lammas = 5, Velen = 7 },
        sunset  = { Saovine = 17, Yule = 16, Imbaelk = 18, Birke = 19, Blathe = 21, Feainn = 20, Lammas = 20, Velen = 18 },
    },
}

local function epoch() return os.time() end

function le.czas.log(level, text)
    if le.ui and le.ui.output then
        le.ui.output("czas", text)
        return
    end
    cecho(string.format("\n<sky_blue>▎<reset>  %s\n", tostring(text or "")))
end

local function duration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%02dh %02dm %02ds", h, m, s) end
    return string.format("%02dm %02ds", m, s)
end

local function season_duration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if d > 0 then return string.format("%dd %02dh %02dm", d, h, m) end
    if h > 0 then return string.format("%02dh %02dm", h, m) end
    return string.format("%02dm", m)
end

local function game_clock(minutes)
    minutes = math.floor((tonumber(minutes) or 0) + 0.5) % 1440
    return string.format("%02d:%02d", math.floor(minutes / 60), minutes % 60)
end

-- Time math: 1 game hour = 120 seconds of this "game_sec" counter, which
-- advances 1:1 with real elapsed seconds.
local function sec_to_date(sec, domain)
    local totalDays = le.czas.cal[domain].totalDays
    local yearSec = totalDays * 24 * 120
    sec = sec % yearSec
    if sec < 0 then sec = sec + yearSec end
    local day = math.floor(sec / (24 * 120)) + 1
    local hour = math.floor((sec % (24 * 120)) / 120)
    local minute = math.floor((sec % 120) / 2)
    return day, hour, minute
end

-- Persistent storage --------------------------------------------------------

le.czas.path = getMudletHomeDir() .. "/le_czas_data.json"
le.czas.data = le.czas.data or {
    domain = nil,
    anchors = {},         -- [domain] = { game_sec, real_ts }
    sun = { imperium = {}, ishtar = {} },
    daylight = {},         -- [domain] = true/false, last observed
}

function le.czas.load()
    if not io.exists(le.czas.path) then return end
    local file = io.open(le.czas.path, "r")
    if not file then return end
    local content = file:read("*a")
    file:close()
    local ok, decoded = pcall(yajl.to_value, content)
    if ok and type(decoded) == "table" then
        le.czas.data = decoded
        le.czas.data.anchors = le.czas.data.anchors or {}
        le.czas.data.sun = le.czas.data.sun or { imperium = {}, ishtar = {} }
        le.czas.data.sun.imperium = le.czas.data.sun.imperium or {}
        le.czas.data.sun.ishtar = le.czas.data.sun.ishtar or {}
        le.czas.data.daylight = le.czas.data.daylight or {}
    end
end

function le.czas.save()
    local file = io.open(le.czas.path, "w")
    if not file then return false end
    local ok, encoded = pcall(yajl.to_string, le.czas.data)
    if not ok then file:close(); return false end
    file:write(encoded)
    file:close()
    return true
end

-- Seed Ishtar's sun table from the known-exact static hours (no observation
-- needed there); Imperium starts empty and learns purely from observation.
function le.czas.seed_ishtar_sun()
    local cal = le.czas.cal.ishtar
    local sun = le.czas.data.sun.ishtar
    for _, item in ipairs(cal.seasonMap) do
        local sr, ss = cal.sunrise[item.name], cal.sunset[item.name]
        if sr and ss and not sun[item.name] then
            sun[item.name] = {
                sunrise = { { minute = sr * 60 } },
                sunset = { { minute = ss * 60 } },
            }
        end
    end
end

-- Time response parsing -------------------------------------------------

local ORDINAL_UNITS = {
    pierwszy = 1, drugi = 2, trzeci = 3, czwarty = 4, piaty = 5,
    szosty = 6, siodmy = 7, osmy = 8, dziewiaty = 9,
    dziesiaty = 10, jedenasty = 11, dwunasty = 12, trzynasty = 13,
    czternasty = 14, pietnasty = 15, szesnasty = 16, siedemnasty = 17,
    osiemnasty = 18, dziewietnasty = 19,
}

local ORDINAL_TENS = {
    dwudziesty = 20,
    trzydziesty = 30,
    czterdziesty = 40,
}

local CLOCK_HOURS = {
    pierwsza = 1, druga = 2, trzecia = 3, czwarta = 4,
    piata = 5, szosta = 6, siodma = 7, osma = 8,
    dziewiata = 9, dziesiata = 10, jedenasta = 11, dwunasta = 12,
}

local function normalize_game_text(value)
    value = tostring(value or ""):lower()
    local replacements = {
        ["ą"] = "a", ["ć"] = "c", ["ę"] = "e", ["ł"] = "l",
        ["ń"] = "n", ["ó"] = "o", ["ś"] = "s", ["ź"] = "z", ["ż"] = "z",
    }
    return (value:gsub("[ąćęłńóśźż]", replacements))
end

local function parse_ordinal_day(text)
    local numeric = text:match("(%d+)%.?%s+dzien%s+pory")
        or text:match("(%d+)%.?%s+dzien%s+miesiaca")
    if numeric then return tonumber(numeric) end

    local first, second = text:match("([%a]+)%s*([%a]*)%s+dzien%s+pory")
    if not first then
        first, second = text:match("([%a]+)%s*([%a]*)%s+dzien%s+miesiaca")
    end
    if not first then return nil end

    if ORDINAL_TENS[first] then
        return ORDINAL_TENS[first] + (ORDINAL_UNITS[second] or 0)
    end
    return ORDINAL_UNITS[first]
end

local function parse_game_clock(text)
    local hour, minute = text:match("^jest%s+.-(%d+):(%d+)")
    if hour then
        hour, minute = tonumber(hour), tonumber(minute)
        if hour and minute and hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 then
            return hour, minute
        end
        return nil
    end

    local phrase = text:match("^jest%s+dokladnie%s+([^,]+)")
        or text:match("^jest%s+w%s+przyblizeniu%s+([^,]+)")
    if not phrase then return nil end
    if phrase:find("polnoc", 1, true) then return 0, 0 end
    if phrase:find("poludnie", 1, true) then return 12, 0 end

    local word = phrase:match("^(%a+)")
    hour = CLOCK_HOURS[word]
    if not hour then return nil end
    if (phrase:find("po poludniu", 1, true) or phrase:find("wieczorem", 1, true)) and hour < 12 then
        hour = hour + 12
    end
    return hour, 0
end

local function find_calendar_period(period_name)
    local wanted = normalize_game_text(period_name)
    for _, domain in ipairs({ "imperium", "ishtar" }) do
        local periods = le.czas.cal[domain].seasonMap
        for index, item in ipairs(periods) do
            if normalize_game_text(item.name) == wanted then
                local next_item = periods[index + 1]
                local length = next_item and (next_item.startDay - item.startDay)
                    or (le.czas.cal[domain].totalDays - item.startDay + 1)
                return domain, item.startDay, length
            end
        end
    end
    return nil
end

function le.czas.parse_time_text(raw_text)
    local text = normalize_game_text(raw_text)
    local period_name = text:match("dzien%s+pory%s+([%a]+)")
    local expected_domain = "ishtar"

    if not period_name then
        period_name = text:match("dzien%s+miesiaca%s+([%a]+)")
        expected_domain = "imperium"
    end

    local period_day = parse_ordinal_day(text)
    local hour, minute = parse_game_clock(text)
    if not period_name or not period_day or hour == nil then return nil end

    local domain, start_day, period_length = find_calendar_period(period_name)
    if domain ~= expected_domain or period_day < 1 or period_day > period_length then return nil end
    return domain, start_day + period_day - 1, hour, minute
end

function le.czas.on_time_text(raw_text)
    local domain, day, hour, minute = le.czas.parse_time_text(raw_text)
    if not domain then
        le.czas.log("rejected", "Nie udalo sie odczytac czasu z odpowiedzi gry.")
        return false
    end

    le.czas.data.domain = domain
    le.czas.sync(domain, day, hour, minute, true)
    le.czas.log("saved", string.format(
        "Automatyczna synchronizacja %s: dzien %d, %02d:%02d.", domain, day, hour, minute))
    return true
end

-- Domain -----------------------------------------------------------------

local function detect_domain_from_gmcp()
    if not gmcp or not gmcp.room or not gmcp.room.info or not gmcp.room.info.map then return nil end
    local raw = gmcp.room.info.map.domain
    if raw == "Imperium" then return "imperium" end
    if raw == "Ishtar" then return "ishtar" end
    return nil
end

function le.czas.on_room()
    local ok, err = pcall(function()
        local detected = detect_domain_from_gmcp()
        if detected and detected ~= le.czas.data.domain then
            le.czas.data.domain = detected
            le.czas.save()
            le.czas.log("info", "Wykryto domene: " .. detected)
        end
        le.czas.on_room_time()
    end)
    if not ok then le.czas.log("skipped", "Blad on_room: " .. tostring(err)) end
end

-- Sync -----------------------------------------------------------------

function le.czas.sync(domain, day, hour, minute, quiet)
    if domain ~= "imperium" and domain ~= "ishtar" then
        le.czas.log("rejected", "Nieznana domena: " .. tostring(domain))
        return
    end
    local total = le.czas.cal[domain].totalDays
    day = math.max(1, math.min(total, tonumber(day) or 1))
    hour = math.max(0, math.min(23, tonumber(hour) or 0))
    minute = math.max(0, math.min(59, tonumber(minute) or 0))
    local game_sec = (day - 1) * 2880 + hour * 120 + minute * 2
    le.czas.data.anchors[domain] = { game_sec = game_sec, real_ts = epoch() }
    le.czas.save()
    if not quiet then
        le.czas.log("saved", string.format("Zsynchronizowano %s: dzien %d, %02d:%02d.", domain, day, hour, minute))
    end
end

function le.czas.get_game_sec(domain)
    local anchor = le.czas.data.anchors[domain]
    if not anchor then return nil end
    return anchor.game_sec + (epoch() - anchor.real_ts)
end

-- Season / period helpers -------------------------------------------------

local SEASON_BY_PERIOD = {
    yule = "Zima", imbaelk = "Wiosna", birke = "Wiosna", blathe = "Wiosna",
    feainn = "Lato", lammas = "Lato", velen = "Jesien", saovine = "Jesien",
    nachhexen = "Wiosna", jahrdrung = "Wiosna", pflugzeit = "Wiosna",
    sigmarszeit = "Lato", sommerzeit = "Lato", vorgeheim = "Lato",
    nachgeheim = "Jesien", erntezeit = "Jesien", brauzeit = "Jesien",
    kaltezeit = "Zima", ulrichszeit = "Zima", vorhexen = "Zima",
}

local SEASON_STYLE = {
    Wiosna = { icon = "&#10047;", color = "#8fcf9b" },
    Lato = { icon = "&#9728;", color = "#e6c55a" },
    Jesien = { icon = "&#10086;", color = "#d7925b" },
    Zima = { icon = "&#10052;", color = "#8fb9cf" },
}

local function normalize_period(name)
    return tostring(name or ""):lower():gsub("[^%w]", "")
end

local function season_for_period(name)
    return SEASON_BY_PERIOD[normalize_period(name)]
end

local function calendar_period_name(domain, day)
    local cal = le.czas.cal[domain]
    local total = cal.totalDays
    local dNorm = ((day - 1) % total) + 1
    for i = #cal.seasonMap, 1, -1 do
        local item = cal.seasonMap[i]
        if dNorm >= item.startDay and season_for_period(item.name) then return item.name end
    end
    for i = #cal.seasonMap, 1, -1 do
        if season_for_period(cal.seasonMap[i].name) then return cal.seasonMap[i].name end
    end
    return nil
end

local function period_info(domain, day)
    local cal = le.czas.cal[domain]
    local current = cal.seasonMap[#cal.seasonMap]
    for _, item in ipairs(cal.seasonMap) do
        if day >= item.startDay then current = item else break end
    end
    local value = day - current.startDay + 1
    if value < 1 then value = cal.totalDays - current.startDay + day + 1 end
    return value, current.name
end

local function season_info(domain, day, game_sec)
    local cal = le.czas.cal[domain]
    local periods = cal.seasonMap
    local yearSec = cal.totalDays * 24 * 120
    local current_index = #periods
    for index, item in ipairs(periods) do
        if day >= item.startDay then current_index = index else break end
    end
    local current = season_for_period(periods[current_index].name)
    if not current then return nil end
    local now_value = game_sec % yearSec
    for step = 1, #periods do
        local index = (current_index + step - 1) % #periods + 1
        local candidate = periods[index]
        local next_season = season_for_period(candidate.name)
        if next_season and next_season ~= current then
            local target = (candidate.startDay - 1) * 24 * 120
            local offset = target - now_value
            if offset <= 0 then offset = offset + yearSec end
            return { name = current, next_name = next_season, offset = offset }
        end
    end
    return { name = current }
end

-- Sun observation ---------------------------------------------------------

local function median(samples)
    if not samples or #samples == 0 then return nil end
    local values = {}
    for _, s in ipairs(samples) do values[#values + 1] = s.minute end
    table.sort(values)
    local mid = math.floor((#values + 1) / 2)
    if #values % 2 == 1 then return values[mid] end
    return math.floor((values[mid] + values[mid + 1]) / 2 + 0.5)
end

local function circular_difference(a, b)
    local d = math.abs(a - b)
    return math.min(d, 1440 - d)
end

local function plausible_sun_minute(kind, minute)
    minute = tonumber(minute)
    if not minute or minute < 0 or minute >= 1440 then return false end
    if kind == "sunrise" then return minute < 720 end
    return minute >= 720
end

function le.czas.store_sun(domain, period, kind, minute)
    if not period or not plausible_sun_minute(kind, minute) then return end
    local kind_label = kind == "sunrise" and "swit" or "zmierzch"
    local dom = le.czas.data.sun[domain]
    dom[period] = dom[period] or { sunrise = {}, sunset = {} }
    local samples = dom[period][kind]
    local center = median(samples)
    if center and #samples >= 3 and circular_difference(center, minute) > le.czas.config.outlier_minutes then
        le.czas.log("rejected", string.format("Odrzucono %s w %s: %s vs mediana %s.",
            kind_label, period, game_clock(minute), game_clock(center)))
        return
    end
    samples[#samples + 1] = { minute = minute }
    while #samples > le.czas.config.maximum_samples do table.remove(samples, 1) end
    le.czas.save()
    le.czas.log("saved", string.format("Zapisano %s: %s, okres %s, %s.", kind_label, domain, period, game_clock(minute)))
end

le.czas.last_event_at = le.czas.last_event_at or {}

function le.czas.on_room_time()
    local domain = le.czas.data.domain
    if domain ~= "imperium" and domain ~= "ishtar" then return end
    if not gmcp or not gmcp.room or not gmcp.room.time or gmcp.room.time.daylight == nil then return end
    local daylight = gmcp.room.time.daylight
    local previous = le.czas.data.daylight[domain]
    le.czas.data.daylight[domain] = daylight
    if previous == nil or previous == daylight then return end

    local kind = daylight and "sunrise" or "sunset"
    local kind_label = kind == "sunrise" and "swit" or "zmierzch"
    local last = le.czas.last_event_at[domain .. kind] or 0
    if epoch() - last < le.czas.config.minimum_event_gap then return end
    le.czas.last_event_at[domain .. kind] = epoch()

    local game_sec = le.czas.get_game_sec(domain)
    if not game_sec then
        le.czas.log("skipped", string.format(
            "Wykryto %s, ale brak synchronizacji. Wpisz w grze: czas", kind_label))
        return
    end
    local day, hour, minute = sec_to_date(game_sec, domain)
    local period = calendar_period_name(domain, day)
    le.czas.store_sun(domain, period, kind, hour * 60 + minute)
end

function le.czas.next_sun(domain, day, game_sec)
    local dom = le.czas.data.sun[domain]
    local total = le.czas.cal[domain].totalDays
    local yearSec = total * 24 * 120
    local now_value = game_sec % yearSec
    local best = {}
    for _, kind in ipairs({ "sunrise", "sunset" }) do
        for offset_days = 0, 1 do
            local d = day + offset_days
            local period = calendar_period_name(domain, d)
            local record = period and dom[period]
            local minute = record and median(record[kind])
            if minute and plausible_sun_minute(kind, minute) then
                local dNorm = ((d - 1) % total)
                local target = dNorm * 24 * 120 + minute * 2
                local off = target - now_value
                if off <= 0 then off = off + yearSec end
                if not best[kind] or off < best[kind].offset then
                    best[kind] = { kind = kind, minute = minute, offset = off }
                end
            end
        end
    end
    if not best.sunrise then return best.sunset end
    if not best.sunset then return best.sunrise end
    return best.sunrise.offset <= best.sunset.offset and best.sunrise or best.sunset
end

-- Events --------------------------------------------------------------

function le.czas.get_upcoming_events(domain, count)
    local cal = le.czas.cal[domain]
    local yearSec = cal.totalDays * 24 * 120
    local game_sec = le.czas.get_game_sec(domain)
    if not game_sec then return {} end
    local now_value = game_sec % yearSec
    local list = {}
    for _, event in ipairs(cal.events) do
        local target = (event.day - 1) * 2880 + event.hour * 120
        local off = target - now_value
        if off <= 0 then off = off + yearSec end
        list[#list + 1] = { desc = event.desc, color = event.color, domain = domain, offset = off }
    end
    table.sort(list, function(a, b) return a.offset < b.offset end)
    local result = {}
    for i = 1, math.min(count or 10, #list) do result[i] = list[i] end
    return result
end

function le.czas.next_event(domain, game_sec)
    return le.czas.get_upcoming_events(domain, 1)[1]
end

function le.czas.get_upcoming_events_both(count)
    local list = {}
    for _, domain in ipairs({ "imperium", "ishtar" }) do
        for _, e in ipairs(le.czas.get_upcoming_events(domain, count)) do
            list[#list + 1] = e
        end
    end
    table.sort(list, function(a, b) return a.offset < b.offset end)
    local result = {}
    for i = 1, math.min(count or 20, #list) do result[i] = list[i] end
    return result
end

-- UI -------------------------------------------------------------------

local function message(label, title, description)
    label:echo(string.format([[<div style='font-family:DejaVu Sans Mono,Consolas,monospace'>
        <div style='font-size:11px;color:#D98282;font-weight:bold'>%s</div>
        <div style='font-size:10px;color:#8B909A;margin-top:5px'>%s</div>
    </div>]], title, description))
end

local function season_html(season)
    if not season then
        return [[<div style='font-size:10px;color:#777;margin-bottom:6px'>Pora roku: brak danych</div>]]
    end
    local style = SEASON_STYLE[season.name] or { icon = "", color = "#bbb" }
    if season.next_name and season.offset then
        return string.format([[<div style='font-size:10px;margin-bottom:6px'><span style='color:%s;font-weight:bold'>%s %s</span> <span style='color:#666'>|</span> <span style='color:#bbb'>%s za %s</span></div>]],
            style.color, style.icon, season.name, season.next_name, season_duration(season.offset))
    end
    return string.format([[<div style='font-size:10px;color:%s;font-weight:bold;margin-bottom:6px'>%s %s</div>]], style.color, style.icon, season.name)
end

local function pastel_event_color(event)
    local value = tostring(event and event.desc or ""):lower()
    if value:find("pelni", 1, true) or value:find("nowiu", 1, true) then return "#988FB5" end
    if value:find("spiskowcy", 1, true) then return "#A37F96" end
    if value:find("wiosn", 1, true) then return "#83A38B" end
    if value:find("lat", 1, true) then return "#AD9C69" end
    if value:find("jesieni", 1, true) or value:find("saovine", 1, true) then return "#A77F68" end
    if value:find("zim", 1, true) or value:find("yule", 1, true) then return "#7D96A5" end
    if value:find("geheim", 1, true) or value:find("rytual", 1, true) then return "#AE747A" end
    return "#9F9880"
end

local WEEKDAY_SHORT = { "n", "pn", "wt", "sr", "czw", "pt", "sob" }
local WEEKDAY_FULL = {
    "NIEDZIELA", "PONIEDZIALEK", "WTOREK", "SRODA",
    "CZWARTEK", "PIATEK", "SOBOTA",
}
local MONTH_NAMES = {
    "stycznia", "lutego", "marca", "kwietnia", "maja", "czerwca",
    "lipca", "sierpnia", "wrzesnia", "pazdziernika", "listopada", "grudnia",
}

local function fit_text(value, width)
    value = tostring(value or "")
    if #value > width then return value:sub(1, width - 1) .. "~" end
    return value .. string.rep(" ", width - #value)
end

local function calendar_countdown(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if days > 0 then return string.format("ZA %02dd %02dh", days, hours) end
    return string.format("ZA %02dh %02dm", hours, minutes)
end

local function real_date(timestamp)
    local value = os.date("*t", timestamp)
    return string.format("%-3s %02d %-11s",
        WEEKDAY_SHORT[value.wday], value.day, MONTH_NAMES[value.month])
end

local function domain_display(event)
    if event.domain == "ishtar" then
        return "ISHTAR", le.czas.config.domain_colors.ishtar
    end
    return "IMPERIUM", le.czas.config.domain_colors.imperium
end

local function decho_rgb(hex_color)
    local red, green, blue = tostring(hex_color):match("^#(%x%x)(%x%x)(%x%x)$")
    if not red then return "255,255,255" end
    return string.format("%d,%d,%d",
        tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16))
end

local function echo_calendar_event(event)
    local timestamp = epoch() + event.offset
    local domain, domain_color = domain_display(event)
    if le.ui and le.ui.prefix then le.ui.prefix("kal") end
    decho(string.format(
        "<174,157,105>%s<r> <82,86,96>|<r> <%s>%s<r> <82,86,96>|<r> <%s>%s<r> <82,86,96>|<r> <145,149,158>%s<r> <82,86,96>|<r> <180,183,190>%s<r>\n",
        fit_text(calendar_countdown(event.offset), 10),
        decho_rgb(domain_color), fit_text(domain, 8),
        decho_rgb(pastel_event_color(event)), fit_text(event.desc, 28),
        fit_text(real_date(timestamp), 18),
        os.date("%H:%M", timestamp)))
end

function le.czas.show_calendar(count)
    count = math.max(1, math.min(100, tonumber(count) or 20))
    local events = le.czas.get_upcoming_events_both(count)

    if le.ui and le.ui.output then le.ui.output("kal", "Najbliższe wydarzenia") else cecho("\nNajbliższe wydarzenia\n") end
    if #events == 0 then
        cecho("<slate_gray>Brak nadchodzacych wydarzen.<reset>\n")
    else
        for _, event in ipairs(events) do echo_calendar_event(event) end
    end

    if le.ui and le.ui.command then
        le.ui.command("kal", "/le.kal tydzien", "/le.kal tydzien", "pokaż agendę na 7 dni", false)
    end
end

function le.czas.show_week_agenda()
    local now = os.date("*t")
    local start_time = os.time({
        year = now.year, month = now.month, day = now.day,
        hour = 0, min = 0, sec = 0,
    })
    local end_time = os.time({
        year = now.year, month = now.month, day = now.day + 7,
        hour = 0, min = 0, sec = 0,
    })
    local groups = {}
    for index = 0, 6 do
        local timestamp = os.time({
            year = now.year, month = now.month, day = now.day + index,
            hour = 12, min = 0, sec = 0,
        })
        local key = os.date("%Y-%m-%d", timestamp)
        groups[key] = { timestamp = timestamp, events = {} }
    end

    for _, event in ipairs(le.czas.get_upcoming_events_both(100)) do
        local timestamp = epoch() + event.offset
        if timestamp >= start_time and timestamp < end_time then
            local key = os.date("%Y-%m-%d", timestamp)
            if groups[key] then
                groups[key].events[#groups[key].events + 1] = event
            end
        end
    end

    if le.ui and le.ui.output then le.ui.output("kal", "Agenda · najbliższe 7 dni") else cecho("\nAgenda · najbliższe 7 dni\n") end
    for index = 0, 6 do
        local timestamp = os.time({
            year = now.year, month = now.month, day = now.day + index,
            hour = 12, min = 0, sec = 0,
        })
        local value = os.date("*t", timestamp)
        local key = os.date("%Y-%m-%d", timestamp)
        local group = groups[key]

        if le.ui and le.ui.output then
            le.ui.output("kal", string.format("%s · %02d %s",
                WEEKDAY_FULL[value.wday], value.day, MONTH_NAMES[value.month]:upper()))
        end
        if #group.events == 0 then
            cecho("<slate_gray>Brak wydarzen<reset>\n")
        else
            for _, event in ipairs(group.events) do
                local event_time = epoch() + event.offset
                local domain, domain_color = domain_display(event)
                if le.ui and le.ui.prefix then le.ui.prefix("kal") end
                decho(string.format(
                    "<180,183,190>%s<r> <82,86,96>|<r> <%s>%s<r> <82,86,96>|<r> <%s>%s<r> <82,86,96>|<r> <174,157,105>%s<r>\n",
                    os.date("%H:%M", event_time),
                    decho_rgb(domain_color), fit_text(domain, 8),
                    decho_rgb(pastel_event_color(event)), fit_text(event.desc, 28),
                    calendar_countdown(event.offset)))
            end
        end
    end

    if le.ui and le.ui.command then
        le.ui.command("kal", "/le.kal", "/le.kal", "powrót do najbliższych wydarzeń", false)
    end
end

function le.czas.UI.update()
    local domain = le.czas.data.domain
    if domain ~= "imperium" and domain ~= "ishtar" then
        message(le.czas.UI.clock, "BRAK DOMENY", "Wejdź na zmapowaną lokację")
        message(le.czas.UI.event, "NAJBLIŻSZE WYDARZENIE", "Brak danych")
        return
    end

    local game_sec = le.czas.get_game_sec(domain)
    if not game_sec then
        message(le.czas.UI.clock, "BRAK SYNCHRONIZACJI", "Wpisz w grze: czas")
        message(le.czas.UI.event, "NAJBLIŻSZE WYDARZENIE", "Oczekiwanie na synchronizację")
        return
    end

    local day, hour, minute = sec_to_date(game_sec, domain)
    local _, period = period_info(domain, day)
    local season = season_info(domain, day, game_sec)
    local domain_name = domain == "ishtar" and "ISHTAR" or "IMPERIUM"
    local season_name = season and string.upper(season.name) or "BRAK PORY ROKU"

    local sun = le.czas.next_sun(domain, day, game_sec)
    local sun_line
    if sun then
        local name = sun.kind == "sunrise" and "Świt" or "Zmierzch"
        sun_line = string.format(
            [[<span style='color:#D8DBE2'>%s %s</span> <span style='color:#666B75'>·</span> <span style='color:#79C9D3;font-weight:bold'>za %s</span>]],
            name, game_clock(sun.minute), season_duration(sun.offset))
    else
        sun_line = [[<span style='color:#8B909A'>Świt i zmierzch · brak danych</span>]]
    end

    le.czas.UI.clock:echo(string.format([[
      <div style='font-family:DejaVu Sans Mono,Consolas,monospace'>
        <div style="font-family:'Trebuchet MS','Segoe UI',sans-serif;font-size:40px;line-height:1;color:#F1F2F4;font-weight:900;letter-spacing:1px">%02d:%02d</div>
        <div style='font-size:11px;color:#D8DBE2;margin-top:8px'>%s</div>
        <div style='font-size:11px;color:#D8DBE2;margin-top:3px'><span style='font-weight:bold'>%s</span> <span style='color:#666B75'>·</span> %s</div>
        <div style='font-size:10px;margin-top:8px'>%s</div>
      </div>]],
        hour, minute, domain_name, season_name, period, sun_line))

    local event = le.czas.next_event(domain, game_sec)
    if event then
        le.czas.UI.event:echo(string.format([[
          <div style='font-family:DejaVu Sans Mono,Consolas,monospace'>
            <div style='font-size:9px;color:#8B909A;letter-spacing:1px'>NAJBLIŻSZE WYDARZENIE</div>
            <div style='font-size:12px;color:#D8DBE2;font-weight:bold;margin-top:4px'>%s</div>
            <div style='font-size:10px;color:#8B909A;margin-top:3px'>za <span style='color:#B6A2E1;font-weight:bold'>%s</span> <span style='color:#666B75'>·</span> %s</div>
          </div>]],
            event.desc, season_duration(event.offset), os.date("%H:%M", epoch() + event.offset)))
    else
        message(le.czas.UI.event, "NAJBLIŻSZE WYDARZENIE", "Brak danych")
    end
end

-- Aliases ---------------------------------------------------------------

function le.czas.setup_aliases()
    le.czas.aliases = le.czas.aliases or {}

    le.czas.aliases.help = tempAlias("^/le\\.czas$", function()
        if le.ui and le.ui.output then
            le.ui.output("czas", "Zegar synchronizuje się automatycznie po komendzie: czas")
            le.ui.command("kal", "/le.kal [liczba]", "/le.kal", "najbliższe wydarzenia", false)
            le.ui.command("kal", "/le.kal tydzien", "/le.kal tydzien", "agenda na najbliższe 7 dni", false)
        end
    end)

    le.czas.aliases.ev = tempAlias("^/le\\.kal(?: (\\d+))?$", function()
        local no_imperium = not le.czas.get_game_sec("imperium")
        local no_ishtar = not le.czas.get_game_sec("ishtar")
        if no_imperium and no_ishtar then
            if le.ui and le.ui.output then
                le.ui.output("kal", "Brak synchronizacji dla obu domen.")
                le.ui.note("kal", "Wpisz w grze: czas · po odwiedzeniu każdej domeny.")
            end
            return
        end
        le.czas.show_calendar(tonumber(matches[2]) or 20)
    end)

    le.czas.aliases.agenda = tempAlias("^/le\\.kal (?:tydzien|agenda)$", function()
        le.czas.show_week_agenda()
    end)
end

-- Lifecycle ---------------------------------------------------------------

function le.czas.cleanup()
    if le.czas.timer then pcall(killTimer, le.czas.timer); le.czas.timer = nil end
    if le.czas.room_handler then pcall(killAnonymousEventHandler, le.czas.room_handler); le.czas.room_handler = nil end
    if le.czas.time_handler then pcall(killAnonymousEventHandler, le.czas.time_handler); le.czas.time_handler = nil end
    if le.czas.exit_handler then pcall(killAnonymousEventHandler, le.czas.exit_handler); le.czas.exit_handler = nil end
    if le.czas.time_trigger then pcall(killTrigger, le.czas.time_trigger); le.czas.time_trigger = nil end
    if le.czas.aliases then
        for _, id in pairs(le.czas.aliases) do pcall(killAlias, id) end
    end
    if le.czas.UI.clock then le.czas.UI.clock:hide(); le.czas.UI.clock = nil end
    if le.czas.UI.event then le.czas.UI.event:hide(); le.czas.UI.event = nil end
end

function le.czas.init()
    le.czas.cleanup()
    le.czas.load()
    le.czas.seed_ishtar_sun()
    le.czas.save()
    le.czas.UI.clock = Geyser.Label:new(le.czas.config.clock)
    le.czas.UI.clock:setStyleSheet(le.czas.config.clock_style)
    le.czas.UI.event = Geyser.Label:new(le.czas.config.event)
    le.czas.UI.event:setStyleSheet(le.czas.config.event_style)
    le.czas.setup_aliases()
    le.czas.time_trigger = tempRegexTrigger(
        [[^Jest (?:dokladnie|w przyblizeniu) .+ wedlug (?:rachuby czasu Starszego Ludu|Kalendarza Imperialnego)\.$]],
        function() le.czas.on_time_text(matches[1]) end
    )
    le.czas.room_handler = registerAnonymousEventHandler("gmcp.room", le.czas.on_room)
    le.czas.time_handler = registerAnonymousEventHandler("gmcp.room.time", le.czas.on_room_time)
    le.czas.exit_handler = registerAnonymousEventHandler("sysExitEvent", le.czas.save)
    le.czas.timer = tempTimer(1, function()
        local ok, err = pcall(le.czas.UI.update)
        if not ok and le.czas.UI.clock then message(le.czas.UI.clock, "BLAD", tostring(err)) end
    end, true)
    le.czas.on_room()
    le.czas.UI.update()
    le.czas.log("info", "le.czas zaladowany. Wpisz /le.czas po pomoc.")
end

le.czas.init()
