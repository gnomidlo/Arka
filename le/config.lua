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

local function read_version(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content:match("le%.version%s*=%s*[\"']([%d%.]+)[\"']")
end

local function module_file(plugin_root, module_name)
    return plugin_root .. "/" .. tostring(module_name):gsub("%.", "/") .. ".lua"
end

local function load_module_list(plugin_root)
    local chunk, err = loadfile(plugin_root .. "/init.lua")
    if not chunk then return nil, "init.lua: " .. tostring(err) end
    -- Manifest zwraca wyłącznie listę; walidacja nie uruchamia kodu pluginu.
    setfenv(chunk, {})
    local ok, modules = pcall(chunk)
    if not ok then return nil, "init.lua: " .. tostring(modules) end
    if type(modules) ~= "table" or #modules == 0 then return nil, "init.lua nie zwrocil listy modulow" end
    local seen, count = {}, 0
    for index, name in pairs(modules) do
        if type(index) ~= "number" or index < 1 or index > #modules or index % 1 ~= 0
            or type(name) ~= "string" or not name:match("^[%w_]+[%w_%.]*$")
            or name:find("..", 1, true) or name:sub(-1) == "." or seen[name] then
            return nil, "nieprawidlowa lista modulow"
        end
        seen[name] = true
        count = count + 1
    end
    if count ~= #modules then return nil, "nieciagla lista modulow" end
    if not seen.version then return nil, "brak modulu version" end
    return modules
end

local function validate_plugin_tree(plugin_root, expected_version)
    if read_version(plugin_root .. "/version.lua") ~= expected_version then
        return nil, "niezgodna wersja plikow"
    end

    local modules, err = load_module_list(plugin_root)
    if not modules then return nil, err end

    for _, module_name in ipairs(modules) do
        local path = module_file(plugin_root, module_name)
        local chunk, compile_error = loadfile(path)
        if not chunk then
            return nil, tostring(module_name) .. ": " .. tostring(compile_error)
        end
    end
    return modules
end

local function ensure_plugin_package_path()
    local plugins = normalized_path(getMudletHomeDir()) .. "/plugins/?.lua"
    if not package.path:find(plugins, 1, true) then
        package.path = plugins .. ";" .. package.path
    end
end

local function reload_plugin_modules(plugin_root, expected_version)
    local modules, validation_error = validate_plugin_tree(plugin_root, expected_version)
    if not modules then return nil, validation_error end

    ensure_plugin_package_path()

    for _, module_name in ipairs(modules) do
        local package_name = "UNICORN." .. module_name
        package.loaded[package_name] = nil
        local ok, err = pcall(require, package_name)
        if not ok then
            return nil, tostring(module_name) .. ": " .. tostring(err)
        end
    end

    if tostring(le.version or "") ~= tostring(expected_version) then
        return nil, "wersja po przeladowaniu to " .. tostring(le.version or "nieznana")
    end
    return true
end

local function install_paths()
    local home = normalized_path(getMudletHomeDir())
    return {
        home = home,
        archive = home .. "/UNICORN-update.zip",
        staging = home .. "/UNICORN-update",
        plugin = home .. "/plugins/UNICORN",
        plugins = home .. "/plugins",
        backup = home .. "/UNICORN-backup",
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
    command_item("mowa", "/le.mowa", "/le.mowa", "oznaczenia mowy, szeptu i krzyku")

    if le.ui and le.ui.output then le.ui.output("config", "KONFIGURACJA") end
    command_item("config", "/le.config wersja", "/le.config wersja", "pokaż wersję i krótkie patch notes")
    command_item("config", "/le.config aktualizacja", "/le.config aktualizacja", "sprawdź dostępną wersję")
    command_item("config", "/le.config aktualizuj", "/le.config aktualizuj", "pobierz, zainstaluj i przeładuj bez restartu")
    command_item("config", "/le.config napraw", "/le.config napraw", "usuń pozostałości instalatora")
end

function le.config.showVersion()
    log("Zainstalowana wersja: " .. tostring(le.version or "nieznana") .. ".", "pale_green")
    if le.patchnotes and le.patchnotes.show then
        le.patchnotes.show(le.version)
    end
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
                log(string.format("Dostępna aktualizacja · %s → %s.", current, remote), "pale_green")
                if le.ui and le.ui.command then
                    le.ui.command("config", "/le.config aktualizuj", "/le.config aktualizuj", "zainstaluj aktualizację", false)
                end
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

                    local modules, validation_error = validate_plugin_tree(paths.staging, remote)
                    if not modules then
                        cleanup_install_resources()
                        pcall(remove_path, paths.staging)
                        pcall(os.remove, paths.archive)
                        log("Odrzucono paczke przed instalacja: " .. tostring(validation_error), "light_pink")
                        return
                    end

                    -- Katalogi są na tym samym dysku profilu. Zamiast kopiować
                    -- po pliku, zachowaj starą instalację i podmień cały katalog.
                    if lfs.attributes(paths.plugin, "mode") ~= "directory" then
                        cleanup_install_resources()
                        log("Brak katalogu aktualnej instalacji. Zachowano kopie zapasowa.", "light_pink")
                        return
                    end
                    local cleared, result = pcall(remove_path, paths.backup)
                    if not cleared or not result then
                        cleanup_install_resources()
                        log("Nie mozna przygotowac kopii poprzedniej wersji.", "light_pink")
                        return
                    end
                    local backed_up, backup_error = os.rename(paths.plugin, paths.backup)
                    if not backed_up then
                        cleanup_install_resources()
                        log("Nie utworzono kopii poprzedniej wersji: " .. tostring(backup_error), "light_pink")
                        return
                    end
                    local installed, install_error = os.rename(paths.staging, paths.plugin)
                    if not installed then
                        local restored, restore_error = os.rename(paths.backup, paths.plugin)
                        cleanup_install_resources()
                        log("Podmiana nie powiodla sie: " .. tostring(install_error)
                            .. (restored and ". Zachowano poprzednia wersje." or
                                ". Poprzednia wersja pozostaje w " .. paths.backup .. ": " .. tostring(restore_error)), "light_pink")
                        return
                    end

                    log("UNICORN " .. remote .. " zapisany. Przeladowuje moduly...", "pale_green")
                    le.config.update.reload_timer = tempTimer(0.05, function()
                        le.config.update.reload_timer = nil
                        local called, ok, reload_error = pcall(reload_plugin_modules, paths.plugin, remote)
                        cleanup_install_resources()
                        pcall(os.remove, paths.archive)
                        if not called or not ok then
                            -- Część modułów mogła już wykonać kod. Przywracamy
                            -- pliki, ale dopiero restart gwarantuje czysty runtime.
                            local moved, move_error = os.rename(paths.plugin, paths.staging)
                            local restored, restore_error
                            if moved then restored, restore_error = os.rename(paths.backup, paths.plugin) end
                            log("Przeladowanie nie powiodlo sie: " .. tostring(reload_error or ok)
                                .. (restored and ". Przywrocono poprzednie pliki. Zrestartuj Mudlet." or
                                    ". Kopia pozostaje w " .. paths.backup .. ": " .. tostring(restore_error or move_error)), "light_pink")
                            return
                        end
                        log("UNICORN " .. remote .. " zaktualizowany i przeladowany bez restartu.", "pale_green")
                        if le.patchnotes and le.patchnotes.show then
                            le.patchnotes.show(remote)
                        end
                    end)
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
    if le.config.update.reload_timer then
        pcall(killTimer, le.config.update.reload_timer)
        le.config.update.reload_timer = nil
    end
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
