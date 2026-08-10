# UNICORN

Niezależna konfiguracja i zestaw pluginów dla Mudleta.

## Wymagania

- Mudlet
- konfiguracja Arkadia ze wsparciem komendy `/zainstaluj_plugin`

## Instalacja

Po udostępnieniu repozytorium wykonaj w Mudlecie:

```text
/zainstaluj_plugin https://raw.githubusercontent.com/gnomidlo/Arka/main/dist/UNICORN.zip?version=0.5.1
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
/zainstaluj_plugin https://raw.githubusercontent.com/gnomidlo/Arka/main/dist/UNICORN.zip?version=0.5.1
```

Od wersji `0.2.0` plugin jest instalowany i wyswietlany na liscie jako `UNICORN`. Paczka ma pliki bezposrednio w katalogu glownym ZIP-a, zgodnie z formatem instalatora Arkadii.

## Komendy

```text
/le.config
/le.config wersja
/le.config aktualizacja
/le.config aktualizuj
/le.config napraw
/le.czas
/le.kal [liczba]
/le.kal tydzien
/le.lecz
/le.lecz <kategoria>
/le.zlecenia
/le.zlecenia lista
/le.zlecenia sprawdz
/le.mowa
/le.mowa ustaw
/le.mowa podglad
```

- `/le.config` — pomoc konfiguracji `le.conf`,
- `/le.config wersja` — pokazuje wersje lokalna,
- `/le.config aktualizacja` — sprawdza nowsza wersje na GitHubie,
- `/le.config aktualizuj` — instaluje wykryta aktualizacje bez tworzenia nowej instancji,
- `/le.config napraw` — usuwa pozostawione katalogi instalatora i duplikaty UNICORN,
- `/le.czas` — pomoc zegara i synchronizacji,
- `/le.kal` — jednoliniowa lista najbliższych wydarzen z obu domen,
- `/le.kal tydzien` — agenda wydarzen na najblizsze 7 dni,
- `/le.lecz` — pomoc i klikalne kategorie leczenia,
- `/le.lecz <kategoria>` — lista ziół dla wybranej przypadłości,
- `/le.zlecenia` — pomoc modułu dostaw od NPC,
- `/le.zlecenia lista` — szczegółowa lista aktywnych dostaw,
- `/le.zlecenia sprawdz` — pyta NPC o dostępne zlecenie,
- `/le.mowa` — pomoc modułu oznaczania wypowiedzi,
- `/le.mowa ustaw` — wysyła ustawienia kolorów: mowa 153, szept 160, krzyk 117,
- `/le.mowa podglad` — pokazuje podgląd trzech kolorów belki.

Komendy wyswietlane w pomocy modulow sa klikalne. Szablony wymagajace parametrow w `/le.czas` uzupelniaja linie polecen zamiast wykonywac niepelna komende.

### Synchronizacja czasu

Moduł nie wysyła żadnych komend. Gdy użytkownik wpisze w grze `czas`, moduł odczytuje odpowiedź i synchronizuje lub aktualizuje zegar właściwej domeny. Obsługiwane są zarówno dokładne godziny i numery dni, jak i starszy format opisowy — dla pór Starszego Ludu oraz miesięcy Kalendarza Imperialnego. Moduł nie wymaga ręcznej synchronizacji.

## Struktura pluginu

- `init.lua` — punkt wejścia pluginu `UNICORN`,
- `le/config.lua` — moduł pomocy i alias `/le.config`,
- `le/czas.lua` — niezależny zegar, kalendarz, wydarzenia i interfejs,
- `le/lecz.lua` — dobór ziół i klikalne leczenie,
- `le/zlecenia.lua` — dostawy od NPC, zapis terminów i panel Geyser,
- `le/mowa.lua` — oznaczanie mowy, szeptu i krzyku na podstawie kolorów ANSI 256.



## Kalendarz

Zwykly widok kalendarza pokazuje kazde wydarzenie w jednej, wyrownanej linii:

```text
ZA 02h 14m | ISHTAR   | Poczatek pelni              | pn  10 sierpnia | 21:34
ZA 05h 48m | IMPERIUM | Poczatek nowiu              | wt  11 sierpnia | 01:08
```

Skroty dni zajmuja stale pole trzech znakow: `pn`, `wt`, `sr`, `czw`, `pt`, `sob`, `n`. Widok zawiera klikalne przejscie do agendy siedmiodniowej. Panel najblizszego wydarzenia pokazuje kolejno nazwe wydarzenia oraz `Imperium | zacznie sie za 02h 14m`.

## Leczenie

Po wpisaniu w grze `stan` modul dopisuje pod rozpoznanym zatruciem, choroba lub pasozytami pasujace ziola. Klikniecie nazwy ziola wykonuje `/wezz`, a klikniecie sposobu uzycia opuszcza bron i uruchamia odpowiedni alias `/z_...`.

Informacje o posiadanych ziolach pochodza z globalnej bazy `herbs.counts`, budowanej komenda `/ziola_buduj`. Kategorie sa pogrupowane jako: toksyny, choroby, inne oraz odtrutki ogolne. Dawne skroty kategorii nadal dzialaja.


## Mowa

Moduł rozpoznaje wypowiedzi po kolorach ustawionych w grze i dodaje przed linią wyłącznie cienką belkę. Mowa, szept i krzyk mają trzy spokojne warianty koloru; treść wypowiedzi i jej kolor pozostają bez zmian.

Kliknięcie `/le.mowa ustaw` w pomocy wysyła kolejno:

```text
ustaw kolor mowy 153
kolor szeptu 160
ustaw kolor krzyku 117
```

Mudlet raportuje te ustawienia jako indeksy ANSI odpowiednio 152, 159 i 116. Moduł używa triggerów ANSI 256 oraz zapasowych triggerów tekstowych dla czasowników mowy, więc nie wymaga importowania osobnego pakietu XML.

## Terminy zleceń

Czas podawany przez NPC jest liczony zegarem świata gry. Jedna godzina gry trwa 120 sekund rzeczywistych, dlatego `dzien` oznacza 24 godziny gry, czyli 2880 sekund — 48 minut rzeczywistych. Liczebniki słowne i cyfrowe są obsługiwane dla dni, godzin i minut gry. Jeśli termin jest nieznany, moduł wyświetla ostrzeżenie i przyjmuje jeden dzień gry zamiast jednej godziny.

## Wersje i aktualizacje

Aktualna wersja projektu jest zapisana w `version.lua`. Przed opublikowaniem nowej wersji nalezy podbic ten numer zgodnie z formatem `MAJOR.MINOR.PATCH`.

Sprawdzanie wersji uruchamia sie automatycznie 6 sekund po zaladowaniu pluginu i korzysta z zadania HTTP bez plikow tymczasowych. Instalacja aktualizacji jest wykonywana dopiero po swiadomym wywolaniu `/le.config aktualizuj`. Od wersji `0.3.1` paczka jest rozpakowywana poza katalogiem pluginow, weryfikowana i kopiowana bezposrednio do `plugins/UNICORN`, dlatego instalator nie tworzy katalogow o nazwach typu `1786310551UNICORN`.

`/le.config napraw` usuwa pozostalosci `UNICORN_todelete` oraz katalogi tymczasowe zakonczone nazwa `UNICORN`. Jesli system blokuje usuniecie, katalog jest przenoszony poza `plugins`, aby loader nie traktowal go jako pluginu. Po aktualizacji lub naprawie nalezy zrestartowac Mudlet.


## Interfejs 0.5.1

UNICORN używa jednego minimalistycznego systemu wizualnego. Komunikaty konsoli zaczynają się od cienkiej belki w kolorze modułu, na przykład:

```text
▎  Zapisano świt · Imperium · Sommerzeit · 03:22
▎  Dodano zlecenie · 80 kg mięsa żubra
```

Panel boczny nie używa ikon ani pełnych ramek. Moduły rozpoznaje się po kolorze lewej krawędzi:

- cyjan — czas,
- lawenda — kalendarz i wydarzenia,
- bursztyn — zlecenia,
- mięta — leczenie,
- chłodny błękit — mowa,
- przygaszona lawenda — szept,
- stonowany koral — krzyk.

Zegar pokazuje dużą, pogrubioną godzinę, domenę, porę roku i okres kalendarza oraz odliczanie do najbliższego świtu albo zmierzchu.

Zwarty panel zleceń pokazuje wyłącznie przedmiot, ilość i pozostały czas. Kliknięcie dostawy rozwija odbiorcę, miejsce oraz tekstowe akcje `PROWADŹ` i `USUŃ`.
