# Instrukcje dla agentów — projekt UNICORN

## Cel dokumentu

Ten plik określa zasady pracy wszystkich agentów AI i współtwórców rozwijających projekt UNICORN, w tym Codex i Gemini. Obowiązuje w całym repozytorium, o ile plik `AGENTS.md` w katalogu podrzędnym nie zawiera bardziej szczegółowych instrukcji.

Przed rozpoczęciem pracy przeczytaj ten dokument w całości, sprawdź aktualny stan repozytorium oraz istniejące zmiany i pull requesty. Nie zakładaj, że opis wcześniejszej rozmowy odpowiada bieżącemu `main`.

## Cel i zakres projektu

UNICORN jest niezależnym pluginem i zestawem modułów Lua dla Mudleta, przeznaczonym do gry Arkadia. Projekt:

- korzysta z publicznych funkcji Mudleta, Geysera, GMCP oraz oficjalnej konfiguracji Arkadii;
- utrzymuje własną przestrzeń nazw `le.*`, własne pliki, interfejs, dane i cykl wydawniczy;
- może analizować i adaptować dozwolone rozwiązania z innych projektów, ale nie może wymagać `msmudlet` do działania;
- ma pozostać możliwy do zainstalowania, uruchomienia i aktualizowania jako samodzielny plugin `UNICORN`.

Nie dodawaj zależności od prywatnego stanu, kolejności inicjalizacji ani wewnętrznych funkcji `msmudlet`.

## Źródła prawdy i priorytety

Przy podejmowaniu decyzji stosuj następującą kolejność:

1. aktualne polecenie użytkownika;
2. ten plik i bardziej szczegółowe pliki `AGENTS.md`;
3. kod oraz dokumentacja znajdujące się na aktualnej gałęzi projektu;
4. oficjalna dokumentacja Mudleta i publiczne interfejsy oficjalnej konfiguracji Arkadii;
5. zewnętrzne projekty używane wyłącznie jako materiał referencyjny.

Jeżeli kod, README i opis zadania są ze sobą sprzeczne, nie zgaduj po cichu. Ustal zachowanie na podstawie działającego kodu i intencji użytkownika, a następnie ujednolić kod oraz dokumentację w tym samym zadaniu.

## Niezależność od msmudlet

Katalog oficjalnych skryptów `plugins/msmudlet/` jest zewnętrznym źródłem tylko do odczytu.

Wolno:

- czytać i analizować jego kod;
- poznawać formaty komunikatów, algorytmy, zdarzenia i zachowanie Arkadii;
- odtwarzać potrzebną mechanikę we własnym module UNICORN, jeśli pozwala na to licencja;
- korzystać z publicznych interfejsów Mudleta lub oficjalnej konfiguracji Arkadii.

Nie wolno:

- edytować, formatować, usuwać ani przenosić plików `msmudlet`;
- tworzyć w jego katalogu plików tymczasowych, testowych lub wygenerowanych;
- deklarować kodu UNICORN w przestrzeni nazw `Msmudlet.*`;
- nadpisywać funkcji, tabel, triggerów ani inicjalizacji `msmudlet`;
- uzależniać działania UNICORN od obecności lub konkretnej wersji `msmudlet`;
- naprawiać problemu przez lokalny monkey patch oficjalnego pakietu.

Jeśli potrzebna funkcja istnieje tylko w `msmudlet`, utwórz niezależną implementację w `le.*` albo adapter do publicznego interfejsu. Gdy nie jest to technicznie możliwe, opisz ograniczenie zamiast modyfikować oficjalne pliki.

## Integracja z oficjalną konfiguracją Arkadii

Preferuj istniejące, publiczne możliwości oficjalnej konfiguracji Arkadii zamiast ich ponownego implementowania. Dotyczy to szczególnie instalowania pluginów, nawigacji, publicznych aliasów, zdarzeń i udokumentowanych danych.

Integracja musi być odporna na brak opcjonalnej funkcji:

- przed wywołaniem opcjonalnego globalnego API sprawdź jego typ;
- używaj `pcall` tam, gdzie błąd zewnętrznego komponentu nie powinien zatrzymać UNICORN;
- zapewnij czytelny fallback albo komunikat o braku funkcji;
- nie zapisuj do tabel należących do oficjalnej konfiguracji, jeśli nie jest to częścią publicznego kontraktu.

## Architektura projektu

Punkt wejścia `init.lua` zwraca uporządkowaną listę modułów. Zachowaj kolejność zależności: wspólne podstawy muszą ładować się przed modułami, które z nich korzystają.

Główne elementy:

- `version.lua` — jedyne źródło numeru wersji;
- `le/ui.lua` — wspólny system wizualny, paleta i funkcje komunikatów;
- `le/config.lua` — pomoc, wersja, sprawdzanie i instalowanie aktualizacji;
- `le/czas.lua` — czas, kalendarz, wydarzenia i panel zegara;
- `le/lecz.lua` — obsługa leczenia i ziół;
- `le/zlecenia.lua` — dostawy od NPC, terminy, zapis danych i panel;
- `le/mowa.lua` — oznaczanie mowy, szeptu i krzyku;
- `dist/UNICORN.zip` — instalowalny artefakt wydania.

Nowy moduł umieszczaj jako `le/<nazwa>.lua`, deklaruj w `le.<nazwa>` i dopisuj do `init.lua` dopiero po sprawdzeniu jego inicjalizacji.

## Zasady modułów Lua

Każdy moduł powinien:

1. bezpiecznie utworzyć swoją tabelę w `le.*`;
2. przechowywać identyfikatory własnych triggerów, aliasów, timerów i handlerów;
3. mieć funkcję czyszczącą zasoby przed ponowną inicjalizacją;
4. pozwalać na ponowne załadowanie bez mnożenia triggerów i timerów;
5. ograniczać globalny stan do przestrzeni nazw `le.*`;
6. zachować dane użytkownika podczas zwykłego przeładowania;
7. obsługiwać brak opcjonalnych zależności bez zatrzymania całego pluginu.

Nie twórz anonimowych zasobów Mudleta, których nie da się później usunąć. Domknięcia triggerów muszą przechowywać właściwą wartość dla każdej iteracji. Nie zakładaj, że kolejność odpalenia kilku triggerów na tej samej linii jest stała.

## Triggery i tekst gry

Triggery opieraj na rzeczywistych komunikatach Arkadii. Wzorce powinny być możliwie precyzyjne, lecz tolerować znane odmiany gramatyczne i mowę bez polskich znaków.

- Nie zmieniaj treści wypowiedzi z gry, jeśli wystarczy dodać formatowanie.
- Jeśli kilka triggerów może obsłużyć tę samą linię, zastosuj odduplikowanie.
- Kolor ANSI może być sygnałem podstawowym, ale zapewnij rozsądny fallback tekstowy, jeśli jest potrzebny.
- Nie używaj `prefix()` z wielobajtowymi symbolami Unicode. Funkcja może policzyć bajty UTF-8 jako pozycje i rozdzielić początek linii.
- Symbole Unicode twórz jawnie przez `utf8.char(...)`, gdy ma to znaczenie dla pozycjonowania.
- Do wstawiania znacznika na początku istniejącej linii używaj kursora i `dinsertText()`, a potem przywróć kursor na koniec.
- Dbaj, aby komunikat modułu zaczynał się w nowej linii, gdy trigger działa na niedomkniętej linii serwera.

## Czas świata gry

Nigdy nie utożsamiaj jednostek czasu Arkadii z czasem rzeczywistym bez jawnego przeliczenia.

Aktualnie przyjęte przeliczniki:

- 1 godzina gry = 120 sekund rzeczywistych;
- 1 minuta gry = 2 sekundy rzeczywiste;
- 1 dzień gry = 24 godziny gry = 2880 sekund rzeczywistych = 48 minut rzeczywistych.

Fraza NPC „mam dzień” oznacza jeden dzień świata gry, nie 24 godziny rzeczywiste. Wszystkie zmiany w parsowaniu czasu sprawdzaj na liczebnikach słownych, cyfrach, liczbie pojedynczej i mnogiej.

Moduł `le.czas` synchronizuje się na podstawie odpowiedzi gry po komendzie `czas`. Nie przywracaj ręcznej synchronizacji bez wyraźnej decyzji użytkownika. Kolejna odpowiedź `czas` ma korygować zegar, a nie bezpodstawnie zerować minuty.

## System wizualny

UNICORN używa minimalistycznego, wspólnego języka wizualnego.

- Komunikaty konsoli zaczynają się cienką pionową belką w kolorze modułu.
- Nie dodawaj etykiet typu `[ czas ]`, jeśli informację przekazuje już kolor i kontekst.
- Preferuj tekst, odstępy i hierarchię typograficzną zamiast ikon, ramek i ozdobników.
- Korzystaj z palety i funkcji `le.ui`; nie twórz lokalnej palety bez uzasadnienia.
- Kolory mają być stonowane, lekko pastelowe i czytelne na ciemnym tle.
- Tekst zwykły, wyciszony, ostrzeżenia i błędy muszą korzystać ze wspólnej semantyki kolorów.
- Panel boczny używa kolorowej lewej krawędzi zamiast pełnych obramowań.
- Zegar eksponuje dużą, pogrubioną godzinę oraz zwięźle pokazuje domenę, porę roku i czas do świtu lub zmierzchu.
- Zwarty panel dostaw pokazuje ilość, przedmiot i pozostały czas; szczegóły oraz akcje `PROWADŹ` i `USUŃ` pojawiają się po rozwinięciu.

Ograniczenia Qt rich text w Geyserze traktuj jako realne: nie zakładaj obsługi flexbox, grid, position ani transform. Do dwóch kolumn używaj prostych tabel HTML lub natywnych kontenerów Geysera.

## Pomoc i komendy

Każdy moduł udostępnia pomoc pod `/le.<moduł>`. Komendy w pomocy powinny być klikalne przez wspólne funkcje `le.ui`.

- Komendy kompletne wykonuj po kliknięciu.
- Szablony wymagające parametru uzupełniają linię poleceń zamiast wykonywać niepełną komendę.
- Nazwy, opisy i przykłady muszą odpowiadać faktycznie rejestrowanym aliasom.
- Po zmianie komendy zaktualizuj równocześnie pomoc modułu i README.
- Nie wysyłaj do gry dodatkowych komend bez jawnej akcji użytkownika.

## Dane użytkownika

Pliki z danymi runtime zapisuj w katalogu profilu zwracanym przez `getMudletHomeDir()`, nie w repozytorium ani katalogu pluginu.

- Zachowuj kompatybilność z istniejącymi danymi, jeśli jest to rozsądne.
- Przy zmianie formatu przygotuj migrację lub bezpieczne wartości domyślne.
- Nie usuwaj danych użytkownika podczas aktualizacji.
- Operacje zapisu i odczytu zabezpieczaj przed brakiem pliku, błędnym JSON-em i błędem dostępu.
- Nie umieszczaj prywatnych danych, logów z gry ani plików profilu w commitach.

## Wersjonowanie i paczka wydania

Projekt używa wersji `MAJOR.MINOR.PATCH`, a `version.lua` jest jedynym źródłem bieżącej wersji.

Podbij wersję przy każdej zmianie kodu lub zachowania, która ma zostać wdrożona użytkownikowi:

- `PATCH` — poprawka błędu lub mała zgodna zmiana;
- `MINOR` — nowa zgodna funkcja albo moduł;
- `MAJOR` — zmiana niezgodna wstecz.

Sama zmiana dokumentacji lub tego pliku nie wymaga nowej wersji ani przebudowy paczki, jeśli nie zmienia instalowanego pluginu.

Przy wydaniu:

1. zaktualizuj `version.lua`;
2. zaktualizuj wersję i opis w README;
3. zbuduj `dist/UNICORN.zip` z dokładnego SHA zawierającego wszystkie zmiany źródłowe — nie z potencjalnie buforowanego adresu gałęzi;
4. umieść pliki bezpośrednio w katalogu głównym ZIP-a, bez dodatkowego katalogu `UNICORN/`;
5. sprawdź zawartość paczki po jej utworzeniu.

Paczka powinna zawierać co najmniej:

- `init.lua`;
- `version.lua`;
- `le/ui.lua`;
- `le/config.lua`;
- `le/czas.lua`;
- `le/lecz.lua`;
- `le/zlecenia.lua`;
- `le/mowa.lua`.

Jeżeli zmieni się lista modułów w `init.lua`, odpowiednio zmień także listę plików paczki.

## Testowanie

Przed uznaniem zadania za zakończone:

- sprawdź składnię wszystkich zmienionych plików Lua;
- sprawdź ponowną inicjalizację modułu i sprzątanie zasobów;
- sprawdź co najmniej przykłady odpowiadające zgłoszonemu błędowi;
- przetestuj wartości brzegowe parserów i brak opcjonalnych API;
- zweryfikuj pliki i wersję wewnątrz ZIP-a;
- odróżnij test automatyczny od testu wykonanego w działającym Mudlecie.

Nie deklaruj, że funkcja została sprawdzona w Mudlecie, jeśli wykonano tylko analizę statyczną lub test ze stubami. W PR pozostaw krótką listę kroków wymagających testu w grze.

## Git i współpraca wielu agentów

GitHub jest wspólnym źródłem prawdy dla Codex, Gemini i człowieka.

- Jedno zadanie realizuj na jednej osobnej gałęzi i w jednym pull requeście.
- Przed rozpoczęciem pobierz aktualny `main` i sprawdź otwarte PR-y.
- Nie pracuj na gałęzi innego agenta bez wyraźnego uzgodnienia.
- Nie modyfikuj tych samych plików równolegle, jeśli można podzielić zadanie według modułów.
- Jeśli inny PR został scalony w trakcie pracy, ponownie porównaj gałąź z `main` przed publikacją.
- Nie dopisuj nowych commitów do już scalonego PR-a; utwórz nowy PR z pozostałą zmianą.
- Zachowuj istniejące zmiany użytkownika i niezwiązane pliki.
- Nie wykonuj force push, rebase ani operacji usuwających historię bez wyraźnej zgody.
- Commity mają być małe, tematyczne i opisywać rezultat.
- PR powinien zawierać: cel, listę zmian, sposób sprawdzenia i kroki testu w Mudlecie.
- Domyślnie otwieraj PR jako draft, jeśli wymaga jeszcze testu w grze.
- Nie scalaj PR-a bez wyraźnej prośby użytkownika.

Przed rozpoczęciem implementacji agent powinien napisać w PR lub rozmowie, które moduły zamierza zmienić. Jeżeli istnieje aktywny PR dotykający tych samych plików, najpierw oceń konflikt i uzgodnij kierunek.

## Bezpieczeństwo zmian

- Nie usuwaj ani nie nadpisuj danych użytkownika.
- Nie umieszczaj sekretów, tokenów, lokalnych ścieżek ani danych profilu w repozytorium.
- Nie uruchamiaj aktualizatora ani instalatora w imieniu użytkownika bez potrzeby i zgody.
- Nie wykonuj destrukcyjnych operacji Git.
- Nie rozszerzaj zakresu zadania o duży refaktor bez przedstawienia korzyści i ryzyka.
- Przy małej poprawce preferuj małą, łatwą do sprawdzenia zmianę.

## Procedura pracy

### Przed zmianą

1. Przeczytaj obowiązujące instrukcje.
2. Sprawdź aktualny `main`, wersję, README i otwarte PR-y.
3. Zidentyfikuj moduły oraz zewnętrzne źródła tylko do odczytu.
4. Odtwórz problem na podstawie logu, kodu lub testu.
5. Określ, czy zmiana wymaga podbicia wersji i paczki.

### Podczas zmiany

1. Ogranicz edycje do potrzebnych plików.
2. Zachowaj przestrzeń nazw i cykl życia modułu.
3. Korzystaj ze wspólnego UI i publicznych interfejsów.
4. Aktualizuj pomoc oraz README razem ze zmianą zachowania.
5. Dodaj lub zaktualizuj test przypadku, jeśli repozytorium ma odpowiedni mechanizm.

### Po zmianie

1. Sprawdź różnice względem aktualnego `main`.
2. Uruchom możliwe testy i opisz ich rzeczywisty zakres.
3. Przy wydaniu podbij wersję i przebuduj ZIP z dokładnego SHA.
4. Otwórz lub zaktualizuj właściwy PR.
5. Podsumuj zmienione pliki, zachowanie, testy i rzeczy pozostające do sprawdzenia w Mudlecie.
6. Potwierdź, że oficjalne pliki `msmudlet` pozostały nietknięte.

## Definicja ukończenia

Zadanie jest ukończone dopiero wtedy, gdy:

- rozwiązanie odpowiada zgłoszonemu zachowaniu;
- moduł można bezpiecznie przeładować;
- pomoc i dokumentacja są zgodne z kodem;
- wersja oraz ZIP są aktualne, jeśli zmieniono instalowany plugin;
- wykonane testy przeszły, a nietestowane elementy są jawnie wskazane;
- zmiany znajdują się w osobnym, możliwym do scalenia PR-ze;
- żaden plik `msmudlet` ani dane użytkownika nie zostały zmienione.
