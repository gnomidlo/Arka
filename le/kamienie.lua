-- le.kamienie: lawendowe oznaczanie kamieni i menu ich właściwości.

le = le or {}
le.kamienie = le.kamienie or {}
le.kamienie.triggers = le.kamienie.triggers or {}
le.kamienie.aliases = le.kamienie.aliases or {}
le.kamienie.config = le.kamienie.config or { enable_mouseover = true }

local function stone(key, adjective, mineral, effect)
    return {
        key = key,
        name = key:gsub("_", " "),
        effect = effect,
        pattern = string.format([[ (?i)\b(%s[a-z]*\s+%s[a-z]*)\b ]], adjective, mineral):gsub("^ ", ""):gsub(" $", ""),
    }
end

le.kamienie.definitions = {
    stone("wielobarwny_oliwin", "wielobarwn", "oliwin", "czysta magia +20"),
    stone("lazurowy_kyanit", "lazurow", "kyanit", "czysta magia +20"),
    stone("skrzacy_aleksandryt", "skrzac", "aleksandryt", "czysta magia +20"),
    stone("wielobarwny_labrador", "wielobarwn", "labrador", "czysta magia +10"),
    stone("fioletowy_ametyst", "fioletow", "ametyst", "czysta magia +10"),
    stone("szaroniebieski_granat", "szaroniebiesk", "granat", "elektryczność +20"),
    stone("wielobarwny_turmalin", "wielobarwn", "turmalin", "elektryczność +20"),
    stone("wzorzysty_onyks", "wzoryst", "onyks", "elektryczność +10"),
    stone("zielony_diopsyd", "zielon", "diopsyd", "kwas +20"),
    stone("zoltawozielony_szmaragd", "zoltawozielon", "szmaragd", "kwas +20"),
    stone("szmaragdowozielony_chryzoberyl", "szmaragdowozielon", "chryzoberyl", "kwas +10"),
    stone("zielonkawy_awenturyn", "zielonkaw", "awenturyn", "kwas +10"),
    stone("oliwkowozielony_serpentyn", "oliwkowozielon", "serpentyn", "kwas +10"),
    stone("ciemnozielony_malachit", "ciemnozielon", "malachit", "kwas +10"),
    stone("jasnozielony_chryzopraz", "jasnozielon", "chryzopraz", "kwas +10"),
    stone("czarny_opal", "czarn", "opal", "magia śmierci +20"),
    stone("nakrapiany_jaspis", "nakrapian", "jaspis", "magia śmierci +10"),
    stone("czarny_gagat", "czarn", "gagat", "magia śmierci +10"),
    stone("szaroczarny_hematyt", "szaroczarn", "hematyt", "magia śmierci +10"),
    stone("czerwonobrazowy_karneol", "czerwonobrazow", "karneol", "magia śmierci +10"),
    stone("bezbarwny_ortoklaz", "bezbarwn", "ortoklaz", "magia umysłu +20"),
    stone("bezbarwny_diament", "bezbarwn", "diament", "magia umysłu +20"),
    stone("bialy_opal", "bial", "opal", "magia umysłu +20"),
    stone("pasiasty_fluoryt", "pasiast", "fluoryt", "magia umysłu +10"),
    stone("zlocisty_piryt", "zlocist", "piryt", "magia umysłu +10"),
    stone("ciemnoczerwony_topaz", "ciemnoczerwon", "topaz", "ogień +30"),
    stone("krwistoczerwony_rubin", "krwistoczerwon", "rubin", "ogień +20"),
    stone("zoltawozielony_apatyt", "zoltawozielon", "apatyt", "ogień +20"),
    stone("ognisty_agat", "ognist", "agat", "ogień +10"),
    stone("krwisty_rodolit", "krwist", "rodolit", "ogień +10"),
    stone("fioletowy_szafir", "fioletow", "szafir", "powietrze +20"),
    stone("niebieski_azuryt", "niebiesk", "azuryt", "powietrze +10"),
    stone("purpurowoniebieski_lazuryt", "purpurowoniebiesk", "lazuryt", "powietrze +10"),
    stone("jasnozielony_nefryt", "jasnozielon", "nefryt", "powietrze +10"),
    stone("czarna_perla", "czarn", "perl", "woda +30"),
    stone("niebieskozielony_akwamaryn", "niebieskozielon", "akwamaryn", "woda +20"),
    stone("purpurowy_iolit", "purpurow", "iolit", "woda +20"),
    stone("biala_perla", "bial", "perl", "woda +20"),
    stone("brazowy_tytanit", "brazow", "tytanit", "ziemia +30"),
    stone("lilioworozowy_spinel", "lilioworozow", "spinel", "ziemia +20"),
    stone("zoltawobrazowy_monacyt", "zoltawobrazow", "monacyt", "ziemia +10"),
    stone("szary_obsydian", "szar", "obsydian", "ziemia +10"),
    stone("brazowy_kwarc", "brazow", "kwarc", "ziemia +10"),
    stone("niebieskawy_zoisyt", "niebieskaw", "zoisyt", "zimno +20"),
    stone("blekitny_almandyn", "blekitn", "almandyn", "zimno +20"),
    stone("niebieski_turkus", "niebiesk", "turkus", "zimno +10"),
    stone("jasnozloty_heliodor", "jasnozlot", "heliodor", "magia życia ?"),
    stone("zolty_cyrkon", "zolt", "cyrkon", "magia życia ?"),
    stone("zolty_celestyn", "zolt", "celestyn", "magia życia ?"),
    stone("zoltawobrazowy_bursztyn", "zoltawobrazow", "bursztyn", "magia życia ?"),
    stone("rozowy_rodochrozyt", "rozow", "rodochrozyt", "magia życia ?"),
    stone("jaskrawozolty_cytryn", "jaskrawozolt", "cytryn", "magia życia ?"),
    {
        key = "bezbarwny_gorski_krysztal", name = "bezbarwny gorski krysztal", effect = "ziemia +10",
        pattern = [[(?i)\b(bezbarwn[a-z]*\s+gorsk[a-z]*\s+krysztal[a-z]*)\b]],
    },
}

local accent = "#B6A2E1"
local function output(text)
    if le.ui and le.ui.output then return le.ui.output("kamienie", text) end
    cecho("\n<LightBlue>▎<reset>  " .. tostring(text or "") .. "\n")
end
local function note(text)
    if le.ui and le.ui.note then return le.ui.note("kamienie", text) end
    output(text)
end
local function dc(color, text)
    if le.ui and le.ui.dc then return le.ui.dc(color, text) end
    return tostring(text or "")
end

function le.kamienie.on_match(matched, definition)
    if not matched or matched == "" or selectString(matched, 1) < 0 then return end
    if type(fg) == "function" then fg("lavender") end

    if le.kamienie.config.enable_mouseover and type(setLink) == "function" then
        -- Wyłącznie podpowiedź właściwości; bez menu i komend wykonywanych
        -- po kliknięciu lub z menu kontekstowego.
        setLink("", definition.effect)
    end

    deselect()
    resetFormat()
end

function le.kamienie.show_list()
    output("Kamienie · właściwości")
    for _, definition in ipairs(le.kamienie.definitions) do
        note(dc(accent, definition.name) .. dc("#8B909A", " · " .. definition.effect))
    end
end

function le.kamienie.toggle_hover()
    le.kamienie.config.enable_mouseover = not le.kamienie.config.enable_mouseover
    output("Podpowiedzi kamieni · " .. (le.kamienie.config.enable_mouseover and "włączone" or "wyłączone"))
end

function le.kamienie.show_help()
    output("Pomoc · kamienie")
    note("Kamienie są oznaczane lawendą. Najedź kursorem po podpowiedź żywiołu lub magii.")
    if le.ui and le.ui.command then
        le.ui.command("kamienie", "/le.kamienie lista", "/le.kamienie lista", "pokaż właściwości kamieni", false)
        le.ui.command("kamienie", "/le.kamienie hover", "/le.kamienie hover", "przełącz podpowiedzi", false)
    end
end

function le.kamienie.cleanup()
    for _, id in pairs(le.kamienie.triggers or {}) do if id then pcall(killTrigger, id) end end
    for _, id in pairs(le.kamienie.aliases or {}) do if id then pcall(killAlias, id) end end
    le.kamienie.triggers, le.kamienie.aliases = {}, {}
end

function le.kamienie.init()
    le.kamienie.cleanup()
    if type(tempRegexTrigger) ~= "function" then return false end
    for _, definition in ipairs(le.kamienie.definitions) do
        local def = definition
        le.kamienie.triggers[def.key] = tempRegexTrigger(def.pattern, function()
            le.kamienie.on_match(matches[2] or matches[1], def)
        end)
    end
    le.kamienie.aliases.help = tempAlias([[^/le\.kamienie$]], le.kamienie.show_help)
    le.kamienie.aliases.list = tempAlias([[^/le\.kamienie lista$]], le.kamienie.show_list)
    le.kamienie.aliases.hover = tempAlias([[^/le\.kamienie hover$]], le.kamienie.toggle_hover)
    return true
end

return le.kamienie.init()
