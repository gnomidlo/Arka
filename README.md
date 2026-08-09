# Arka

Niezależna konfiguracja i zestaw pluginów dla Mudleta.

## Wymagania

- Mudlet
- konfiguracja Arkadia ze wsparciem komendy `/zainstaluj_plugin`

## Instalacja

Po udostępnieniu repozytorium wykonaj w Mudlecie:

```text
/zainstaluj_plugin https://codeload.github.com/gnomidlo/Arka/zip/main?version=0.1.2
```

Po instalacji sprawdź listę pluginów:

```text
/plugins
```

Plugin powinien pojawić się na liście jako `Arka`.

Jeżeli aktualizacja z wersji `0.1.1` pozostawiła niepełny katalog pluginu, zamknij Mudlet i usuń ręcznie katalog `plugins/Arka` z katalogu profilu. Następnie uruchom Mudlet i wykonaj:

```text
/zainstaluj_plugin https://codeload.github.com/gnomidlo/Arka/zip/main?version=0.1.2
```

Od wersji `0.1.2` aktualizator nie korzysta z wadliwego usuwania katalogu przez instalator Arkadii. Przenosi poprzednią wersję poza katalog `plugins` jako `Arka_backup_<czas>`, a dopiero potem instaluje nowe pliki.

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

Moduł nie wysyła żadnych komend. Gdy użytkownik wpisze w grze `czas`, moduł odczytuje odpowiedź i synchronizuje lub aktualizuje zegar właściwej domeny. Obsługiwane są zarówno dokładne godziny i numery dni, jak i starszy format opisowy. `/le.czas sync` pozostaje awaryjną możliwością ręcznej korekty.

## Struktura pluginu

- `init.lua` — punkt wejścia dla loadera pluginów Arkadii,
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

Sprawdzanie wersji pobiera publiczny plik `version.lua` z galezi `main`. Instalacja aktualizacji jest wykonywana dopiero po swiadomym wywolaniu `/le.config aktualizuj`. Aktualizator najpierw przenosi poprzedni katalog `Arka` poza katalog pluginow jako kopie zapasowa, a nastepnie pobiera archiwum ZIP z parametrem wersji, aby instalator wgral rzeczywiscie nowe pliki.
