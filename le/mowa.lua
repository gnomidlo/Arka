-- le.mowa: minimalistyczne oznaczanie mowy, szeptu i krzyku wyłącznie po kolorach ANSI.

le = le or {}
le.mowa = le.mowa or {}
le.mowa.triggers = le.mowa.triggers or {}
le.mowa.aliases = le.mowa.aliases or {}
le.mowa.timers = le.mowa.timers or {}
le.mowa.colors = le.mowa.colors or { mowa = 153, szept = 160, krzyk = 117 }

-- Arkadia numeruje kolory Xterm w komendzie gry od 1, a Mudlet od 0.
-- tempAnsiColorTrigger() obsługuje pełną paletę Xterm 256, więc nasłuchuje
-- indeksu Xterm o jeden niższego niż wartość ustawiana w grze.
le.mowa.types = {
    {
        key = "mowa",
        label = "Mowa",
        game_color = 153,
        accent = "#7FAFC0",
    },
    {
        key = "szept",
        label = "Szept",
        game_color = 160,
        accent = "#A39CBC",
    },
    {
        key = "krzyk",
        label = "Krzyk",
        game_color = 117,
        accent = "#C88478",
    },
}

local function type_definition(kind)
    for _, definition in ipairs(le.mowa.types) do
        if definition.key == kind then return definition end
    end
end

local function output(text)
    if le.ui and le.ui.output then
        le.ui.output("mowa", text)
    else
        cecho("\n<LightBlue>▎<reset>  " .. tostring(text or "") .. "\n")
    end
end

local function note(text)
    if le.ui and le.ui.note then
        le.ui.note("mowa", text)
    else
        output(text)
    end
end

-- Wąska belka UNICORN: celowo nie używamy szerokiego znaku ▋.
local speech_bar = "▎"

-- Dwie równe belki: pierwsza identyfikuje moduł mowy, druga rodzaj wypowiedzi.
local function module_marker()
    local accent = le.ui and le.ui.module and le.ui.module("mowa").accent or "#7FAFC0"
    if le.ui and le.ui.dc then return le.ui.dc(accent, speech_bar) end
    return "<127,175,192>" .. speech_bar .. "<r>"
end

local function type_marker(definition)
    if le.ui and le.ui.dc then return le.ui.dc(definition.accent, speech_bar) end
    return "<127,175,192>" .. speech_bar .. "<r>"
end

-- Zachowujemy ostatni odczyt przy hot reloadzie; false oznacza brak koloru.
local function valid_color(value)
    return type(value) == "number" and value == math.floor(value) and value >= 1 and value <= 256
end

local function plain_line(text)
    return tostring(text or ""):gsub("^%s*▎▎%s*", ""):match("^%s*(.-)%s*$")
end

function le.mowa.refresh_colors()
    for _, definition in ipairs(le.mowa.types) do
        local kind = definition.key
        local key = "xterm_" .. kind
        local value = le.mowa.colors[kind]
        if le.mowa.triggers[key] then
            pcall(killTrigger, le.mowa.triggers[key])
            le.mowa.triggers[key] = nil
        end
        if valid_color(value) and type(tempAnsiColorTrigger) == "function" then
            -- Trwały kod Lua zamiast anonimowego callbacka gubionego przez GC.
            le.mowa.triggers[key] = tempAnsiColorTrigger(value - 1, -1,
                string.format([[le.mowa.on_color(%q)]], kind))
        end
    end
end

function le.mowa.read_colors(text)
    text = plain_line(text)
    if text == "Twoje ustawienia kolorow sa nastepujace:" then
        le.mowa.color_read = { lines = 0 }
        return
    end
    local state = le.mowa.color_read
    if not state then return end
    state.lines = state.lines + 1
    -- Niekompletny wydruk nie może przechwytywać późniejszych wypowiedzi.
    if state.lines > 120 then le.mowa.color_read = nil; return end
    if text == "Komunikacja" then
        state.values = { mowa = false, szept = false, krzyk = false }
        return
    end
    if not state.values or text == "" then return end
    local kind, suffix = text:match("^%*%s*(.-)%s*%*%s*(.*)$")
    if kind and state.values[kind] ~= nil then
        local value = tonumber(suffix:match("^%((%d+)%)$"))
        state.values[kind] = valid_color(value) and value or false
        return
    end
    -- Nieoczekiwany tekst przerywa odczyt bez zmiany ostatniego mapowania.
    if kind ~= "emocje do mnie" and text ~= "Opisy lokacji" and text ~= "Walka postaci" then
        le.mowa.color_read = nil
        return
    end
    -- Emocje lub kolejna sekcja kończą odczyt; brakujące pozycje są wyłączone.
    le.mowa.colors = state.values
    le.mowa.color_read = nil
    le.mowa.refresh_colors()
end

function le.mowa.on_color(kind)
    -- Niezależnie od kolejności triggerów próbki ustawień nie są wypowiedziami.
    local text = plain_line(line)
    if le.mowa.color_read or text:match("^%*.-%*")
        or text == "Twoje ustawienia kolorow sa nastepujace:" then return end
    local definition = type_definition(kind)
    if not definition then return end

    -- Jedna linia może zawierać kilka fragmentów w tym samym kolorze.
    -- Numer wiersza chroni przed dodaniem drugiej belki do tej samej wypowiedzi.
    local line_number
    if type(getLineNumber) == "function" then
        local ok, value = pcall(getLineNumber)
        if ok then line_number = value end
    end
    if line_number and le.mowa.last_line_number == line_number then return end
    le.mowa.last_line_number = line_number

    local moved = false
    if line_number and type(moveCursor) == "function" then
        local ok, result = pcall(moveCursor, 0, line_number)
        moved = ok and result ~= false
    end

    if moved then
        -- 1. Jedna spacja jest potrzebna dopiero po obu belkach.
        if type(insertText) == "function" then
            insertText(" ")
        elseif type(dinsertText) == "function" then
            dinsertText(" ")
        end

        -- 2. Wstawiamy znaki pojedynczo. cinsertText() przesuwał kursor
        -- między fragmentami kolorów, co dawało niechciane: „▎  ▎tekst”.
        pcall(moveCursor, 0, line_number)
        local function insert_bar(hex)
            local r, g, b = tostring(hex or "#FFFFFF"):match("#?(%x%x)(%x%x)(%x%x)")
            if type(setFgColor) == "function" and r then
                pcall(setFgColor, tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
            end
            if type(insertText) == "function" then
                insertText(speech_bar)
            elseif type(dinsertText) == "function" then
                dinsertText(speech_bar)
            end
        end
        local module_accent = le.ui and le.ui.module and le.ui.module("mowa").accent or "#7FAFC0"
        insert_bar(module_accent)
        insert_bar(definition.accent)
        if type(resetFormat) == "function" then pcall(resetFormat) end

        -- 3. Przywracamy kursor na koniec linii
        if type(moveCursorEnd) == "function" then
            pcall(moveCursorEnd)
        end
    else
        -- Fallback dla braku obsługi kursorów
        prefix("| | ")
    end
end

-- Usuń funkcję pozostałą po przeładowaniu starszej wersji.
le.mowa.configure_game_colors = nil

function le.mowa.preview()
    for _, definition in ipairs(le.mowa.types) do
        local value = le.mowa.colors[definition.key]
        note(definition.label .. " · " .. (valid_color(value) and ("kolor " .. value) or "oznaczanie wyłączone"))
    end
end

function le.mowa.show_help()
    output("Pomoc · mowa")
    note("Wypowiedzi zachowują treść i kolor gry oraz otrzymują dwie belki ▎▎.")
    note("Wpisz ręcznie w grze kolory, aby odczytać ustawienia mowy, szeptu i krzyku.")
    note("Moduł nie wysyła komend ani nie zmienia kolorów w grze.")
    note("Przed pierwszym odczytem: 153/160/117. Brak lub błędny kolor po odczycie wyłącza oznaczanie.")
    if le.ui and le.ui.command then
        le.ui.command("mowa", "/le.mowa podglad", "/le.mowa podglad",
            "pokaż bieżące mapowanie kolorów", false)
    end
    le.mowa.preview()
end

function le.mowa.cleanup()
    for _, id in pairs(le.mowa.triggers or {}) do
        if id then pcall(killTrigger, id) end
    end
    for _, id in pairs(le.mowa.aliases or {}) do
        if id then pcall(killAlias, id) end
    end
    for _, id in pairs(le.mowa.timers or {}) do
        if id then pcall(killTimer, id) end
    end
    le.mowa.color_read = nil
    le.mowa.triggers = {}
    le.mowa.aliases = {}
    le.mowa.timers = {}
end

function le.mowa.init()
    le.mowa.cleanup()
    le.mowa.last_line_number = nil

    if type(tempAnsiColorTrigger) ~= "function" then
        output("Ta wersja Mudleta nie obsługuje triggerów ANSI 256.")
        return false
    end

    le.mowa.refresh_colors()
    if type(tempRegexTrigger) == "function" then
        le.mowa.triggers.colors = tempRegexTrigger([[^.*$]], [[le.mowa.read_colors(line)]])
    else
        output("Brak obsługi odczytu kolorów; pozostaje bieżące mapowanie.")
    end

    le.mowa.aliases.help = tempAlias([[^/le\.mowa$]], le.mowa.show_help)
    le.mowa.aliases.preview = tempAlias([[^/le\.mowa podglad$]], le.mowa.preview)
    return true
end

return le.mowa.init()
