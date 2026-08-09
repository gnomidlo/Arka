# UNICORN

Niezależna konfiguracja i zestaw pluginów dla Mudleta.

## Wymagania

- Mudlet
- konfiguracja Arkadia ze wsparciem komendy `/zainstaluj_plugin`

## Instalacja

W Mudlecie wykonaj:

```text
/zainstaluj_plugin https://raw.githubusercontent.com/gnomidlo/Arka/main/dist/UNICORN.zip?version=0.3.0
```

Po pierwszej instalacji pliki są już na dysku, ale plugin może nie być jeszcze widoczny w `/plugins`. To ograniczenie instalatora Arkadii. Zrestartuj Mudlet, aby standardowy loader dodał `UNICORN` do listy i uruchomił wszystkie aliasy.

## Moduły

- `/le.config` — centrum pomocy, informacje o wersji i aktualizacje UNICORN.
- `/le.czas` — zegar i synchronizacja czasu dla obu domen.
- `/le.kal` — kalendarz wydarzeń oraz agenda najbliższych siedmiu dni.
- `/le.lecz` — dobór ziół do wykrytych zatruć, chorób i pasożytów.

Komendy wyświetlane w pomocy modułów są klikalne. Komendy wymagające parametrów w module czasu uzupełniają linię poleceń zamiast wykonywać niepełną operację.

## Komendy

```text
/le.config
/le.config wersja
/le.config aktualizacja
/le.config aktualizuj
/le.czas
/le.kal [liczba]
/le.kal tydzien
/le.lecz
/le.lecz <kategoria>
```

### Czas i kalendarz

Moduł nie wysyła samodzielnie komendy `czas`. Gdy użytkownik wpisze ją w grze, moduł odczytuje odpowiedź i synchronizuje lub aktualizuje zegar właściwej domeny. Obsługiwane są dokładne i opisowe godziny oraz kalendarze Starszego Ludu i Imperium.

Zwykły kalendarz pokazuje każde wydarzenie w jednej, wyrównanej linii. Skróty dni zajmują stałe pole trzech znaków: `pn`, `wt`, `sr`, `czw`, `pt`, `sob`, `n`.

Panel najbliższego wydarzenia pokazuje domenę przed odliczaniem:

```text
Imperium | zacznie sie za 02h 14m
```

### Leczenie

Po wpisaniu w grze `stan` moduł dopisuje pod rozpoznanym zatruciem, chorobą lub pasożytami pasujące zioła. Kliknięcie nazwy zioła wykonuje `/wezz`, a kliknięcie sposobu użycia opuszcza broń i uruchamia odpowiedni alias `/z_...`.

Informacje o posiadanych ziołach pochodzą z globalnej bazy `herbs.counts`, budowanej komendą `/ziola_buduj`.

## Struktura pluginu

- `init.lua` — punkt wejścia pluginu `UNICORN`,
- `version.lua` — numer aktualnej wersji,
- `le/config.lua` — pomoc, wersje i aktualizacje,
- `le/czas.lua` — zegar, kalendarz, wydarzenia i interfejs,
- `le/lecz.lua` — dobór ziół i klikalne leczenie,
- `dist/UNICORN.zip` — paczka instalacyjna.

## Wersje i aktualizacje

Sprawdzanie wersji uruchamia się automatycznie po załadowaniu pluginu. Instalacja aktualizacji następuje dopiero po użyciu `/le.config aktualizuj`. Po aktualizacji należy zrestartować Mudlet.
