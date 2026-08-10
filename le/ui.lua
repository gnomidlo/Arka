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
    config = { accent = "#D5A1B8", tag = "config" },
    czas = { accent = "#79C9D3", tag = "czas" },
    kal = { accent = "#B6A2E1", tag = "kal" },
    zlec = { accent = "#D7A84D", tag = "zlec" },
    lecz = { accent = "#82C9A5", tag = "lecz" },
}

function le.ui.module(name)
    return le.ui.modules[name] or { accent = le.ui.palette.text, tag = tostring(name or "unicorn") }
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

function le.ui.output(module_name, text)
    local module = le.ui.module(module_name)
    decho("\n")
    decho(le.ui.dc(module.accent, "▎"))
    decho(" ")
    decho(le.ui.dc(module.accent, "[ " .. module.tag .. " ]"))
    decho(" " .. tostring(text or "") .. "\n")
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
