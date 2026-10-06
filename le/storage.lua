-- Zapis JSON z zachowaniem poprzedniego pliku także na Windows.
le = le or {}
le.storage = le.storage or {}

function le.storage.write_json(path, value)
    local ok, encoded = pcall(yajl.to_string, value)
    if not ok or type(encoded) ~= "string" then return nil, "Nie udalo sie przygotowac JSON." end
    local temporary, backup = path .. ".tmp", path .. ".bak"
    local file, err = io.open(temporary, "wb")
    if not file then return nil, err end
    local wrote, result = pcall(file.write, file, encoded)
    local closed, close_result = pcall(file.close, file)
    if not wrote or not result or not closed or not close_result then
        os.remove(temporary)
        return nil, "Nie udalo sie zapisac lub zamknac pliku tymczasowego."
    end
    local existed = io.exists(path)
    if existed then
        if io.exists(backup) then
            local removed, remove_error = os.remove(backup)
            if not removed then os.remove(temporary); return nil, remove_error end
        end
        local moved, move_error = os.rename(path, backup)
        if not moved then os.remove(temporary); return nil, move_error end
    end
    local installed, install_error = os.rename(temporary, path)
    if not installed then
        if existed then
            local restored, restore_error = os.rename(backup, path)
            if not restored then
                return nil, "Poprzedni zapis pozostaje w " .. backup .. ": " .. tostring(restore_error)
            end
        end
        os.remove(temporary)
        return nil, install_error
    end
    return true
end

return le.storage
