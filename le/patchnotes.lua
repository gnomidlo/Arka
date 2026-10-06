-- le.patchnotes: krótkie informacje o zmianach w kolejnych wydaniach UNICORN.

le = le or {}
le.patchnotes = le.patchnotes or {}

-- To jest źródło prawdy dla mini patch notes. Każde wydanie zmieniające kod
-- lub zachowanie pluginu musi dostać tutaj krótki, użytkowy opis zmian.
le.patchnotes.notes = {
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
