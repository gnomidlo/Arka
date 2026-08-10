-- le.config
-- Glowny modul pomocy, wersji i aktualizacji konfiguracji le.conf.

le = le or {}
le.config = le.config or {}
le.config.aliases = le.config.aliases or {}
le.config.update = le.config.update or {}

le.config.urls = {
    version = "https://raw.githubusercontent.com/gnomidlo/Arka/main/version.lua",
    install = "https://raw.githubusercontent.com/gnomidlo/Arka/main/dist/UNICORN.zip",
}

local function log(text, color)
    if le.ui and le.ui.output then
        le.ui.output("config", text)
        return
    end
    cecho(string.format("\n<light_pink>▎<reset>  %s\n", tostring(text or "")))
end

local function command_item(module_name, label, command, description)
    if le.ui and le.ui.command then
        le.ui.command(module_name, label, command, description, false)
        return
    end
    cecho("  ")
    cechoLink(label, function() expandAlias(command) end, description, true)
    cecho(" · " .. description .. "\n")
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

local function kill_update_handler(key)
    if le.config.update[key] then
        pcall(killAnonymousEventHandler, le.config.update[key])
        le.config.update[key] = nil
    end
end

local function cleanup_install_resources()
    for _, key in ipairs({
        "download_done_handler", "download_error_handler",
        "unzip_done_handler", "unzip_error_handler",
    }) do
        kill_update_handler(key)
    end
    le.config.update.installing = false
end

local function normalized_path(path)
    return tostring(path or ""):gsub("\\", "/"):gsub("/+$", "")
end

local function remove_path(path)
    path = normalized_path(path)
    local mode = lfs.attributes(path, "mode")
    if not mode then return true end
    if mode ~= "directory" then return os.remove(path) end

    for entry in lfs.dir(path) do
        if entry ~= "." and entry ~= ".." then
            local success, err = remove_path(path .. "/" .. entry)
            if not success then return nil, err end
        end
    end
    return lfs.rmdir(path)
end

local function copy_file(source, target)
    local input, read_error = io.open(source, "rb")
    if not input then return nil, read_error end
    local content = input:read("*a")
    input:close()

    local output, write_error = io.open(target, "wb")
    if not output then return nil, write_error end
    local success, error_message = output:write(content)
    output:close()
    if not success then return nil, error_message end
    return true
end

local function copy_tree(source, target)
    source, target = normalized_path(source), normalized_path(target)
    local mode = lfs.attributes(source, "mode")
    if mode == "file" then return copy_file(source, target) end
    if mode ~= "directory" then return nil, "brak katalogu " .. source end

    if lfs.attributes(target, "mode") ~= "directory" then
        local success, err = lfs.mkdir(target)
        if not success then return nil, err end
    end
    for entry in lfs.dir(source) do
        if entry ~= "." and entry ~= ".." then
            local success, err = copy_tree(source .. "/" .. entry, target .. "/" .. entry)
            if not success then return nil, err end
        end
    end
    return true
end

local function read_version(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content:match("le%.version%s*=%s*[\"']([%d%.]+)[\"']")
end

local function install_paths()
    local home = normalized_path(getMudletHomeDir())
    return {
        home = home,
        archive = home .. "/UNICORN-update.zip",
        staging = home .. "/UNICORN-update",
        plugin = home .. "/plugins/UNICORN",
        plugins = home .. "/plugins",
    }
end

function le.config.cleanupArtifacts(options)
    options = options or {}
    local paths = install_paths()
    local removed, quarantined, failed = 0, 0, {}

    if lfs.attributes(paths.home, "mode") == "directory" then
        for name in lfs.dir(paths.home) do
            if name:match("^UNICORN%-cleanup%-%d+") then
                pcall(remove_path, paths.home .. "/" .. name)
            end
        end
    end

    if lfs.attributes(paths.plugins, "mode") == "directory" then
        for name in lfs.dir(paths.plugins) do
            if name == "UNICORN_todelete" or name:match("^%d+UNICORN$") then
                local target = paths.plugins .. "/" .. name
                local cleared = false
                local ok, success, err = pcall(remove_path, target)
                if ok and success then
                    removed = removed + 1
                    cleared = true
                else
                    local quarantine = paths.home .. "/UNICORN-cleanup-" .. os.time() .. "-" .. name
                    local moved, move_error = os.rename(target, quarantine)
                    if moved then
                        quarantined = quarantined + 1
                        cleared = true
                    else
                        failed[#failed + 1] = name .. ": " .. tostring(move_error or err or success)
                    end
                end

                if cleared and scripts and scripts.plugins then
                    for index = #scripts.plugins, 1, -1 do
                        if scripts.plugins[index] == name then table.remove(scripts.plugins, index) end
                    end
                end
            end
        end
    end

    if not options.quiet then
        if #failed == 0 then
            if quarantined > 0 then
                log(string.format("Usunieto %d, odizolowano poza plugins %d. Zrestartuj Mudlet.",
                    removed, quarantined), "pale_green")
            else
                log("Usunieto pozostalosci instalatora: " .. removed .. ". Zrestartuj Mudlet.", "pale_green")
            end
        else
            log("Nie udalo sie usunac: " .. table.concat(failed, ", "), "light_pink")
        end
    end
    return #failed == 0
end

function le.config.showHelp()
    log("UNICORN " .. tostring(le.version or "") .. " · pomoc")
    if le.ui and le.ui.note then
        le.ui.note("config", "Kliknij komendę, aby ją uruchomić.")
        le.ui.output("config", "MODUŁY")
    end

    command_item("config", "/le.config", "/le.config", "centrum pomocy UNICORN")
    command_item("czas", "/le.czas", "/le.czas", "zegar i synchronizacja")
    command_item("kal", "/le.kal", "/le.kal", "kalendarz i agenda 7 dni")
    command_item("lecz", "/le.lecz", "/le.lecz", "dobór ziół do przypadłości")
    command_item("zlec", "/le.zlecenia", "/le.zlecenia", "dostawy od NPC")

    if le.ui and le.ui.output then le.ui.output("config", "KONFIGURACJA") end
    command_item("config", "/le.config wersja", "/le.config wersja", "pokaż zainstalowaną wersję")
    command_item("config", "/le.config aktualizacja", "/le.config aktualizacja", "sprawdź dostępną wersję")
    command_item("config", "/le.config aktualizuj", "/le.config aktualizuj", "pobierz i zainstaluj")
    command_item("config", "/le.config napraw", "/le.config napraw", "usuń pozostałości instalatora")
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

            local content = tostring(response or "")
            local remote = content:match("le%.version%s*=%s*[\"\']([%d%.]+)[\"\']")
                or content:match("return%s+[\"\']([%d%.]+)[\"\']")
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
    if le.config.update.installing then
        log("Instalacja aktualizacji juz trwa.", "slate_gray")
        return
    end

    cleanup_install_resources()
    local paths = install_paths()
    pcall(os.remove, paths.archive)
    pcall(remove_path, paths.staging)
    le.config.cleanupArtifacts({ quiet = true })

    local install_url = le.config.urls.install .. "?version=" .. remote .. "&time=" .. os.time()
    le.config.update.installing = true
    le.config.update.install_url = install_url
    log("Rozpoczynam aktualizacje do wersji " .. remote .. ".", "pale_green")

    le.config.update.download_done_handler = registerAnonymousEventHandler(
        "sysDownloadDone",
        function(_, filename)
            if normalized_path(filename) ~= normalized_path(paths.archive) then return true end
            kill_update_handler("download_done_handler")
            kill_update_handler("download_error_handler")

            le.config.update.unzip_done_handler = registerAnonymousEventHandler(
                "sysUnzipDone",
                function()
                    kill_update_handler("unzip_done_handler")
                    kill_update_handler("unzip_error_handler")

                    local staged_version = read_version(paths.staging .. "/version.lua")
                    if staged_version ~= remote then
                        cleanup_install_resources()
                        pcall(remove_path, paths.staging)
                        pcall(os.remove, paths.archive)
                        log("Paczka aktualizacji ma nieprawidlowa wersje.", "light_pink")
                        return
                    end

                    local ok, success, err = pcall(copy_tree, paths.staging, paths.plugin)
                    if not ok or not success then
                        cleanup_install_resources()
                        log("Nie udalo sie zapisac aktualizacji: " .. tostring(err or success), "light_pink")
                        return
                    end

                    local installed_version = read_version(paths.plugin .. "/version.lua")
                    pcall(remove_path, paths.staging)
                    pcall(os.remove, paths.archive)
                    le.config.cleanupArtifacts({ quiet = true })
                    cleanup_install_resources()

                    if installed_version ~= remote then
                        log("Weryfikacja zapisanej wersji nie powiodla sie.", "light_pink")
                        return
                    end
                    log("UNICORN " .. remote .. " zapisany bez tworzenia nowej instancji. Zrestartuj Mudlet.", "pale_green")
                end,
                true
            )
            le.config.update.unzip_error_handler = registerAnonymousEventHandler(
                "sysUnzipError",
                function()
                    cleanup_install_resources()
                    pcall(remove_path, paths.staging)
                    pcall(os.remove, paths.archive)
                    log("Nie udalo sie rozpakowac aktualizacji.", "light_pink")
                end,
                true
            )
            unzipAsync(paths.archive, paths.staging)
        end,
        true
    )

    le.config.update.download_error_handler = registerAnonymousEventHandler(
        "sysDownloadError",
        function(_, response, url)
            if url and url ~= install_url then return true end
            cleanup_install_resources()
            pcall(os.remove, paths.archive)
            log("Nie udalo sie pobrac aktualizacji: " .. tostring(response or "blad pobierania"), "light_pink")
        end,
        true
    )

    local ok, err = pcall(downloadFile, paths.archive, install_url)
    if not ok then
        cleanup_install_resources()
        log("Nie udalo sie rozpoczac aktualizacji: " .. tostring(err), "light_pink")
    end
end

function le.config.cleanup()
    cleanup_update_resources()
    cleanup_install_resources()
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
    le.config.cleanup()

    le.config.aliases.help = tempAlias([[^/le\.config$]], le.config.showHelp)
    le.config.aliases.version = tempAlias([[^/le\.config wersja$]], le.config.showVersion)
    le.config.aliases.check = tempAlias([[^/le\.config aktualizacja$]], le.config.checkUpdate)
    le.config.aliases.install = tempAlias([[^/le\.config aktualizuj$]], le.config.installUpdate)
    le.config.aliases.repair = tempAlias([[^/le\.config napraw$]], le.config.cleanupArtifacts)
end

le.config.setupAliases()

le.config.update.startup_timer = tempTimer(6, function()
    le.config.update.startup_timer = nil
    le.config.checkUpdate({ automatic = true })
end)

tempTimer(1, function()
    log("UNICORN " .. tostring(le.version or "") .. " zaladowany. Pomoc: /le.config.", "plum")
end)
