-- le.patchnotes: krótkie informacje o zmianach w kolejnych wydaniach UNICORN.

le = le or {}
le.patchnotes = le.patchnotes or {}

-- To jest źródło prawdy dla mini patch notes. Każde wydanie zmieniające kod
-- lub zachowanie pluginu musi dostać tutaj krótki, użytkowy opis zmian.
le.patchnotes.notes = {
    ["0.8.8"] = {
        "Panel zleceń przeniesiono do osobnego przesuwanego okna Mudleta.",
        "Kliknięcie zlecenia po aktualizacji ponownie rozwija szczegóły i przyciski PROWADŹ/USUŃ.",
        "Przeładowanie usuwa stare etykiety i ich callbacki, zachowując zapisane zlecenia.",
    },
    ["0.8.7"] = {
        "Aktualizator nie usuwa już starych kopii UNICORN przed instalacją nowej wersji.",
        "Jeśli poprzednia kopia istnieje lub jest zablokowana, wybierana jest nowa, wolna nazwa kopii.",
        "Poprzednie wersje pozostają nietknięte także przy błędzie instalacji.",
    },
    ["0.8.6"] = {
        "Zegar, pasek online i najbliższe wydarzenie przeniesiono do przesuwanego okna z przezroczystym tłem.",
        "Zachowano położenie okna podczas przeładowania; starszy Mudlet nadal używa dotychczasowych etykiet.",
        "Komunikaty zleceń i innych modułów nie doklejają się już do wypowiedzi NPC.",
    },
    ["0.8.5"] = {
        "Belki mowy wymagają teraz zgodnego koloru i słowa opisującego wypowiedź przed dwukropkiem.",
        "Opisy walki i umiejętności nie otrzymują belek tylko dlatego, że mają ten sam kolor.",
        "Mowa, szept i krzyk mają właściwy rodzaj belki także przy wspólnym kolorze gry.",
    },
    ["0.8.4"] = {
        "Oznaczanie mowy odczytuje Twoje kolory po ręcznym wpisaniu kolory w grze.",
        "Moduł nie zmienia kolorów w grze; zachowuje dwie dotychczasowe belki.",
        "Brakujące lub błędne kolory wyłączają oznaczanie odpowiedniego rodzaju wypowiedzi.",
    },
    ["0.8.3"] = {
        "Naprawiono synchronizację zegara w jednodniowe święta Kalendarza Imperialnego, m.in. Mitterherbst i Geheimnistag.",
        "Komenda czas poprawnie ustawia teraz godzinę także dla wpisów w formacie \"dzien <swieto>\".",
    },
    ["0.8.2"] = {
        "Aktualizator sprawdza paczkę przed instalacją i zachowuje poprzednią wersję na wypadek błędu.",
        "Zapis zegara, czasu online i zleceń korzysta z pliku tymczasowego oraz kopii zapasowej.",
        "Wygasłe zlecenia nie zwiększają liczby wykonanych dostaw; błędy prowadzenia są zgłaszane.",
        "Porady o leczeniu bez ziół działają także bez wczytanej bazy ziół.",
        "Zegar odświeża etykiety tylko po zmianie ich treści i sprawniej wybiera najbliższe wydarzenie.",
    },
    ["0.8.1"] = {
        "Tygodniowy pasek online wypełnia szerokość panelu zegara z małymi marginesami.",
        "Długość paska dopasowuje się do szerokości panelu i czcionki, zachowując dotychczasowy wygląd.",
    },
    ["0.8.0"] = {
        "Aktualizacje UNICORN przeładowują moduły bez restartu Mudleta.",
        "Naprawiono widoczność tygodniowego paska online pod zegarem.",
        "Dodano krótkie patch notes wyświetlane razem z informacją o wersji.",
    },
    ["0.7.1"] = {
        "Zegar odświeża się po \"czas\" i GMCP oraz potrafi odtworzyć zatrzymany timer.",
        "Tygodniowy pasek online przeniesiono bezpośrednio pod godzinę.",
    },
}

function le.patchnotes.get(version)
    return le.patchnotes.notes[tostring(version or le.version or "")]
end

function le.patchnotes.show(version)
    version = tostring(version or le.version or "nieznana")
    local notes = le.patchnotes.get(version)
    if not notes or #notes == 0 then return false end

    if le.ui and le.ui.output then
        le.ui.output("config", "UNICORN " .. version .. " · zmiany")
        for _, item in ipairs(notes) do
            if le.ui.note then
                le.ui.note("config", "• " .. item)
            else
                le.ui.output("config", "• " .. item)
            end
        end
    else
        cecho("\n<light_pink>▎<reset>  UNICORN " .. version .. " · zmiany\n")
        for _, item in ipairs(notes) do
            cecho("<grey>   • " .. tostring(item) .. "<reset>\n")
        end
    end
    return true
end

return le.patchnotes
