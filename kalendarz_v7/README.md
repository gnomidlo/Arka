# Kalendarz 7.0 (propozycja przebudowy)

Ten katalog zawiera nowy, modularny szkielet kalendarza Arkadii. Głównym celem jest rozdzielenie logiki od danych domenowych, ułatwienie edycji świąt i zmniejszenie ryzyka błędnej synchronizacji przy logowaniu oraz przy zmianie domen.

## Struktura

- `init.lua` – plik startowy do wczytania w Mudlecie.
- `core.lua` – logika obliczeń, synchronizacji i obsługi GMCP.
- `modules/utils.lua` – helpery (czas, formatowanie, union tabel).
- `modules/domains/imperial.lua` – dane domeny Imperium (miesiące/święta/słońce).
- `modules/domains/ishtar.lua` – dane domeny Ishtar (miesiące/święta/słońce).

## Kluczowe zmiany w logice GMCP

1. **Ignorowanie pierwszego pakietu gmcp.room.time po logowaniu** – pierwszy status dnia/nocy traktujemy jako stan bazowy, nie jako świt/zmierzch.
2. **Ochrona przy zmianie domeny** – przez kilka sekund po wykryciu nowej domeny blokujemy synchronizację, bo gmcp często wysyła tylko aktualny stan dnia/nocy.
3. **Stan dzien/noc per domena** – zapamiętujemy ostatni status osobno dla każdej domeny.

## Edycja świąt

Święta i wydarzenia znajdują się w:
- `modules/domains/imperial.lua` → `config.search_times`
- `modules/domains/ishtar.lua` → `config.search_times`

Możesz je dopisywać/usuwać bez dotykania logiki w `core.lua`.

## Instalacja (skrót)

1. Skopiuj katalog `kalendarz_v7` do `getMudletHomeDir()`.
2. W Mudlecie dodaj nowy skrypt, który wywołuje `dofile(getMudletHomeDir() .. "/kalendarz_v7/init.lua")`.
3. Zadbaj o istniejące aliasy/triggerów – logika w `core.lua` pozostaje kompatybilna z dotychczasową składnią wywołań.
