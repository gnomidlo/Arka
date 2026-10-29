-- Uruchom: texlua tests/ui.lua (lub fengari tests/ui.lua).
-- Regresja: triggery Mudleta ustawiaja kursor w kolumnie 0 linii NPC.
local output, cursor, seeks = "", 0, 0
local function append(value)
    value = tostring(value or ""):gsub("<[^>]+>", "")
    output = output .. value
    local last = value:match("([^\n]*)$")
    if value:find("\n", 1, true) then
        cursor = #last
    else
        cursor = cursor + #value
    end
end

moveCursorEnd = function()
    seeks = seeks + 1
    cursor = #(output:match("([^\n]*)$") or "")
    return true
end
getColumnNumber = function() return cursor end
echo = append
decho = append
dofile("le/ui.lua")

output = "Czarnowlosy stary elf mowi do ciebie: Dziekuje, wiecej mi juz nie trzeba."
cursor = 0 -- kursor triggera na poczatku pelnej linii
le.ui.output("zlec", "Zlecenie od Czarnowlosy stary elf zostalo wykonane.")
assert(output:find("trzeba.\n▎  Zlecenie", 1, true),
    "zlecenie zostalo doklejone do wypowiedzi NPC")
assert(seeks == 1, "nie przesunieto kursora na koniec bufora")

local before = output
le.ui.output("zlec", "Lacznie wykonanych zlecen: 80")
assert(output:sub(#before + 1):find("^▎  Lacznie"),
    "kolejny komunikat powinien zaczynac sie bez pustej linii")

-- Inne komunikaty uzywaja dokladnie tego samego mechanizmu.
output = "Wkraczasz na trakt."
cursor = 0
le.ui.note("czas", "Zapisano swit")
assert(output:find("trakt.\n▎  Zapisano", 1, true),
    "podobny komunikat kalendarza nie otrzymal nowej linii")
print("OK: nowa linia przed komunikatami triggerow i brak pustych linii")
