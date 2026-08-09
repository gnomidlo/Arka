# Arka

Niezależna konfiguracja i zestaw pluginów dla Mudleta.

## Wymagania

- Mudlet
- konfiguracja Arkadia ze wsparciem komendy `/zainstaluj_plugin`

## Instalacja

Po udostępnieniu repozytorium wykonaj w Mudlecie:

```text
/zainstaluj_plugin https://codeload.github.com/gnomidlo/Arka/zip/main
```

Po instalacji sprawdź listę pluginów:

```text
/plugins
```

Plugin powinien pojawić się na liście jako `Arka`.

## Komendy

```text
/le.config
/le.czas
/le.kal [liczba]
```

- `/le.config` — pomoc konfiguracji `le.conf`,
- `/le.czas` — pomoc zegara i synchronizacji,
- `/le.kal` — lista najbliższych wydarzeń z obu domen.

## Struktura pluginu

- `init.lua` — punkt wejścia dla loadera pluginów Arkadii,
- `le/config.lua` — moduł pomocy i alias `/le.config`,
- `le/czas.lua` — niezależny zegar, kalendarz, wydarzenia i interfejs.

