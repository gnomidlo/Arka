-- le.config
-- Glowny modul pomocy, wersji i aktualizacji konfiguracji le.conf.

le = le or {}
le.config = le.config or {}
le.config.aliases = le.config.aliases or {}
le.config.update = le.config.update or {}

le.config.urls = {
    version = "https://raw.githubusercontent.com/gnomidlo/Arka/main/version.lua",
    install = "https://raw.githubusercontent.com/gnomidlo/Arka/main/dist/Arka.zip",
}

local function log(text, color)
    cecho(string.format("\n<sky_blue>[<%s>config<sky_blue>]<reset> %s\n",
        color or "powder_blue", tostring(text or "")))
end

local function compare_versions(left, right)
    local left_parts, right_parts = {}, {}
    for value in tostring(left or ""):gmatch("%d+") do
        left_parts[#left_parts + 1] = tonumber(value)
    end
    for value in tostring(right or ""):gmatch("%d+") do
        right_parts[#right_parts + 1] = tonumber(value)
    end
    for index = 1, math.max(#left_parts, #right_parts, 3) do
        local a, b = left_parts[index] or 0, right_parts[index] or 0
        if a < b then return -1 end
        if a > b then return 1 end
    end
    return 0
end

local function cleanup_update_resources()
    if le.config.update.done_handler then
        pcall(killAnonymousEventHandler, le.config.update.done_handler)
        le.config.update.done_handler = nil
    end
    if le.config.update.error_handler then
        pcall(killAnonymousEventHandler, le.config.update.error_handler)
        le.config.update.error_handler = nil
    end
    le.config.update.checking = false
end

function le.config.showHelp()
    cecho([[
<sky_blue>╔══════════════════════════════════════════════╗
<sky_blue>║<white>                  le.conf                     <sky_blue>║
<sky_blue>╚══════════════════════════════════════════════╝<reset>

<white>Dostepne komendy:<reset>
  <yellow>/le.config<reset>              - wyswietla te pomoc
  <yellow>/le.config wersja<reset>       - pokazuje zainstalowana wersje
  <yellow>/le.config aktualizacja<reset> - sprawdza dostepnosc aktualizacji
  <yellow>/le.config aktualizuj<reset>   - instaluje znaleziona aktualizacje
  <yellow>/le.czas<reset>                - pomoc zegara i synchronizacji czasu
  <yellow>/le.kal [liczba]<reset>        - najblizsze wydarzenia z obu domen
  <yellow>/le.kal tydzien<reset>         - agenda na najblizsze 7 dni
]])
end

function le.config.showVersion()
    log("Zainstalowana wersja: " .. tostring(le.version or "nieznana") .. ".", "pale_green")
end

function le.config.checkUpdate(options)
    options = options or {}
    if le.config.update.checking then
        if not options.automatic then
            log("Sprawdzanie aktualizacji juz trwa.", "slate_gray")
        end
        return
    end

    cleanup_update_resources()
    le.config.update.checking = true
    le.config.update.remote_version = nil

    local request_url = le.config.urls.version .. "?time=" .. os.time()
    le.config.update.request_url = request_url

    le.config.update.done_handler = registerAnonymousEventHandler(
        "sysGetHttpDone",
        function(_, url, response)
            if url ~= request_url then return true end
            cleanup_update_resources()

            local remote = tostring(response or ""):match("return%s+[\"']([%d%.]+)[\"']")
            if not remote then
                log("Nie udalo sie odczytac wersji z GitHuba.", "light_pink")
                return
            end

            le.config.update.remote_version = remote
            local current = tostring(le.version or "0.0.0")
            if compare_versions(current, remote) < 0 then
                log(string.format("Dostepna aktualizacja: %s -> %s.", current, remote), "pale_green")
                cechoLink("<yellow>>> /le.config aktualizuj<reset>\n",
                    function() expandAlias("/le.config aktualizuj") end,
                    "Zainstaluj aktualizacje le.conf", true)
            elseif not options.automatic then
                log("Masz najnowsza wersje: " .. current .. ".", "pale_green")
            end
        end,
        true
    )

    le.config.update.error_handler = registerAnonymousEventHandler(
        "sysGetHttpError",
        function(_, response, url)
            if url ~= request_url then return true end
            cleanup_update_resources()
            log("Nie udalo sie sprawdzic aktualizacji: " .. tostring(response or "blad HTTP"), "light_pink")
        end,
        true
    )

    local ok, err = pcall(getHTTP, request_url)
    if not ok then
        cleanup_update_resources()
        log("Nie udalo sie rozpoczac sprawdzania: " .. tostring(err), "light_pink")
        return
    end

    if not options.automatic then
        log("Sprawdzam dostepnosc aktualizacji...", "powder_blue")
    end
end

function le.config.installUpdate()
    local remote = le.config.update.remote_version
    local current = tostring(le.version or "0.0.0")
    if not remote then
        log("Najpierw uzyj /le.config aktualizacja.", "light_pink")
        return
    end
    if compare_versions(current, remote) >= 0 then
        log("Masz juz najnowsza wersje: " .. current .. ".", "pale_green")
        return
    end

    local install_url = le.config.urls.install .. "?version=" .. remote
    log("Rozpoczynam aktualizacje do wersji " .. remote .. ".", "pale_green")

    if scripts and scripts.plugins_installer and scripts.plugins_installer.install_from_url then
        scripts.plugins_installer:install_from_url(install_url)
    else
        expandAlias("/zainstaluj_plugin " .. install_url)
    end

    tempTimer(5, function()
        log("Aktualizacja pobrana. Zrestartuj Mudlet, aby zaladowac wszystkie zmiany.", "pale_green")
    end)
end

function le.config.cleanup()
    cleanup_update_resources()
    if le.config.update.startup_timer then
        pcall(killTimer, le.config.update.startup_timer)
        le.config.update.startup_timer = nil
    end
    if le.config.aliases then
        for _, id in pairs(le.config.aliases) do pcall(killAlias, id) end
    end
    le.config.aliases = {}
end

function le.config.setupAliases()

le.config.update.startup_timer = tempTimer(6, function()
    le.config.update.startup_timer = nil
    le.config.checkUpdate({ automatic = true })
end)
    le.config.cleanup()

    le.config.aliases.help = tempAlias([[^/le\.config$]], le.config.showHelp)
    le.config.aliases.version = tempAlias([[^/le\.config wersja$]], le.config.showVersion)
    le.config.aliases.check = tempAlias([[^/le\.config aktualizacja$]], le.config.checkUpdate)
    le.config.aliases.install = tempAlias([[^/le\.config aktualizuj$]], le.config.installUpdate)
end

le.config.setupAliases()
