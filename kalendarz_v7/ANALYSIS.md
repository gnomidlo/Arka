# Analiza problemów w obecnym skrypcie kalendarza

## 1. Rozjazd zegara IRL vs. czasu gry

W obecnej wersji synchronizacja jest wyzwalana za każdym razem, gdy status `gmcp.room.time.daylight` zmienia się lub pojawia się po raz pierwszy. Pierwsze zdarzenie po logowaniu lub po zmianie domeny nie jest świtem/zmierzchem, tylko *stanem początkowym* (dzień albo noc). To powoduje błędny offset i narastający drift, bo skrypt zakłada, że pierwsza informacja jest faktycznym wydarzeniem astronomicznym.

## 2. Sygnały GMCP przy zmianie domeny

Po wejściu do nowej domeny GMCP potrafi przesłać ponownie aktualny status dnia/nocy. W starszej logice każde takie zdarzenie mogło uruchamiać `recalibrate_by_event`, mimo że to nie jest prawdziwy świt/zmierzch. Taki „fałszywy” trigger zmienia offset i zniekształca obliczenia (szczególnie w dłuższych sesjach).

## 3. Przerost i brak modularności

Wszystkie dane domen (miesiące, święta, cykle słońca) są wstrzyknięte do jednego pliku z logiką obliczeń i GMCP. To utrudnia edycję wydarzeń oraz utrzymanie wielu kalendarzy. Najprostsze usprawnienie to podział na moduły domen (`imperial.lua`, `ishtar.lua`) i osobny rdzeń (`core.lua`).

## 4. Co powinno się zmienić

- **Ignorować pierwszą wartość GMCP** po logowaniu – traktować ją jako stan bazowy, nie jako event.
- **Ignorować krótkie „okno” po zmianie domeny** (np. 5 sekund), bo GMCP potrafi w tym czasie dosłać jedynie status dnia/nocy.
- **Prowadzić stan dzien/noc osobno dla każdej domeny**.
- **Rozdzielić dane świąt/kalendarzy od logiki**.

## 5. Uwaga o prędkości gry

Wartość `gamehour_real_time` powinna być okresowo aktualizowana na bazie rzeczywistych obserwacji świtu/zmierzchu. Dobrze działa podejście, które uśrednia wiele obserwacji i stosuje kalibrację dopiero, gdy mamy co najmniej dwa wiarygodne pomiary w jednym cyklu.
