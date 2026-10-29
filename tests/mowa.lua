-- Test integracji callbacków z atrapami publicznego API Mudleta (Lua 5.1).
local resources, serial, row, inserted, cursor = {}, 0, 0, "", 0
local function register(kind, callback, color)
    serial = serial + 1
    resources[serial] = { kind = kind, callback = callback, color = color }
    return serial
end
function tempAnsiColorTrigger(fg, bg, callback)
    assert(fg >= 0 and fg <= 255 and bg == -1)
    return register("ansi", callback, fg)
end
function tempRegexTrigger(pattern, callback)
    assert(pattern == "^.*$")
    return register("regex", callback)
end
function tempAlias(pattern, callback) return register("alias", callback) end
function killTrigger(id) resources[id] = nil end
killAlias = killTrigger
killTimer = killTrigger
function send() error("Nie wolno wysyłać komend") end
function tempTimer() error("Nie potrzeba timerów") end
function cecho() end
function getLineNumber() return row end
function moveCursor(x) cursor = x; return true end
function moveCursorEnd() end
function insertText(text)
    inserted = inserted:sub(1, cursor) .. text .. inserted:sub(cursor + 1)
    cursor = cursor + #text
end
local accents = {}
function setFgColor(r, g, b) accents[#accents + 1] = string.format("%02X%02X%02X", r, g, b) end
function resetFormat() end
local function count(kind)
    local n = 0
    for _, r in pairs(resources) do if r.kind == kind then n = n + 1 end end
    return n
end
local function feed(text, color, ansi_first)
    row, line = row + 1, text
    local callbacks = {}
    for _, r in pairs(resources) do
        if r.kind == "regex" or (r.kind == "ansi" and r.color == color) then
            callbacks[#callbacks + 1] = r
        end
    end
    table.sort(callbacks, function(a, b)
        if a.kind == b.kind then return false end
        return (a.kind == "ansi") == ansi_first
    end)
    for _, r in ipairs(callbacks) do assert(loadstring(r.callback))() end
end
local function header()
    feed("Twoje ustawienia kolorow sa nastepujace:")
    feed("")
    feed("\t* tekst * (248)")
    feed("\tInne postaci")
    feed("\t* druzyna * (189)")
    feed("\tStan postaci")
    feed("\t* wysoki poziom stanu * (156)")
    feed("\tKomunikacja")
end
local function finish() feed("\t* emocje do mnie * (225)") end
local function check(a, b, c)
    assert(le.mowa.colors.mowa == a and le.mowa.colors.szept == b and le.mowa.colors.krzyk == c)
    for _, kind in ipairs({"mowa", "szept", "krzyk"}) do
        local id, value = le.mowa.triggers["xterm_" .. kind], le.mowa.colors[kind]
        if value then assert(resources[id].color == value - 1) else assert(id == nil) end
    end
end
assert(dofile("le/mowa.lua"))
check(153, 160, 117)
assert(count("ansi") == 3 and count("regex") == 1 and count("alias") == 2)
feed("\t* mowa * (23)") -- bez nagłówka: ignoruj
check(153, 160, 117)
header()
feed("▎▎ \t* mowa * (153)", 152, true)
feed("\t* szept * (160)", 159, false)
feed("\t* krzyk * (117)", 116, true)
finish()
assert(inserted == "")
check(153, 160, 117)
header()
feed("\t* mowa * (1)")
feed("\t* szept * (256)")
feed("\t* krzyk * (42)")
finish()
check(1, 256, 42)
feed("Elf mowi: Witaj.", 0, true)
assert(inserted == "▎▎ ")
inserted = ""
feed("Stary kolor nie pasuje.", 152, false)
assert(inserted == "")
for _, invalid in ipairs({"", "(0)", "(257)", "(-1)", "(1.5)", "(abc)", "(12) smieci"}) do
    header()
    feed("\t* mowa * " .. invalid)
    feed("\t* szept * (160)") -- krzyk nieobecny
    finish()
    check(false, 160, false)
    assert(count("ansi") == 1)
end
header()
feed("\t* mowa * (88)")
assert(dofile("le/mowa.lua")) -- odrzucenie niekompletnego odczytu, zachowanie mapowania
check(false, 160, false)
assert(count("regex") == 1 and count("alias") == 2)
for i = 1, 5 do
    header()
    feed("\t* mowa * (42)")
    feed("\t* szept * (42)")
    feed("\t* krzyk * (42)")
    finish()
    assert(count("ansi") == 3)
end
inserted = ""
feed("Elf krzyczy: Glosna wypowiedz.", 41, true)
assert(inserted == "▎▎ ") -- wspólny kolor: jedna para
header()
for i = 1, 121 do feed("") end
feed("\tKomunikacja")
feed("\t* mowa * (9)")
finish()
check(42, 42, 42)
header()
feed("\t* mowa * (7)")
feed("\tOpisy lokacji")
check(7, false, false)
header()
feed("\t* mowa * (18)")
feed("Elf mowi: Witaj.")
finish()
check(7, false, false)
-- Ustawienia z raportu testera: kolory komunikacji pokrywają się z innymi.
header()
feed("\t* mowa * (12)")
feed("\t* szept * (153)")
feed("\t* krzyk * (123)")
finish()
local words = {
    mowa = {"mowisz", "mowi", "syczy", "huczy", "burczy", "skrzypi", "skrzeczy", "spiewa", "nuci", "grzmi"},
    szept = {"szepczesz", "szepcze"}, krzyk = {"krzyczysz", "krzyczy"},
}
local colors = { mowa = 11, szept = 152, krzyk = 122 }
local expected_accents = { mowa = "7FAFC0", szept = "A39CBC", krzyk = "C88478" }
for kind, verbs in pairs(words) do
    for _, verb in ipairs(verbs) do
        for _, first in ipairs({true, false}) do
            local text = "Wysoki siwy elf " .. verb .. " do ciebie: Witaj!"
            if verb == "mowisz" or verb == "szepczesz" or verb == "krzyczysz" then
                text = verb:sub(1, 1):upper() .. verb:sub(2) .. ": Witaj!"
            end
            inserted, accents = "", {}
            feed(text, colors[kind], first)
            assert(inserted == "▎▎ ", text)
            assert(accents[2] == expected_accents[kind])
            inserted = ""
            feed(text, 200, first)
            assert(inserted == "", "Wrong color must not match")
        end
    end
end
local negatives = {
    "skradanie sie: znakomicie [9/10]", "walka dwiema bronmi: dobrze [6/10]",
    "wspinaczka: dobrze [6/10] (+lina)",
    "[2/6] Lekko ranisz wielkiego gorskiego trolla.",
    "Wielki gorski troll jest ciezko ranny.", "Pelnym gracji zwodem odskakujesz.",
    "W oddali grzmi.", "Drzwi skrzypiace na wietrze: zamkniete.",
    "Opis: elf mowi do ciebie.", "Elf przemowi: Witaj.",
    "Elf mowiacy: Witaj.", "mowi!", "Elf szepcze: on mowi i krzyczy.",
}
for _, text in ipairs(negatives) do
    inserted = ""
    feed(text, 11, true)
    assert(inserted == "", text)
end
inserted = ""
feed("Elf mowi: on szepcze i krzyczy.", 152, false)
assert(inserted == "", "Body must not select whisper")
-- Wspólny kolor: rodzaj belki zależy od słowa, nie kolejności triggerów.
le.mowa.colors = {mowa = 153, szept = 153, krzyk = 153}
le.mowa.refresh_colors()
assert(dofile("le/mowa.lua"))
for kind, verbs in pairs(words) do
    for _, first in ipairs({true, false}) do
        inserted, accents = "", {}
        feed("Elf " .. verbs[#verbs] .. ": Test.", 152, first)
        assert(inserted == "▎▎ " and accents[2] == expected_accents[kind])
    end
end
le.mowa.show_help()
le.mowa.preview()
assert(le.mowa.configure_game_colors == nil)
le.mowa.cleanup()
assert(next(resources) == nil)
tempRegexTrigger = nil
assert(le.mowa.init())
le.mowa.cleanup()
tempAnsiColorTrigger = nil
assert(le.mowa.init() == false)
assert(next(resources) == nil)
print("OK: passive speech colors, lifecycle, markers and no game commands")
