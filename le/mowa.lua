-- le.mowa: minimalistyczne oznaczanie mowy, szeptu i krzyku po kolorach ANSI.

le = le or {}
le.mowa = le.mowa or {}
le.mowa.triggers = le.mowa.triggers or {}
le.mowa.aliases = le.mowa.aliases or {}
le.mowa.timers = le.mowa.timers or {}

le.mowa.text_patterns = {
    mowa = [[(?i)\b(?:mruczy|mowi|nuci|huczy|marudzi|bulgocze|syczy|skrzypi|skrzeczy|mowisz)\b]],
    szept = [[(?i)\b(?:szepcze|szepczesz)\b]],
    krzyk = [[(?i)\b(?:krzyczy|krzyczysz)\b]],
}

-- Numery ustawiane komendą gry są o jeden wyższe od indeksów ANSI 256,
-- które raportuje Mudlet (np. kolor gry 153 jest widoczny jako ANSI 152).
le.mowa.types = {
    {
        key = "mowa",
        label = "Mowa",
        game_color = 153,
        ansi_color = 152,
        accent = "#7FAFC0",
        command = "ustaw kolor mowy 153",
    },
    {
        key = "szept",
        label = "Szept",
        game_color = 160,
        ansi_color = 159,
        accent = "#A39CBC",
        command = "kolor szeptu 160",
    },
    {
        key = "krzyk",
        label = "Krzyk",
        game_color = 117,
        ansi_color = 116,
        accent = "#C88478",
        command = "ustaw kolor krzyku 117",
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

local speech_bar = "▎"
if type(utf8) == "table" and type(utf8.char) == "function" then
    speech_bar = utf8.char(0x258B)
end

local function marker(definition)
    if le.ui and le.ui.dc then return le.ui.dc(definition.accent, speech_bar) end
    return "<127,175,192>" .. speech_bar .. "<r>"
end

function le.mowa.on_color(kind)
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
        -- 1. Wstawiamy dwie spacje na pozycji 0 (przesuwa tekst gry czysto w prawo)
        if type(insertText) == "function" then
            insertText("  ")
        elseif type(dinsertText) == "function" then
            dinsertText("  ")
        end

        -- 2. Wracamy kursorem na pozycję 0 (przed wstawione spacje)
        pcall(moveCursor, 0, line_number)

        -- 3. Wstawiamy sam pokolorowany symbol belki (bez spacji w tym samym ciągu)
        local m = marker(definition)
        if m:find("^<#") and type(cinsertText) == "function" then
            cinsertText(m)
        elseif type(dinsertText) == "function" then
            dinsertText(m)
        elseif type(cinsertText) == "function" then
            cinsertText(m)
        end

        -- 4. Przywracamy kursor na koniec linii
        if type(moveCursorEnd) == "function" then
            pcall(moveCursorEnd)
        end
    else
        -- Fallback dla braku obsługi kursorów
        prefix("|  ")
    end
end

function le.mowa.configure_game_colors()
    for index, definition in ipairs(le.mowa.types) do
        local command = definition.command
        if index == 1 then
            send(command)
        else
            le.mowa.timers[index] = tempTimer((index - 1) * 0.2, function()
                send(command)
                le.mowa.timers[index] = nil
            end)
        end
    end
    output("Wysłano ustawienia kolorów · mowa 153 · szept 160 · krzyk 117.")
end

function le.mowa.preview()
    if le.ui and le.ui.output then
        le.ui.output("mowa", "Mowa · kolor 153")
        le.ui.output("szept", "Szept · kolor 160")
        le.ui.output("krzyk", "Krzyk · kolor 117")
    end
end

function le.mowa.show_help()
    output("Pomoc · mowa")
    note("Wypowiedzi są oznaczane samą belką; treść i kolor gry pozostają bez zmian.")
    if le.ui and le.ui.command then
        le.ui.command("mowa", "/le.mowa ustaw", "/le.mowa ustaw",
            "ustaw w grze kolory 153, 160 i 117", false)
        le.ui.command("mowa", "/le.mowa podglad", "/le.mowa podglad",
            "pokaż trzy warianty belki", false)
    end
    note("Mapowanie · mowa 153 · szept 160 · krzyk 117")
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
    le.mowa.triggers = {}
    le.mowa.aliases = {}
    le.mowa.timers = {}
end

function le.mowa.init()
    le.mowa.cleanup()
    le.mowa.last_line_number = nil

    local has_color_triggers = type(tempAnsiColorTrigger) == "function"
    local has_text_triggers = type(tempRegexTrigger) == "function"
    if not has_color_triggers and not has_text_triggers then
        output("Ta wersja Mudleta nie obsługuje wymaganych triggerów.")
        return false
    end

    for _, definition in ipairs(le.mowa.types) do
        local kind = definition.key
        if has_color_triggers then
            local ansi_color = definition.ansi_color
            le.mowa.triggers["color_" .. kind] = tempAnsiColorTrigger(ansi_color, -1, function()
                le.mowa.on_color(kind)
            end)
        end
        if has_text_triggers then
            le.mowa.triggers["text_" .. kind] = tempRegexTrigger(
                le.mowa.text_patterns[kind],
                function() le.mowa.on_color(kind) end
            )
        end
    end

    le.mowa.aliases.help = tempAlias([[^/le\.mowa$]], le.mowa.show_help)
    le.mowa.aliases.configure = tempAlias([[^/le\.mowa ustaw$]], le.mowa.configure_game_colors)
    le.mowa.aliases.preview = tempAlias([[^/le\.mowa podglad$]], le.mowa.preview)
    return true
end

return le.mowa.init()
