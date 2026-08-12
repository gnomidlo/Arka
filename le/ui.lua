-- Wspolny, minimalistyczny system wizualny UNICORN.

le = le or {}
le.ui = le.ui or {}

le.ui.palette = {
    background = "#101216",
    surface = "rgba(12, 14, 18, 220)",
    text = "#D8DBE2",
    muted = "#8B909A",
    dim = "#666B75",
    divider = "#2C3038",
    success = "#8FC9A3",
    warning = "#D7AE5D",
    danger = "#D98282",
}

le.ui.modules = {
    config = { accent = "#D5A1B8" },
    czas = { accent = "#79C9D3" },
    kal = { accent = "#B6A2E1" },
    zlec = { accent = "#D7A84D" },
    lecz = { accent = "#82C9A5" },
    flakoniki = { accent = "#8FAFC5" },
    kamienie = { accent = "#B6A2E1" },
    mowa = { accent = "#7FAFC0" },
    szept = { accent = "#A39CBC" },
    krzyk = { accent = "#C88478" },
}

function le.ui.module(name)
    return le.ui.modules[name] or { accent = le.ui.palette.text }
end

function le.ui.rgb(hex)
    local value = tostring(hex or "#FFFFFF"):gsub("#", "")
    local r = tonumber(value:sub(1, 2), 16) or 255
    local g = tonumber(value:sub(3, 4), 16) or 255
    local b = tonumber(value:sub(5, 6), 16) or 255
    return string.format("%d,%d,%d", r, g, b)
end

function le.ui.dc(hex, text)
    return string.format("<%s>%s<r>", le.ui.rgb(hex), tostring(text or ""))
end

function le.ui.prefix(module_name)
    local module = le.ui.module(module_name)
    -- Trigger moze odpalic na niedomknietej linii serwera (np. mowa NPC bez
    -- konca linii) — wstaw znak nowej linii tylko wtedy, gdy kursor nie jest
    -- juz na jej poczatku, zeby belka nigdy nie doklejala sie do tekstu gry.
    local ok, column = pcall(getColumnNumber)
    if ok and column and column > 0 then
        echo("\n")
    end
    decho(le.ui.dc(module.accent, "▎"))
    decho("  ")
end

function le.ui.output(module_name, text)
    le.ui.prefix(module_name)
    decho(tostring(text or "") .. "\n")
end

function le.ui.note(module_name, text)
    le.ui.prefix(module_name)
    decho(le.ui.dc(le.ui.palette.muted, text) .. "\n")
end

function le.ui.command(module_name, label, command, description, fill_only)
    local module = le.ui.module(module_name)
    le.ui.prefix(module_name)
    dechoLink(le.ui.dc(module.accent, label), function()
        if fill_only and type(setCmdLine) == "function" then
            setCmdLine(command)
        else
            expandAlias(command)
        end
    end, fill_only and "Uzupełnij komendę i zatwierdź" or description, true)
    decho(le.ui.dc(le.ui.palette.muted, " · " .. tostring(description or "")) .. "\n")
end

function le.ui.panel_style(accent, padding)
    return string.format([[
        background-color: rgba(12, 14, 18, 220);
        border: none;
        border-left: 3px solid %s;
        border-radius: 0px;
        padding: %s;
        font-family: 'DejaVu Sans Mono', 'Consolas', monospace;
    ]], accent, padding or "7px 10px")
end

function le.ui.transparent_panel_style(accent, padding)
    return string.format([[
        background-color: transparent;
        border: none;
        border-left: 3px solid %s;
        border-radius: 0px;
        padding: %s;
        font-family: 'DejaVu Sans Mono', 'Consolas', monospace;
    ]], accent, padding or "2px 8px")
end
