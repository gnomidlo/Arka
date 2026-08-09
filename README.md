# UNICORN

Niezależna konfiguracja i zestaw pluginów dla Mudleta.

## Wymagania

- Mudlet
- konfiguracja Arkadia ze wsparciem komendy `/zainstaluj_plugin`

## Instalacja

Po udostępnieniu repozytorium wykonaj w Mudlecie:

```text
/zainstaluj_plugin https://raw.githubusercontent.com/gnomidlo/Arka/main/dist/UNICORN.zip?version=0.2.2
```

Po instalacji sprawdź listę pluginów:

```text
/plugins
```

Plugin powinien pojawić się na liście jako `UNICORN`.

Po pierwszej instalacji pliki sa juz na dysku, ale plugin moze nie byc jeszcze widoczny w `/plugins`. To ograniczenie instalatora Arkadii. Zrestartuj Mudlet, aby standardowy loader dodal `UNICORN` do listy i uruchomil wszystkie aliasy.

### Przejscie z poprzedniej nazwy

Zmiana nazwy pluginu wymaga jednorazowego usuniecia starego katalogu. Zamknij Mudlet, usun katalog `plugins/Arka`, uruchom Mudlet i zainstaluj nowa paczke:

```text
/zainstaluj_plugin https://raw.githubusercontent.com/gnomidlo/Arka/main/dist/UNICORN.zip?version=0.2.2
```

Od wersji `0.2.0` plugin jest instalowany i wyswietlany na liscie jako `UNICORN`. Paczka ma pliki bezposrednio w katalogu glownym ZIP-a, zgodnie z formatem instalatora Arkadii.

## Komendy

```text
/le.config
/le.config wersja
/le.config aktualizacja
/le.config aktualizuj
/le.czas
/le.kal [liczba]
/le.kal tydzien
```

- `/le.config` — pomoc konfiguracji `le.conf`,
- `/le.config wersja` — pokazuje wersje lokalna,
- `/le.config aktualizacja` — sprawdza nowsza wersje na GitHubie,
- `/le.config aktualizuj` — instaluje wykryta aktualizacje,
- `/le.czas` — pomoc zegara i synchronizacji,
- `/le.kal` — jednoliniowa lista najbliższych wydarzen z obu domen,
- `/le.kal tydzien` — agenda wydarzen na najblizsze 7 dni.

### Synchronizacja czasu

Moduł nie wysyła żadnych komend. Gdy użytkownik wpisze w grze `czas`, moduł odczytuje odpowiedź i synchronizuje lub aktualizuje zegar właściwej domeny. Obsługiwane są zarówno dokładne godziny i numery dni, jak i starszy format opisowy — dla pór Starszego Ludu oraz miesięcy Kalendarza Imperialnego. `/le.czas sync` pozostaje awaryjną możliwością ręcznej korekty.

## Struktura pluginu

- `init.lua` — punkt wejścia pluginu `UNICORN`,
- `le/config.lua` — moduł pomocy i alias `/le.config`,
- `le/czas.lua` — niezależny zegar, kalendarz, wydarzenia i interfejs.



## Kalendarz

Zwykly widok kalendarza pokazuje kazde wydarzenie w jednej, wyrownanej linii:

```text
ZA 02h 14m | ISHTAR   | Poczatek pelni              | pn  10 sierpnia | 21:34
ZA 05h 48m | IMPERIUM | Poczatek nowiu              | wt  11 sierpnia | 01:08
```

Skroty dni zajmuja stale pole trzech znakow: `pn`, `wt`, `sr`, `czw`, `pt`, `sob`, `n`. Widok zawiera klikalne przejscie do agendy siedmiodniowej.


## Wersje i aktualizacje

Aktualna wersja projektu jest zapisana w `version.lua`. Przed opublikowaniem nowej wersji nalezy podbic ten numer zgodnie z formatem `MAJOR.MINOR.PATCH`.

Sprawdzanie wersji uruchamia sie automatycznie 6 sekund po zaladowaniu pluginu i korzysta z zadania HTTP bez plikow tymczasowych. Instalacja aktualizacji jest wykonywana dopiero po swiadomym wywolaniu `/le.config aktualizuj` i pobiera przygotowane archiwum `dist/UNICORN.zip`. Po aktualizacji nalezy zrestartowac Mudlet.
