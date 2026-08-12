-- le.flakoniki: rozpoznawanie i etykiety flakoników Arkadii.

le = le or {}
le.flakoniki = le.flakoniki or {}
le.flakoniki.triggers = le.flakoniki.triggers or {}
le.flakoniki.aliases = le.flakoniki.aliases or {}
le.flakoniki.config = le.flakoniki.config or {
    show_inline_badge = true,
    color_text = true,
}

local function flask(key, stem, label, description, color)
    return {
        key = key,
        label = label,
        description = description,
        color = color,
        -- Obsługuje także złożone przymiotniki, np.
        -- „trójkątny przezroczysto-żółty flakonik”.
        pattern = string.format(
            [[(?i)\b((?:(?:[a-z]+\s+)?(?:[a-z]+-)?%s[a-z]*\s+(?:[a-z]+\s+)?|flakonik[a-z]*\s+(?:[a-z]+\s+)?(?:[a-z]+-)?%s[a-z]*)flakonik[a-z]*)\b]],
            stem, stem
        ),
    }
end

le.flakoniki.definitions = {
    flask("bialy", "bial", "+reg mana", "Regeneracja many", "#D8DBE2"),
    flask("srebrny", "srebrn", "+reg zmęczenia", "Regeneracja zmęczenia", "#B8BDC8"),
    flask("purpurowy", "pu[rp]*pur", "+odporność spaczenie", "Odporność na skażenie", "#9D88C4"),
    flask("niebieski", "niebiesk", "+odtrucie", "Antidotum / leczenie trucizny", "#78A9C8"),
    flask("czerwony", "czerwon", "+wytrzymałość", "Zwiększenie wytrzymałości", "#C98282"),
    flask("zielony", "zielon", "+zręczność", "Zwiększenie zręczności", "#82B996"),
    flask("pomaranczowy", "pomaranczow", "+reg HP", "Regeneracja życia", "#CF9A68"),
    flask("zolty", "zolt", "+siła", "Zwiększenie siły", "#C9B66F"),
    flask("szmaragdowy", "szmaragdow", "+odporność zimno", "Odporność na zimno", "#78AE9A"),
    flask("czarny", "czarn", "+odporność ogień", "Odporność na ogień", "#8B909A"),
}

local function output(text)
    if le.ui and le.ui.output then return le.ui.output("flakoniki", text) end
    cecho("\n<LightBlue>▎<reset>  " .. tostring(text or "") .. "\n")
end

local function note(text)
    if le.ui and le.ui.note then return le.ui.note("flakoniki", text) end
    output(text)
end

local function dc(color, text)
    if le.ui and le.ui.dc then return le.ui.dc(color, text) end
    return tostring(text or "")
end

function le.flakoniki.on_match(matched, definition)
    if not matched or matched == "" or selectString(matched, 1) < 0 then return end
    local config = le.flakoniki.config
    local replacement = matched
    if config.color_text then replacement = dc(definition.color, replacement) end
    if config.show_inline_badge then
        replacement = replacement .. dc("#8B909A", " · " .. definition.label)
    end
    if config.color_text or config.show_inline_badge then creplace(replacement) end
    deselect()
    resetFormat()
end

function le.flakoniki.show_list()
    output("Flakoniki · właściwości")
    for _, definition in ipairs(le.flakoniki.definitions) do
        note(string.format("%s · %s", dc(definition.color, definition.key), definition.description))
    end
end

function le.flakoniki.toggle_badge()
    le.flakoniki.config.show_inline_badge = not le.flakoniki.config.show_inline_badge
    output("Etykiety efektów · " .. (le.flakoniki.config.show_inline_badge and "włączone" or "wyłączone"))
end

function le.flakoniki.toggle_color()
    le.flakoniki.config.color_text = not le.flakoniki.config.color_text
    output("Kolorowanie nazw · " .. (le.flakoniki.config.color_text and "włączone" or "wyłączone"))
end

function le.flakoniki.show_help()
    output("Pomoc · flakoniki")
    note("Rozpoznaje flakoniki, koloruje ich nazwy i opcjonalnie dopisuje efekt.")
    if le.ui and le.ui.command then
        le.ui.command("flakoniki", "/le.flakoniki lista", "/le.flakoniki lista", "pokaż właściwości flakoników", false)
        le.ui.command("flakoniki", "/le.flakoniki etykiety", "/le.flakoniki etykiety", "przełącz etykiety efektów", false)
        le.ui.command("flakoniki", "/le.flakoniki kolor", "/le.flakoniki kolor", "przełącz kolorowanie nazw", false)
    end
end

function le.flakoniki.cleanup()
    for _, id in pairs(le.flakoniki.triggers or {}) do if id then pcall(killTrigger, id) end end
    for _, id in pairs(le.flakoniki.aliases or {}) do if id then pcall(killAlias, id) end end
    le.flakoniki.triggers, le.flakoniki.aliases = {}, {}
end

function le.flakoniki.init()
    le.flakoniki.cleanup()
    if type(tempRegexTrigger) ~= "function" then return false end
    for _, definition in ipairs(le.flakoniki.definitions) do
        local def = definition
        le.flakoniki.triggers[def.key] = tempRegexTrigger(def.pattern, function()
            le.flakoniki.on_match(matches[2] or matches[1], def)
        end)
    end
    le.flakoniki.aliases.help = tempAlias([[^/le\.flakoniki$]], le.flakoniki.show_help)
    le.flakoniki.aliases.list = tempAlias([[^/le\.flakoniki lista$]], le.flakoniki.show_list)
    le.flakoniki.aliases.badge = tempAlias([[^/le\.flakoniki etykiety$]], le.flakoniki.toggle_badge)
    le.flakoniki.aliases.color = tempAlias([[^/le\.flakoniki kolor$]], le.flakoniki.toggle_color)
    return true
end

return le.flakoniki.init()
