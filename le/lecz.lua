-- le.lecz: dobor ziol do zatruc, chorob i pasozytow.
-- Modul korzysta wylacznie z bazy herbs.counts budowanej przez /ziola_buduj.

le = le or {}
le.lecz = le.lecz or {}
le.lecz.triggers = le.lecz.triggers or {}
le.lecz.aliases = le.lecz.aliases or {}

le.lecz.colors = {
    tag = "light_slate_blue",
    title = "thistle",
    herb = "pale_green",
    action = "light_steel_blue",
    count = "wheat",
    warning = "light_pink",
    separator = "grey",
    muted = "slate_grey",
    dark = "dim_grey",
}

le.lecz.treatments = {
    gadzi_jad = { {"barwinek","zjedz"}, {"centuria","zjedz"}, {"krzyzownica","przezuj"}, {"mandragora","rozgryz"}, {"pieciornik","przezuj"}, {"rdest_wezownik","przezuj"}, {"siezygron","rozgryz"}, {"ususzona_boldoa","rozkrusz"} },
    jad_insekta = { {"barwinek","zjedz"}, {"chaber","przezuj"}, {"mandragora","rozgryz"}, {"pieciornik","przezuj"}, {"siezygron","rozgryz"}, {"ususzona_boldoa","rozkrusz"}, {"ususzona_macznica","rozgryz"} },
    toksyna_roslinna = { {"chaber","powachaj"}, {"chaber","przezuj"}, {"mandragora","rozgryz"}, {"nostrzyk","przezuj"}, {"pieciornik","przezuj"}, {"siezygron","rozgryz"}, {"ususzona_boldoa","rozkrusz"} },
    choroba_pokarmowa = { {"bez","przezuj"}, {"centuria","zjedz"}, {"dziewanna","zjedz"}, {"mandragora","rozgryz"}, {"nawloc","rozgryz"}, {"nawloc","zjedz"}, {"rumianek","powachaj"}, {"rumianek","przyloz"}, {"ususzona_boldoa","rozkrusz"} },
    choroba_pluc = { {"chaber","powachaj"}, {"chaber","przezuj"}, {"dziewanna","zjedz"}, {"krzyzownica","przezuj"}, {"plucnica","sproszkuj"} },
    choroba_skory = { {"deren","przezuj"}, {"lukrecja","przyloz"}, {"nawloc","przyloz"}, {"przelot","sproszkuj"}, {"rumianek","powachaj"}, {"rumianek","przyloz"}, {"ususzony_jaskier","rozkrusz"}, {"ususzony_przelot","sproszkuj"} },
    choroba_zakazna = { {"bez","przezuj"}, {"bylica_cytwarowa","wetrzyj"}, {"bylica_piolun","wetrzyj"}, {"czosnek","zjedz"}, {"ususzony_czosnek","zjedz"} },
    pasozyty = { {"bagno","przyloz"}, {"bylica_cytwarowa","wetrzyj"}, {"bylica_piolun","wetrzyj"}, {"wrotycz","przyloz"} },
    pchly = { {"bagno","przyloz"} },
    odtr_ogolne = { {"ususzona_rosiczka","polknij"}, {"ususzony_starzec","sproszkuj"} },
}

le.lecz.names = {
    gadzi_jad = "gadzi jad",
    jad_insekta = "jad insekta",
    toksyna_roslinna = "toksyna roslinna",
    choroba_pokarmowa = "choroba ukladu pokarmowego",
    choroba_pluc = "choroba pluc",
    choroba_skory = "choroba skory",
    choroba_zakazna = "choroba zakazna",
    pasozyty = "pasozyty",
    pchly = "pchly",
    odtr_ogolne = "odtrutka ogolna",
    jad_wija = "jad wija",
}

le.lecz.special = {
    jad_wija = {
        info = "nie leczy sie ziolami - kup antidotum u zielarza w wiosce bobolakow",
        commands = { "wylecz zatrucie", "ulecz zatrucie" },
    },
}

le.lecz.categories = {
    { token = "gad", key = "gadzi_jad" },
    { token = "insekt", key = "jad_insekta" },
    { token = "roslinna", key = "toksyna_roslinna" },
    { token = "pokarm", key = "choroba_pokarmowa" },
    { token = "pluc", key = "choroba_pluc" },
    { token = "skora", key = "choroba_skory" },
    { token = "zakazna", key = "choroba_zakazna" },
    { token = "pasozyty", key = "pasozyty" },
    { token = "pchly", key = "pchly" },
    { token = "odtrutka", key = "odtr_ogolne" },
    { token = "wij", key = "jad_wija" },
}

le.lecz.detectors = {
    { key = "gadzi_jad", words = { "gadz", "jad gad" } },
    { key = "jad_insekta", words = { "insekt" } },
    { key = "toksyna_roslinna", words = { "toksyn" } },
    { key = "choroba_pokarmowa", words = { "pokarm" } },
    { key = "choroba_pluc", words = { "pluc" } },
    { key = "choroba_skory", words = { "skor" } },
    { key = "choroba_zakazna", words = { "zakazn" } },
    { key = "pasozyty", words = { "pasozyt", "glist", "robak" } },
    { key = "pchly", words = { "pchl" } },
    { key = "jad_wija", words = { "jadem wij", "jad wij", " wij" } },
}

local polish = {
    ["\196\133"]="a", ["\196\135"]="c", ["\196\153"]="e", ["\197\130"]="l",
    ["\197\132"]="n", ["\195\179"]="o", ["\197\155"]="s", ["\197\186"]="z",
    ["\197\188"]="z",
}

local function log(text, color)
    cecho(string.format("\n<light_sky_blue>[<%s> lecz <light_sky_blue>]<reset> %s\n",
        color or le.lecz.colors.tag, tostring(text or "")))
end

local function herb_count(herb)
    if type(herbs) == "table" and type(herbs.counts) == "table" then
        return tonumber(herbs.counts[herb] or 0) or 0
    end
    return 0
end

local function inventory_ready()
    return type(herbs) == "table"
        and type(herbs.counts) == "table"
        and next(herbs.counts) ~= nil
end

local function click_take(herb)
    return function() expandAlias("/wezz " .. herb) end
end

local function click_use(herb, action)
    return function()
        send("opusc bron", true)
        expandAlias("/z_" .. action .. " " .. herb)
    end
end

local function render_pair(item)
    local colors = le.lecz.colors
    cechoLink(string.format("<%s>%s", colors.herb, item.herb),
        click_take(item.herb), "/wezz " .. item.herb, true)
    cecho(" ")
    cechoLink(string.format("<%s>(%s)", colors.action, item.action),
        click_use(item.herb, item.action),
        "opusc bron; /z_" .. item.action .. " " .. item.herb, true)
end

function le.lecz.normalize(text)
    text = string.lower(text or "")
    text = string.gsub(text, "<[^>]->", " ")
    for source, target in pairs(polish) do text = string.gsub(text, source, target) end
    text = string.gsub(text, "[%.,;]", " ")
    return string.gsub(text, "%s+", " ")
end

function le.lecz.detect(text)
    local normalized = le.lecz.normalize(text)
    local found, seen = {}, {}
    for _, definition in ipairs(le.lecz.detectors) do
        for _, word in ipairs(definition.words) do
            if string.find(normalized, word, 1, true) and not seen[definition.key] then
                seen[definition.key] = true
                found[#found + 1] = definition.key
                break
            end
        end
    end
    return found
end

local function render_special(key, prefix)
    local colors = le.lecz.colors
    local special = le.lecz.special[key]
    cecho(string.format("\n%s<%s>%s<%s> -> <%s>%s<%s>: ",
        prefix or "   |- ", colors.title, le.lecz.names[key], colors.separator,
        colors.warning, special.info, colors.separator))
    for index, command in ipairs(special.commands) do
        local selected_command = command
        cechoLink(string.format("<%s>%s", colors.action, command),
            function() send(selected_command) end, command, true)
        if index < #special.commands then cecho(string.format(" <%s>| ", colors.separator)) end
    end
    cecho("\n")
end

function le.lecz.render_condition(key)
    local colors = le.lecz.colors
    if le.lecz.special[key] then
        render_special(key)
        return
    end

    local owned, missing = {}, {}
    for _, pair in ipairs(le.lecz.treatments[key] or {}) do
        local item = { herb = pair[1], action = pair[2], count = herb_count(pair[1]) }
        if item.count > 0 then owned[#owned + 1] = item else missing[#missing + 1] = item end
    end

    cecho(string.format("\n   <%s>|- <%s>%s<%s> -> ",
        colors.separator, colors.title, le.lecz.names[key] or key, colors.separator))
    if #owned > 0 then
        cecho(string.format("<%s>wylecz: ", colors.separator))
        for index, item in ipairs(owned) do
            render_pair(item)
            cecho(string.format("<%s>:%d", colors.count, item.count))
            if index < #owned then cecho(string.format(" <%s>| ", colors.separator)) end
        end
        cecho("\n")
        return
    end

    cecho(string.format("<%s>nie mamy odpowiednich ziol<%s>: ", colors.warning, colors.separator))
    for index, item in ipairs(missing) do
        cecho(string.format("<%s>%s <%s>(%s)", colors.muted, item.herb, colors.dark, item.action))
        if index < #missing then cecho(", ") end
    end
    cecho("\n")
end

function le.lecz.render_recommendation(found)
    local combined = {}
    for _, key in ipairs(found) do
        for _, pair in ipairs(le.lecz.treatments[key] or {}) do
            local id = pair[1] .. "\0" .. pair[2]
            combined[id] = combined[id] or { herb = pair[1], action = pair[2], keys = {} }
            combined[id].keys[key] = true
        end
    end

    local choices = {}
    for _, item in pairs(combined) do
        local coverage = 0
        for _ in pairs(item.keys) do coverage = coverage + 1 end
        item.count = herb_count(item.herb)
        item.coverage = coverage
        if coverage >= 2 and item.count > 0 then choices[#choices + 1] = item end
    end
    table.sort(choices, function(a, b)
        if a.coverage ~= b.coverage then return a.coverage > b.coverage end
        return a.herb < b.herb
    end)
    if #choices == 0 then return end

    local colors = le.lecz.colors
    cecho(string.format("\n   <%s>|= <%s>leczy kilka na raz<%s>:\n",
        colors.separator, colors.tag, colors.separator))
    for _, item in ipairs(choices) do
        local names = {}
        for _, key in ipairs(found) do
            if item.keys[key] then names[#names + 1] = le.lecz.names[key] or key end
        end
        cecho("      ")
        render_pair(item)
        cecho(string.format(" <%s>-> %s  <%s>mamy: %d\n",
            colors.separator, table.concat(names, ", "), colors.count, item.count))
    end
end

function le.lecz.report(found)
    if #found == 0 then return end
    if not inventory_ready() then
        cecho(string.format("\n   <%s>|- <%s>brak danych o ziolach, kliknij ",
            le.lecz.colors.separator, le.lecz.colors.warning))
        cechoLink("<pale_turquoise>/ziola_buduj",
            function() expandAlias("/ziola_buduj") end, "Zbuduj baze ziol", true)
        cecho("\n")
        return
    end

    if #found > 1 then
        local ok, err = pcall(le.lecz.render_recommendation, found)
        if not ok then log("Blad rekomendacji: " .. tostring(err), "light_pink") end
    end
    for _, key in ipairs(found) do
        local ok, err = pcall(le.lecz.render_condition, key)
        if not ok then log("Blad dla " .. key .. ": " .. tostring(err), "light_pink") end
    end
end

function le.lecz.on_status(text)
    le.lecz.report(le.lecz.detect(text))
end

function le.lecz.resolve_category(argument)
    argument = string.lower(argument or "")
    for _, category in ipairs(le.lecz.categories) do
        if category.token == argument or category.key == argument then return category.key end
    end
end

function le.lecz.show_category(argument)
    local key = le.lecz.resolve_category(argument)
    if not key then
        log("Nieznana kategoria: " .. tostring(argument) .. ".", "light_pink")
        le.lecz.show_help()
        return
    end
    if le.lecz.special[key] then
        render_special(key, "")
        return
    end

    local colors = le.lecz.colors
    local owned, missing = {}, {}
    for _, pair in ipairs(le.lecz.treatments[key] or {}) do
        local item = { herb = pair[1], action = pair[2], count = herb_count(pair[1]) }
        if inventory_ready() and item.count > 0 then owned[#owned + 1] = item else missing[#missing + 1] = item end
    end

    cecho(string.format("\n<sky_blue>[<thistle> lecz <sky_blue>]<reset> <%s>%s<reset>\n",
        colors.title, le.lecz.names[key] or key))
    for _, item in ipairs(owned) do
        cecho("  ")
        render_pair(item)
        cecho(string.format(" <%s>mamy: %d\n", colors.count, item.count))
    end
    for _, item in ipairs(missing) do
        cecho(string.format("  <%s>%s <%s>(%s) <%s>mamy: %d\n",
            colors.muted, item.herb, colors.dark, item.action, colors.dark, item.count))
    end
end

function le.lecz.show_help()
    cecho("\n<light_pink>╭────────────────────────────────────────────────────────╮\n")
    cecho("<light_salmon>│ <light_pink>U<light_salmon>N<khaki>I<pale_green>C<pale_turquoise>O<light_sky_blue>R<plum>N  <white>le.lecz<slate_gray> · ziola dopasowane do stanu           <light_salmon>│\n")
    cecho("<khaki>├────────────────────────────────────────────────────────┤\n")
    cecho("<pale_green>│ <slate_gray>Wpisz <white>stan<slate_gray>. Pod wynikiem pojawi sie leczenie.       <pale_green>│\n")
    cecho("<pale_turquoise>│ <slate_gray>Kliknij ziolo, aby je wziac; kliknij akcje, aby uzyc. <pale_turquoise>│\n")
    cecho("<light_sky_blue>│ <slate_gray>Ilosci pochodza z klikalnego <light_sky_blue>")
    cechoLink("/ziola_buduj", function() expandAlias("/ziola_buduj") end, "Zbuduj baze ziol", true)
    cecho("<slate_gray>.                 <light_sky_blue>│\n")
    cecho("<plum>├────────────────────────────────────────────────────────┤\n")
    cecho("<plum>│ <white>KATEGORIE                                              <plum>│\n")
    cecho("<light_pink>│ ")
    for index, category in ipairs(le.lecz.categories) do
        local token = category.token
        local color = ({ "light_pink", "light_salmon", "khaki", "pale_green", "pale_turquoise", "light_sky_blue", "plum" })[((index - 1) % 7) + 1]
        cechoLink(string.format("<%s>%s", color, category.token),
            function() expandAlias("/le.lecz " .. token) end,
            "Pokaz: " .. (le.lecz.names[category.key] or category.key), true)
        if index < #le.lecz.categories then cecho("<slate_gray> | ") end
        if index == 6 then cecho("\n<light_salmon>│ ") end
    end
    cecho("\n<pale_turquoise>╰────────────────────────────────────────────────────────╯<reset>\n")
end

function le.lecz.cleanup()
    for key, id in pairs(le.lecz.triggers or {}) do
        if id then pcall(killTrigger, id) end
        le.lecz.triggers[key] = nil
    end
    for key, id in pairs(le.lecz.aliases or {}) do
        if id then pcall(killAlias, id) end
        le.lecz.aliases[key] = nil
    end
end

function le.lecz.init()
    le.lecz.cleanup()
    le.lecz.triggers.poison = tempRegexTrigger([[^Jestes zatrut(?:y|a) (.+?)\.?$]],
        function() le.lecz.on_status(matches[2] or matches[1]) end)
    le.lecz.triggers.disease = tempRegexTrigger([[^Cierpisz na (.+?)\.?$]],
        function() le.lecz.on_status(matches[2] or matches[1]) end)
    le.lecz.triggers.parasite = tempRegexTrigger([[^Doskwieraj(?:a|\xc4\x85) ci (.+?)\.?$]],
        function() le.lecz.on_status(matches[2] or matches[1]) end)

    le.lecz.aliases.main = tempAlias([[^/le\.lecz(?:\s+([\w_]+))?$]], function()
        local argument = matches[2]
        if not argument or argument == "" or argument == "pomoc" then
            le.lecz.show_help()
        else
            le.lecz.show_category(argument)
        end
    end)
    log("Modul zaladowany.", "pale_green")
    cechoLink("<pale_turquoise>>> /le.lecz<reset> <slate_gray>- otworz pomoc<reset>\n",
        function() expandAlias("/le.lecz") end, "Otworz pomoc le.lecz", true)
end

le.lecz.init()
