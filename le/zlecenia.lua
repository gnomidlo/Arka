le = le or {}

-- le.zlecenia: śledzenie zleceń od NPC. samodzielny moduł UNICORN
-- (własne triggery/aliasy, własne triggery/aliasy, zapis JSON, panel Geyser).
-- Uwaga: kolorowe echo używa decho() (tagi <r,g,b>, reset to <r> a nie <reset>).
-- Treść etykiet Geyser to Qt rich text: bez flexbox/grid/position/transform,
-- justowanie dwóch kolumn robimy przez proste <table>, tak jak w ChronoPop.
-- le.zlecenia są kluczowane po ID lokacji NPC (nie po imieniu) — to samo NPC
-- bywa widoczne pod różnymi nazwami (np. przed/po przedstawieniu się).

le.zlecenia = le.zlecenia or {}
le.zlecenia.UI = le.zlecenia.UI or {}

le.zlecenia.config = {
    panel = {
        x = "-280px", width = 260, top = -560,
        headerHeight = 22, itemHeight = 24, expandedExtra = 104, gap = 0, maxItems = 8,
        routeWidth = 78, deleteWidth = 48, actionHeight = 18, btnMargin = 6,
    },
    style = [[
        background-color: rgba(12, 14, 18, 220);
        border: none;
        border-left: 3px solid #D7A84D;
        border-radius: 0px;
        padding: 3px 8px;
        font-family: 'DejaVu Sans Mono', 'Consolas', monospace;
    ]],
    btnStyle = [[
        background-color: transparent;
        border: none;
        padding: 0px;
        font-family: 'DejaVu Sans Mono', 'Consolas', monospace;
    ]],
    -- Wspólna, semantyczna paleta UNICORN.
    colors = {
        accent = "#D7A84D", text = "#D8DBE2", bracket = "#D7A84D",
        brand = "#D7A84D", label = "#9A9FAA", npc = "#D8DBE2",
        value = "#D8DBE2", good_label = "#82C9A5", good = "#82C9A5",
        urgent_high = "#D98282", urgent_mid = "#D7AE5D", urgent_low = "#8FC9A3",
        muted = "#8B909A", muted_dim = "#666B75", danger_link = "#D98282",
    },
    -- Zegar Arkadii: jedna godzina gry trwa 120 sekund czasu rzeczywistego.
    real_seconds_per_game_hour = 120,
    check_interval = 30,
}

local function rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16) .. "," .. tonumber(hex:sub(3, 4), 16) .. "," .. tonumber(hex:sub(5, 6), 16)
end

-- decho tag helper: <r,g,b>text<r>  (decho's reset tag is <r>, not <reset>)
local function dc(hex, text)
    return string.format("<%s>%s<r>", rgb(hex), tostring(text))
end

local function epoch() return os.time() end

-- Formatowanie pozostałego czasu: "2d 07h" / "3h 58m" / "12m" ------------

function le.zlecenia.duration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)
    if d > 0 then return string.format("%dd %02dh", d, h) end
    if h > 0 then return string.format("%dh %02dm", h, m) end
    return string.format("%dm", m)
end

function le.zlecenia.compact_duration(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%d:%02d", hours, minutes)
end

function le.zlecenia.urgency_color(seconds)
    if seconds == nil then return le.zlecenia.config.colors.muted end
    if seconds < 6 * 3600 then return le.zlecenia.config.colors.urgent_high end
    if seconds < 2 * 86400 then return le.zlecenia.config.colors.urgent_mid end
    return le.zlecenia.config.colors.urgent_low
end

-- Polskie liczebniki (odmiany używane po "sztuk"/"dni" itp.) --------------

le.zlecenia.numberWords = {
    ["jeden"] = 1, ["jednego"] = 1, ["jednej"] = 1, ["jedna"] = 1,
    ["dwa"] = 2, ["dwoch"] = 2, ["dwu"] = 2, ["dwie"] = 2,
    ["trzy"] = 3, ["trzech"] = 3,
    ["cztery"] = 4, ["czterech"] = 4,
    ["piec"] = 5, ["pieciu"] = 5,
    ["szesc"] = 6, ["szesciu"] = 6,
    ["siedem"] = 7, ["siedmiu"] = 7,
    ["osiem"] = 8, ["osmiu"] = 8,
    ["dziewiec"] = 9, ["dziewieciu"] = 9,
    ["dziesiec"] = 10, ["dziesieciu"] = 10,
    ["jedenascie"] = 11, ["jedenastu"] = 11,
    ["dwanascie"] = 12, ["dwunastu"] = 12,
    ["trzynascie"] = 13, ["trzynastu"] = 13,
    ["czternascie"] = 14, ["czternastu"] = 14,
    ["pietnascie"] = 15, ["pietnastu"] = 15,
    ["szesnascie"] = 16, ["szesnastu"] = 16,
    ["siedemnascie"] = 17, ["siedemnastu"] = 17,
    ["osiemnascie"] = 18, ["osiemnastu"] = 18,
    ["dziewietnascie"] = 19, ["dziewietnastu"] = 19,
    ["dwadziescia"] = 20, ["dwudziestu"] = 20,
    ["trzydziesci"] = 30, ["trzydziestu"] = 30,
    ["czterdziesci"] = 40, ["czterdziestu"] = 40,
    ["piecdziesiat"] = 50, ["piecdziesieciu"] = 50,
    ["szescdziesiat"] = 60, ["szescdziesieciu"] = 60,
    ["siedemdziesiat"] = 70, ["siedemdziesieciu"] = 70,
    ["osiemdziesiat"] = 80, ["osiemdziesieciu"] = 80,
    ["dziewiecdziesiat"] = 90, ["dziewiecdziesieciu"] = 90,
    ["sto"] = 100, ["stu"] = 100,
}

-- Jednostki, które warto skrócić w wyświetlanym tekście.
le.zlecenia.unitNormalize = {
    kilogramow = "kg", kilogram = "kg", kilogramy = "kg", kilograma = "kg",
}

-- Słowa "łączące", zawsze obecne w opisach zleceń, niezależne od słownika
-- uczonego z gry (rasy mówiące bez spacji, np. gnomy, potrzebują ich do
-- segmentacji zlepionego tekstu).
le.zlecenia.seedVocab = {
    "z", "o", "i", "kazda", "sztuke", "sztuk", "sztuki", "dni", "dzien", "godzin", "kilka",
    "kg", "srednich", "srednia", "srednie", "duzych", "duza", "duze", "malych", "mala", "male",
    "ciezkich", "ciezka", "ciezkie", "lekkich", "lekka", "lekkie", "przynajmniej", "sredniej",
    "jakosci", "chroniacych", "nogi", "rece", "tors",
}

-- Uczy słownik segmentacji na podstawie tekstu, który już mamy PODZIELONY
-- spacjami (normalne, nie-gnomie wiadomości) — budujemy słownik z realnych
-- zleceń, więc z czasem "gnomia mowa" rozszyfrowuje się sama.
function le.zlecenia.learn_words(text)
    if not text then return end
    le.zlecenia.data.vocab = le.zlecenia.data.vocab or {}
    local changed = false
    for w in text:gmatch("%a+") do
        w = w:lower()
        if #w > 1 and not le.zlecenia.data.vocab[w] then
            le.zlecenia.data.vocab[w] = true
            changed = true
        end
    end
    return changed
end

function le.zlecenia.build_dict()
    local dict = {}
    for w in pairs(le.zlecenia.numberWords) do dict[w] = true end
    for _, w in ipairs(le.zlecenia.seedVocab) do dict[w] = true end
    if le.zlecenia.data.vocab then
        for w in pairs(le.zlecenia.data.vocab) do dict[w] = true end
    end
    return dict
end

-- Segmentacja zlepionego (bez spacji) tekstu na słowa ze słownika, metodą
-- programowania dynamicznego z pamięcią podręczną (klasyczny "word break").
-- Preferuje najdłuższe dopasowanie na starcie. Zwraca nil, jeśli nie da się
-- podzielić w całości.
function le.zlecenia.segment(s, dict, memo)
    if s == "" then return {} end
    memo = memo or {}
    if memo[s] ~= nil then return memo[s] or nil end
    for i = #s, 1, -1 do
        local word = s:sub(1, i)
        if dict[word] then
            local rest = le.zlecenia.segment(s:sub(i + 1), dict, memo)
            if rest then
                local result = { word }
                for _, w in ipairs(rest) do result[#result + 1] = w end
                memo[s] = result
                return result
            end
        end
    end
    memo[s] = false
    return nil
end

-- Próbuje rozdzielić zlepiony (bez spacji) fragment tekstu gnomiej mowy na
-- słowa, zwraca (tekst_ze_spacjami, ok). Gdy się nie uda — zwraca oryginał
-- niezmieniony i ok=false (zlecenie i tak trafia na listę, tylko z surowym
-- opisem, do poprawienia ręcznie po nauczeniu słownika).
function le.zlecenia.desquash(text)
    if not text or text:find("%s") then return text, true end
    local dict = le.zlecenia.build_dict()
    local words = le.zlecenia.segment(text:lower(), dict)
    if not words then return text, false end
    return table.concat(words, " "), true
end

-- Sumuje WSZYSTKIE rozpoznane słowa-liczebniki w tekście (np. "dwudziestu
-- trzech" -> 23). Używane tam, gdzie tekst zawiera tylko liczbę.
function le.zlecenia.words_to_number(text)
    if not text then return nil end
    text = text:lower():gsub("-", " ")
    local sum, found = 0, false
    for w in text:gmatch("%S+") do
        local val = le.zlecenia.numberWords[w]
        if val then sum = sum + val; found = true end
    end
    if found then return sum end
    return tonumber(text)
end

-- Wyciąga ilość z opisu zlecenia: cyframi ("10 desek dębowych") albo
-- słownie ("dwudziestu czterech sztuk kasztanowca", "osiemdziesieciu kilogramow
-- miesa z zubra"). Zwraca (ilość, reszta_tekstu) — reszta ma znormalizowaną
-- jednostkę na początku, jeśli ją rozpoznaliśmy (kilogramow -> kg).
function le.zlecenia.extract_quantity(text)
    local qty, rest = text:match("^(%d+)%s+(.*)$")
    if not qty then
        local words = {}
        for w in text:gmatch("%S+") do words[#words + 1] = w end
        local sum, consumed = 0, 0
        for i, w in ipairs(words) do
            local val = le.zlecenia.numberWords[w:lower()]
            if val then sum = sum + val; consumed = i else break end
        end
        if consumed > 0 then
            qty = sum
            local restWords = {}
            for i = consumed + 1, #words do restWords[#restWords + 1] = words[i] end
            rest = table.concat(restWords, " ")
        end
    end
    if not qty then return nil, text end
    qty = tonumber(qty)
    local firstWord, remainder = rest:match("^(%a+)%s*(.*)$")
    if firstWord and le.zlecenia.unitNormalize[firstWord:lower()] then
        rest = le.zlecenia.unitNormalize[firstWord:lower()] .. (remainder ~= "" and (" " .. remainder) or "")
    end
    return qty, rest
end

-- Zapis/odczyt danych (JSON, jak w ChronoPop) ----------------------------

le.zlecenia.path = getMudletHomeDir() .. "/Zlecenia_data.json"
le.zlecenia.data = le.zlecenia.data or { orders = {}, completed = 0 }

function le.zlecenia.load()
    if not io.exists(le.zlecenia.path) then return end
    local file = io.open(le.zlecenia.path, "r")
    if not file then return end
    local content = file:read("*a")
    file:close()
    local ok, decoded = pcall(yajl.to_value, content)
    if ok and type(decoded) == "table" then
        le.zlecenia.data = decoded
        le.zlecenia.data.orders = le.zlecenia.data.orders or {}
        le.zlecenia.data.completed = le.zlecenia.data.completed or 0
    end
end

function le.zlecenia.save()
    local file = io.open(le.zlecenia.path, "w")
    if not file then return false end
    local ok, encoded = pcall(yajl.to_string, le.zlecenia.data)
    if not ok then file:close(); return false end
    file:write(encoded)
    file:close()
    return true
end

-- Komunikaty w oknie tekstowym --------------------------------------------

function le.zlecenia.output(message)
    local col = le.zlecenia.config.colors
    decho("\n")
    decho(dc(col.accent, "▎"))
    decho(" ")
    dechoLink(dc(col.accent, "[ zlec ]"), [[le.zlecenia.show_help()]], "Kliknij, aby wyświetlić pomoc", true)
    decho(" " .. tostring(message or "") .. "\n")
end

-- Obsługa triggerów gry: zlecenia trzymane pod kluczem ID lokacji NPC -----

function le.zlecenia.handle_no_order()
    local npcName = matches[2]:gsub("%s*$", "")
    local roomID = getPlayerRoom()
    le.zlecenia.data.orders[tostring(roomID)] = {
        npc = npcName, status = "brak", lastSeen = os.date("%H:%M %d-%m-%Y"),
        roomName = getRoomName(roomID) or "-", roomID = roomID,
    }
    le.zlecenia.save()
    le.zlecenia.output(string.format("%s nie ma dla Ciebie żadnych zleceń.", dc(le.zlecenia.config.colors.npc, npcName)))
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.new_order_core(npcName, orderType, orderDetails)
    le.zlecenia.learn_words(orderDetails)
    local quantity, rest = le.zlecenia.extract_quantity(orderDetails)
    local what = quantity and string.format("%d %s", quantity, rest) or orderDetails

    le.zlecenia.temp = {
        npc = npcName, type = orderType, what = what, itemName = rest,
        receivedAt = epoch(), initialQuantity = quantity, remainingQuantity = quantity,
        roomID = getPlayerRoom(),
    }
end

function le.zlecenia.handle_new_order()
    le.zlecenia.new_order_core(matches[2]:gsub("%s*$", ""), matches[3], matches[4])
end

function le.zlecenia.handle_new_order_gnome()
    local orderDetails, ok = le.zlecenia.desquash(matches[4])
    le.zlecenia.new_order_core(matches[2]:gsub("%s*$", ""), matches[3], orderDetails)
    if not ok then
        decho(dc(le.zlecenia.config.colors.muted, "(gnomia mowa nie w pełni rozpoznana, dodaj brakujące słowa do słownika: /le.zlecenia slowo <słowo>)\n"))
    end
end

function le.zlecenia.order_time_core(timePhrase)
    if not le.zlecenia.temp then
        decho(dc(le.zlecenia.config.colors.urgent_high, "Brak tymczasowego zlecenia do aktualizacji.\n"))
        return
    end
    le.zlecenia.learn_words(timePhrase)
    local order = le.zlecenia.temp
    local timeWord = timePhrase:gsub("%s+dni?%s*$", "")
    local timeDays = le.zlecenia.words_to_number(timeWord)

    local roomID = order.roomID or getPlayerRoom()
    order.roomID = roomID
    order.roomName = getRoomName(roomID) or "-"
    order.status = "aktywne"
    order.lastSeen = os.date("%H:%M %d-%m-%Y")

    if type(timeDays) == "number" then
        local realSeconds = timeDays * 24 * le.zlecenia.config.real_seconds_per_game_hour
        order.completionAt = order.receivedAt + realSeconds
    else
        order.completionAt = order.receivedAt + le.zlecenia.config.real_seconds_per_game_hour -- < 1 dzień: przyjmij ok. 1h realnie
    end

    -- Ta sama lokacja = to samo zlecenie, nawet jeśli NPC pokazał się pod inną nazwą.
    le.zlecenia.data.orders[tostring(roomID)] = order
    le.zlecenia.save()

    local remaining = order.completionAt - epoch()
    le.zlecenia.output(string.format(
        "Dodano zlecenie od %s: %s\n           Potrzebuje %s. Czas na realizację: %s (koniec ok. %s).",
        dc(le.zlecenia.config.colors.npc, order.npc), dc(le.zlecenia.config.colors.value, order.type),
        dc(le.zlecenia.config.colors.value, order.what),
        dc(le.zlecenia.urgency_color(remaining), le.zlecenia.duration(remaining)),
        dc(le.zlecenia.config.colors.good, os.date("%H:%M %d-%m-%Y", order.completionAt))
    ))
    le.zlecenia.temp = nil
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.handle_order_time()
    le.zlecenia.order_time_core(matches[3])
end

function le.zlecenia.handle_order_time_gnome()
    local timePhrase, ok = le.zlecenia.desquash(matches[3])
    le.zlecenia.order_time_core(timePhrase)
    if not ok then
        decho(dc(le.zlecenia.config.colors.muted, "(gnomia mowa nie w pełni rozpoznana, dodaj brakujące słowa do słownika: /le.zlecenia slowo <słowo>)\n"))
    end
end

function le.zlecenia.partial_order_core(npcName, remainingPhrase)
    local key = tostring(getPlayerRoom())
    local order = le.zlecenia.data.orders[key]
    if not order then
        le.zlecenia.output(string.format("Nie znaleziono zlecenia od %s do aktualizacji.", dc(le.zlecenia.config.colors.npc, npcName)))
        return
    end

    le.zlecenia.learn_words(remainingPhrase)
    local remainingQuantity, restText = le.zlecenia.extract_quantity(remainingPhrase)
    if not remainingQuantity then
        le.zlecenia.output(dc(le.zlecenia.config.colors.urgent_high, "Nie udało się rozpoznać pozostałej ilości."))
        return
    end

    order.npc = npcName -- aktualizujemy do najnowszej nazwy NPC
    order.remainingQuantity = remainingQuantity
    order.lastSeen = os.date("%H:%M %d-%m-%Y")
    order.what = string.format("%d %s", remainingQuantity, restText ~= "" and restText or (order.itemName or ""))

    -- Uwaga: ukończenie zlecenia zgłasza WYŁĄCZNIE osobny komunikat gry
    -- ("Dziekuje, wiecej mi juz nie trzeba.") — częściowa dostawa nigdy nie
    -- zalicza zlecenia jako wykonane, nawet gdy zejdzie do zera.
    le.zlecenia.output(string.format("Zaktualizowano zlecenie od %s. Pozostało: %s.", dc(le.zlecenia.config.colors.npc, npcName), dc(le.zlecenia.config.colors.value, order.what)))
    le.zlecenia.save()
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.handle_partial_order()
    le.zlecenia.partial_order_core(matches[2]:gsub("%s*$", ""), matches[3])
end

function le.zlecenia.handle_partial_order_gnome()
    local remainingPhrase, ok = le.zlecenia.desquash(matches[3])
    le.zlecenia.partial_order_core(matches[2]:gsub("%s*$", ""), remainingPhrase)
    if not ok then
        decho(dc(le.zlecenia.config.colors.muted, "(gnomia mowa nie w pełni rozpoznana, dodaj brakujące słowa do słownika: /le.zlecenia slowo <słowo>)\n"))
    end
end

function le.zlecenia.handle_order_completed()
    local npcName = matches[2]:gsub("%s*$", "")
    local key = tostring(getPlayerRoom())
    if le.zlecenia.data.orders[key] then
        le.zlecenia.data.orders[key] = nil
        le.zlecenia.data.completed = le.zlecenia.data.completed + 1
        le.zlecenia.save()
        le.zlecenia.output(string.format("Zlecenie od %s zostało wykonane. Usunięto z listy.", dc(le.zlecenia.config.colors.npc, npcName)))
        le.zlecenia.output(string.format("%s %s", dc(le.zlecenia.config.colors.good_label, "Łącznie wykonanych zleceń:"), dc(le.zlecenia.config.colors.good, le.zlecenia.data.completed)))
    else
        le.zlecenia.output(string.format("Nie znaleziono zlecenia od %s na liście.", dc(le.zlecenia.config.colors.npc, npcName)))
    end
    le.zlecenia.UI.rebuild()
end

-- Automatyczne wygasanie ---------------------------------------------------

function le.zlecenia.check_expired()
    local now = epoch()
    for key, order in pairs(le.zlecenia.data.orders) do
        if order.completionAt and order.completionAt <= now then
            le.zlecenia.data.orders[key] = nil
            le.zlecenia.data.completed = le.zlecenia.data.completed + 1
            le.zlecenia.output(string.format("Zlecenie na %s od %s właśnie się zakończyło. Usunięto z listy.",
                dc(le.zlecenia.config.colors.value, order.what or "-"), dc(le.zlecenia.config.colors.npc, order.npc)))
            le.zlecenia.save()
        end
    end
end

-- Lista aktywnych zleceń, posortowana po najbliższym terminie ------------
-- Każdy wpis niesie swój klucz (order.key) do usuwania/rozwijania/tras.

function le.zlecenia.active_orders_sorted()
    local list = {}
    for key, order in pairs(le.zlecenia.data.orders) do
        if order.status ~= "brak" then
            order.key = key
            list[#list + 1] = order
        end
    end
    table.sort(list, function(a, b) return (a.completionAt or math.huge) < (b.completionAt or math.huge) end)
    return list
end

-- Komendy konsolowe --------------------------------------------------------

function le.zlecenia.show_help()
    local col = le.zlecenia.config.colors
    le.zlecenia.output("--- Pomoc: Menedżer Zleceń ---")
    decho(dc(col.value, "Dostępne komendy:\n"))
    local rows = {
        { "/le.zlecenia", "pokazuje tę pomoc" },
        { "/le.zlecenia lista", "lista aktywnych zleceń" },
        { "/le.zlecenia sprawdz", "zapytaj NPCów o nowe zlecenia" },
        { "/le.zlecenia usun <nr>", "usuń zlecenie z listy" },
        { "/le.zlecenia reset", "wyczyść listę (licznik zostaje)" },
        { "/le.zlecenia slowo <słowo>", "dodaj słowo do słownika (dla gnomiej mowy)" },
    }
    for _, r in ipairs(rows) do
        decho(string.format("  %s %s\n", dc("#FDF5C4", r[1]), dc(col.muted, "— " .. r[2])))
    end
    decho(string.format("%s %s\n", dc(col.good_label, "Wykonanych zleceń:"), dc(col.good, le.zlecenia.data.completed)))
end

function le.zlecenia.show_list()
    local col = le.zlecenia.config.colors
    local orders = le.zlecenia.active_orders_sorted()
    local noOrderNpcs = {}
    for key, order in pairs(le.zlecenia.data.orders) do
        if order.status == "brak" then noOrderNpcs[#noOrderNpcs + 1] = { npc = order.npc, lastSeen = order.lastSeen } end
    end

    if #orders == 0 and #noOrderNpcs == 0 then
        le.zlecenia.output("Nie masz aktualnie żadnych zleceń.")
        return
    end

    le.zlecenia.output("Twoje zlecenia:")
    le.zlecenia.indexMap = {}
    for i, order in ipairs(orders) do
        le.zlecenia.indexMap[i] = order.key
        local remaining = (order.completionAt or 0) - epoch()
        decho(string.format("%s %s %s\n", dc(col.good, i .. "."), dc(col.npc, order.npc), dc(col.muted, "— " .. (order.type or "-"))))
        decho(string.format("   %s %s\n", dc(col.label, "Potrzebuje:"), dc(col.value, order.what or "-")))
        decho(string.format("   %s %s ", dc(col.label, "Gdzie:"), dc(col.npc, order.roomName or "-")))
        dechoLink(dc(col.value, "[trasa]"), string.format([[alias_func_prowadz(%s)]], tostring(order.roomID or "")), "Kliknij, aby wyznaczyć ścieżkę", true)
        decho("\n")
        decho(string.format("   %s %s %s ", dc(col.label, "Czas:"), dc(le.zlecenia.urgency_color(remaining), "za " .. le.zlecenia.duration(remaining)), dc(col.muted_dim, "(koniec ok. " .. os.date("%H:%M %d-%m-%Y", order.completionAt or epoch()) .. ")")))
        dechoLink(dc(col.danger_link, "[usuń]"), string.format([[le.zlecenia.remove_by_index(%d)]], i), "Usuń to zlecenie", true)
        decho("\n\n")
    end

    for _, n in ipairs(noOrderNpcs) do
        decho(string.format("%s %s %s\n\n", dc(col.muted, n.npc), dc(col.muted, "— brak zlecenia"), dc(col.muted_dim, "(zapytano " .. (n.lastSeen or "-") .. ")")))
    end
end

function le.zlecenia.remove_by_index(index)
    local key = le.zlecenia.indexMap and le.zlecenia.indexMap[index]
    le.zlecenia.remove_order(key)
end

function le.zlecenia.remove_order(key)
    local order = key and le.zlecenia.data.orders[key]
    if order then
        if le.zlecenia.UI.routingKey == key then
            pcall(alias_func_prowadz_stop)
            le.zlecenia.UI.routingKey = nil
        end
        le.zlecenia.data.orders[key] = nil
        le.zlecenia.save()
        le.zlecenia.output(string.format("Zlecenie od %s zostało usunięte.", dc(le.zlecenia.config.colors.npc, order.npc)))
    else
        le.zlecenia.output("Nie znaleziono zlecenia do usunięcia.")
    end
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.reset_all()
    le.zlecenia.data.orders = {}
    le.zlecenia.save()
    le.zlecenia.output(dc(le.zlecenia.config.colors.urgent_high, "Wszystkie zlecenia zostały usunięte."))
    le.zlecenia.UI.rebuild()
end

-- Panel na ekranie (Geyser), pod modułami czasu UNICORN -----------------------
-- Etykiety Geyser renderują Qt rich text (podzbiór HTML4/CSS2): brak
-- flexbox/grid/position/transform. Justowanie dwóch kolumn -> <table>.
-- Mini-przyciski trasy/usuwania to osobne małe etykiety nałożone na kartę,
-- każda z własnym setClickCallback (jedna etykieta = jeden klik).

function le.zlecenia.UI.order_html(order, expanded)
    local col = le.zlecenia.config.colors
    local remaining = math.max(0, (order.completionAt or 0) - epoch())
    local urgency = le.zlecenia.urgency_color(remaining)
    local function esc(value)
        return tostring(value or "-")
            :gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    end

    local html = string.format([[<table width='100%%' cellspacing='0' cellpadding='0'><tr>
        <td align='left'><span style='font-size:10px;color:%s;%s'>%s</span></td>
        <td align='right'><span style='font-size:10px;color:%s;font-weight:bold'>%s</span></td>
      </tr></table>]],
        col.text, expanded and "font-weight:bold" or "", esc(order.what),
        urgency, le.zlecenia.compact_duration(remaining))

    if expanded then
        html = html .. string.format([[
          <div style='height:8px'></div>
          <div style='font-size:10px;color:%s'>Odbiorca: <span style='color:%s'>%s</span></div>
          <div style='font-size:10px;color:%s'>Miejsce: <span style='color:%s'>%s</span></div>
          <div style='font-size:10px;color:%s'>Pozostało: <span style='color:%s;font-weight:bold'>%s</span></div>]],
            col.muted, col.text, esc(order.npc),
            col.muted, col.text, esc(order.roomName),
            col.muted, urgency, le.zlecenia.duration(remaining))
    end
    return html
end

function le.zlecenia.UI.ensure_pool()
    if le.zlecenia.UI.pool then return end
    le.zlecenia.UI.pool, le.zlecenia.UI.routeBtn, le.zlecenia.UI.deleteBtn, le.zlecenia.UI.slotOrder = {}, {}, {}, {}
    local p = le.zlecenia.config.panel
    local col = le.zlecenia.config.colors

    le.zlecenia.UI.header = Geyser.Label:new({
        name = "LeZleceniaHeader", x = p.x, y = tostring(p.top) .. "px",
        width = tostring(p.width) .. "px", height = tostring(p.headerHeight) .. "px"
    })
    le.zlecenia.UI.header:setStyleSheet(string.format([[
        background-color: rgba(12, 14, 18, 220);
        border:none; border-left:3px solid %s; padding:2px 8px;
        font-family:'DejaVu Sans Mono','Consolas',monospace;
    ]], col.accent))
    le.zlecenia.UI.header:setClickCallback(function() le.zlecenia.UI.toggle_panel() end)

    for i = 1, p.maxItems do
        local slot = i
        local label = Geyser.Label:new({
            name = "LeZleceniaItem" .. slot, x = p.x, y = "0px",
            width = tostring(p.width) .. "px", height = tostring(p.itemHeight) .. "px"
        })
        label:setStyleSheet(le.zlecenia.config.style)
        label:hide()
        label:setClickCallback(function()
            local order = le.zlecenia.UI.slotOrder[slot]
            if order then le.zlecenia.UI.toggle(order.key) end
        end)
        le.zlecenia.UI.pool[slot] = label
    end

    for i = 1, p.maxItems do
        local slot = i
        local route = Geyser.Label:new({
            name = "LeZleceniaRoute" .. slot, x = "0px", y = "0px",
            width = tostring(p.routeWidth) .. "px", height = tostring(p.actionHeight) .. "px"
        })
        route:setStyleSheet(le.zlecenia.config.btnStyle)
        route:hide()
        route:setClickCallback(function()
            local order = le.zlecenia.UI.slotOrder[slot]
            if order then le.zlecenia.UI.toggle_route(order) end
        end)
        le.zlecenia.UI.routeBtn[slot] = route

        local delete = Geyser.Label:new({
            name = "LeZleceniaDelete" .. slot, x = "0px", y = "0px",
            width = tostring(p.deleteWidth) .. "px", height = tostring(p.actionHeight) .. "px"
        })
        delete:setStyleSheet(le.zlecenia.config.btnStyle)
        delete:hide()
        delete:setClickCallback(function()
            local order = le.zlecenia.UI.slotOrder[slot]
            if order then le.zlecenia.remove_order(order.key) end
        end)
        le.zlecenia.UI.deleteBtn[slot] = delete
    end
end

function le.zlecenia.UI.toggle(key)
    -- (uwaga: "cond and nil or key" jest tu bugiem — and/nil zawsze spada na key)
    if le.zlecenia.UI.expandedKey == key then
        le.zlecenia.UI.expandedKey = nil
    else
        le.zlecenia.UI.expandedKey = key
    end
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.UI.collapse_all()
    le.zlecenia.UI.expandedKey = nil
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.UI.toggle_panel()
    le.zlecenia.UI.panelHidden = not le.zlecenia.UI.panelHidden
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.UI.toggle_route(order)
    if le.zlecenia.UI.routingKey == order.key then
        pcall(alias_func_prowadz_stop)
        le.zlecenia.UI.routingKey = nil
    else
        if le.zlecenia.UI.routingKey then pcall(alias_func_prowadz_stop) end
        pcall(alias_func_prowadz, order.roomID)
        le.zlecenia.UI.routingKey = order.key
    end
    le.zlecenia.UI.rebuild()
end

function le.zlecenia.UI.rebuild()
    le.zlecenia.UI.ensure_pool()
    local p = le.zlecenia.config.panel
    local col = le.zlecenia.config.colors
    local orders = le.zlecenia.active_orders_sorted()

    if #orders == 0 then
        le.zlecenia.UI.header:hide()
        for _, label in ipairs(le.zlecenia.UI.pool) do label:hide() end
        for _, button in ipairs(le.zlecenia.UI.routeBtn) do button:hide() end
        for _, button in ipairs(le.zlecenia.UI.deleteBtn) do button:hide() end
        return
    end

    le.zlecenia.UI.header:move(p.x, tostring(p.top) .. "px")
    le.zlecenia.UI.header:echo(string.format([[<table width='100%%' cellspacing='0' cellpadding='0'><tr>
        <td align='left'><span style='font-size:10px;color:%s;letter-spacing:1px'>ZLECENIA</span></td>
        <td align='right'><span style='font-size:10px;color:%s;font-weight:bold'>%d</span></td>
      </tr></table>]], col.accent, col.accent, #orders))
    le.zlecenia.UI.header:show()

    if le.zlecenia.UI.panelHidden then
        for _, label in ipairs(le.zlecenia.UI.pool) do label:hide() end
        for _, button in ipairs(le.zlecenia.UI.routeBtn) do button:hide() end
        for _, button in ipairs(le.zlecenia.UI.deleteBtn) do button:hide() end
        return
    end

    local rightOffset = tonumber((p.x:gsub("px", ""))) + p.width
    local deleteX = rightOffset - p.deleteWidth - p.btnMargin
    local routeX = deleteX - p.routeWidth - 12
    local y = p.top + p.headerHeight

    for i, order in ipairs(orders) do
        if i > p.maxItems then break end
        le.zlecenia.UI.slotOrder[i] = order
        local expanded = le.zlecenia.UI.expandedKey == order.key
        local height = expanded and (p.itemHeight + p.expandedExtra) or p.itemHeight
        local label = le.zlecenia.UI.pool[i]
        label:move(p.x, tostring(y) .. "px")
        label:resize(tostring(p.width) .. "px", tostring(height) .. "px")
        label:echo(le.zlecenia.UI.order_html(order, expanded))
        label:show()

        local route = le.zlecenia.UI.routeBtn[i]
        local delete = le.zlecenia.UI.deleteBtn[i]
        if expanded then
            local actionY = y + height - p.actionHeight - 6
            local routing = le.zlecenia.UI.routingKey == order.key
            route:move(tostring(routeX) .. "px", tostring(actionY) .. "px")
            route:echo(string.format("<span style='font-size:10px;color:%s;font-weight:bold'>%s</span>",
                col.good, routing and "ZATRZYMAJ" or "PROWADŹ"))
            route:show()

            delete:move(tostring(deleteX) .. "px", tostring(actionY) .. "px")
            delete:echo(string.format("<span style='font-size:10px;color:%s;font-weight:bold'>USUŃ</span>", col.danger_link))
            delete:show()
        else
            route:hide()
            delete:hide()
        end
        y = y + height
    end

    for i = math.min(#orders, p.maxItems) + 1, p.maxItems do
        le.zlecenia.UI.slotOrder[i] = nil
        le.zlecenia.UI.pool[i]:hide()
        le.zlecenia.UI.routeBtn[i]:hide()
        le.zlecenia.UI.deleteBtn[i]:hide()
    end
end

-- Triggery gry --------------------------------------------------------------

function le.zlecenia.setup_triggers()
    le.zlecenia.triggers = le.zlecenia.triggers or {}
    le.zlecenia.triggers.brak = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Nie, w tej chwili niczego mi nie trzeba\\. Zajrzyj moze za jakis czas\\.$",
        [[le.zlecenia.handle_no_order()]]
    )
    le.zlecenia.triggers.nowe = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Tak, mam pewne pilne zamowienie na (\\w+)\\. Potrzebuje (.+)\\. Dobrze zaplace.*$",
        [[le.zlecenia.handle_new_order()]]
    )
    le.zlecenia.triggers.czas = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Na realizacje zamowienia mam (.+), pozniej zapewne bede potrzebowac czego innego\\.$",
        [[le.zlecenia.handle_order_time()]]
    )
    le.zlecenia.triggers.ukonczone = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Dziekuje, wiecej mi juz nie trzeba\\.$",
        [[le.zlecenia.handle_order_completed()]]
    )
    le.zlecenia.triggers.czesciowe = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Dziekuje, potrzebuje jeszcze (.+)\\.$",
        [[le.zlecenia.handle_partial_order()]]
    )

    -- Warianty "gnomiej mowy": ta sama struktura zdania, ale bez spacji
    -- (prefiks "... do ciebie:" zostaje normalny, tylko treść jest zlepiona).
    le.zlecenia.triggers.brak_gnom = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Nie,wtejchwiliniczegominietrzeba\\.Zajrzyjmozezajakiscczas\\.$",
        [[le.zlecenia.handle_no_order()]]
    )
    le.zlecenia.triggers.nowe_gnom = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Tak,mampewnepilnezamowienienam*na(\\w+)\\.Potrzebuje(.+)\\.Dobrzezaplace.*$",
        [[le.zlecenia.handle_new_order_gnome()]]
    )
    le.zlecenia.triggers.czas_gnom = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Narealizacjezamowieniamam(.+),pozniejzapewnebedepotrzebowacczegoinnego\\.$",
        [[le.zlecenia.handle_order_time_gnome()]]
    )
    le.zlecenia.triggers.ukonczone_gnom = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Dziekuje,wiecejmijuznietrzeba\\.$",
        [[le.zlecenia.handle_order_completed()]]
    )
    le.zlecenia.triggers.czesciowe_gnom = tempRegexTrigger(
        "^(.+)\\s+\\w+\\s+do\\s+ciebie:\\s+Dziekuje,potrzebujejeszcze(.+)\\.$",
        [[le.zlecenia.handle_partial_order_gnome()]]
    )
end

-- Aliasy: /le.zlecenia ... ---------------------------------------------

function le.zlecenia.setup_aliases()
    le.zlecenia.aliases = le.zlecenia.aliases or {}
    le.zlecenia.aliases.help = tempAlias("^/le\\.zlecenia$", [[le.zlecenia.show_help()]])
    le.zlecenia.aliases.list = tempAlias("^/le\\.zlecenia lista$", [[le.zlecenia.show_list()]])
    le.zlecenia.aliases.check = tempAlias("^/le\\.zlecenia sprawdz$", [[
        send("zapytaj mezczyzne o zlecenie", false)
        send("zapytaj kobiete o zlecenie", false)
    ]])
    le.zlecenia.aliases.remove = tempAlias("^/le\\.zlecenia usun (\\d+)$", [[le.zlecenia.remove_by_index(tonumber(matches[2]))]])
    le.zlecenia.aliases.reset = tempAlias("^/le\\.zlecenia reset$", [[le.zlecenia.reset_all()]])
    le.zlecenia.aliases.learn = tempAlias("^/le\\.zlecenia slowo (.+)$", [[le.zlecenia.learn_word_manual(matches[2])]])
end

function le.zlecenia.learn_word_manual(word)
    word = word:lower():gsub("%s+", "")
    if word == "" then return end
    le.zlecenia.data.vocab = le.zlecenia.data.vocab or {}
    le.zlecenia.data.vocab[word] = true
    le.zlecenia.save()
    le.zlecenia.output(string.format("Dodano %s do słownika gnomiej mowy.", dc(le.zlecenia.config.colors.good, word)))
end

-- Cykl życia ----------------------------------------------------------------

function le.zlecenia.cleanup()
    if le.zlecenia.timer then pcall(killTimer, le.zlecenia.timer); le.zlecenia.timer = nil end
    if le.zlecenia.exit_handler then pcall(killAnonymousEventHandler, le.zlecenia.exit_handler); le.zlecenia.exit_handler = nil end
    if le.zlecenia.aliases then for _, id in pairs(le.zlecenia.aliases) do pcall(killAlias, id) end end
    if le.zlecenia.triggers then for _, id in pairs(le.zlecenia.triggers) do pcall(killTrigger, id) end end
    if le.zlecenia.UI.header then le.zlecenia.UI.header:hide() end
    if le.zlecenia.UI.footer then le.zlecenia.UI.footer:hide() end
    if le.zlecenia.UI.pool then for _, label in ipairs(le.zlecenia.UI.pool) do label:hide() end end
    if le.zlecenia.UI.routeBtn then for _, b in ipairs(le.zlecenia.UI.routeBtn) do b:hide() end end
    if le.zlecenia.UI.deleteBtn then for _, b in ipairs(le.zlecenia.UI.deleteBtn) do b:hide() end end
    if le.zlecenia.UI.routingKey then pcall(alias_func_prowadz_stop) end
    end

function le.zlecenia.init()
    le.zlecenia.cleanup()
    le.zlecenia.load()
    le.zlecenia.setup_triggers()
    le.zlecenia.setup_aliases()
    le.zlecenia.exit_handler = registerAnonymousEventHandler("sysExitEvent", le.zlecenia.save)
    le.zlecenia.timer = tempTimer(le.zlecenia.config.check_interval, function()
        le.zlecenia.check_expired()
        le.zlecenia.UI.rebuild()
    end, true)
    le.zlecenia.UI.rebuild()
    le.zlecenia.output("Moduł zleceń załadowany · /le.zlecenia")
end

le.zlecenia.init()

