-- le.config
-- Główny moduł pomocy konfiguracji le.conf.
-- Moduł korzysta wyłącznie z API Mudleta i nie zależy od msconfig/msmudlet.

le = le or {}
le.config = le.config or {}
le.config.aliases = le.config.aliases or {}

function le.config.showHelp()
    cecho([[
<sky_blue>╔══════════════════════════════════════════════╗
<sky_blue>║<white>                  le.conf                     <sky_blue>║
<sky_blue>╚══════════════════════════════════════════════╝<reset>

<white>Dostępne komendy:<reset>
  <yellow>/le.config<reset>      - wyświetla tę pomoc
  <yellow>/le.czas<reset>        - pomoc zegara i synchronizacji czasu
  <yellow>/le.kal [liczba]<reset> - najbliższe wydarzenia z obu domen
]])
end

function le.config.setupAliases()
    if le.config.aliases.help then
        pcall(killAlias, le.config.aliases.help)
    end

    le.config.aliases.help = tempAlias([[^/le\.config$]], function()
        le.config.showHelp()
    end)
end

le.config.setupAliases()
