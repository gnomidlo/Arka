-- le.config
-- Glowny modul pomocy, wersji i aktualizacji konfiguracji le.conf.

le = le or {}
le.config = le.config or {}
le.config.aliases = le.config.aliases or {}
le.config.update = le.config.update or {}

le.config.urls = {
    version = "https://raw.githubusercontent.com/gnomidlo/Arka/main/version.lua",
    install = "https://codeload.github.com/gnomidlo/Arka/zip/main",
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
    if le.config.update.download_handler then
        pcall(killAnonymousEventHandler, le.config.update.download_handler)
        le.config.update.download_handler = nil
    end
    if le.config.update.timeout then
        pcall(killTimer, le.config.update.timeout)
        le.config.update.timeout = nil
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

function le.config.checkUpdate()
    if le.config.update.checking then
        log("Sprawdzanie aktualizacji juz trwa.", "slate_gray")
        return
    end

    cleanup_update_resources()
    le.config.update.checking = true
    le.config.update.remote_version = nil
    local path = getMudletHomeDir() .. "/le_config_remote_version.lua"
    le.config.update.path = path
    pcall(os.remove, path)

    le.config.update.download_handler = registerAnonymousEventHandler(
        "sysDownloadDone",
        function(_, filename)
            if filename ~= path then return end
            local file = io.open(path, "r")
            local content = file and file:read("*a") or ""
            if file then file:close() end
            pcall(os.remove, path)
            cleanup_update_resources()

            local remote = content:match([[return%s+["']([%d%.]+)["']]])
            if not remote then
                log("Nie udalo sie odczytac wersji z GitHuba.", "light_pink")
                return
            end

            le.config.update.remote_version = remote
            local current = tostring(le.version or "0.0.0")
            if compare_versions(current, remote) < 0 then
                log(string.format("Dostepna aktualizacja: %s -> %s.", current, remote), "pale_green")
                cechoLink("<yellow>>> /le.config aktualizuj<reset>\n",
                    [[expandAlias("/le.config aktualizuj")]],
                    "Zainstaluj aktualizacje le.conf", true)
            else
                log("Masz najnowsza wersje: " .. current .. ".", "pale_green")
            end
        end
    )

    le.config.update.timeout = tempTimer(30, function()
        if not le.config.update.checking then return end
        cleanup_update_resources()
        pcall(os.remove, path)
        log("Przekroczono czas sprawdzania aktualizacji.", "light_pink")
    end)

    local ok, err = pcall(downloadFile, path, le.config.urls.version)
    if not ok then
        cleanup_update_resources()
        log("Nie udalo sie rozpoczac sprawdzania: " .. tostring(err), "light_pink")
        return
    end
    log("Sprawdzam dostepnosc aktualizacji...", "powder_blue")
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

    log("Rozpoczynam aktualizacje do wersji " .. remote .. ".", "pale_green")
    expandAlias("/zainstaluj_plugin " .. le.config.urls.install)
end

function le.config.cleanup()
    cleanup_update_resources()
    if le.config.aliases then
        for _, id in pairs(le.config.aliases) do pcall(killAlias, id) end
    end
    le.config.aliases = {}
end

function le.config.setupAliases()
    le.config.cleanup()

    le.config.aliases.help = tempAlias([[^/le\.config$]], le.config.showHelp)
    le.config.aliases.version = tempAlias([[^/le\.config wersja$]], le.config.showVersion)
    le.config.aliases.check = tempAlias([[^/le\.config aktualizacja$]], le.config.checkUpdate)
    le.config.aliases.install = tempAlias([[^/le\.config aktualizuj$]], le.config.installUpdate)
end

le.config.setupAliases()
