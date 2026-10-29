-- Regresja panelu zlecen: kliki po hot reloadzie i izolacja od glownej konsoli.
local function noop() end
local next_id = 0
local function id() next_id = next_id + 1; return next_id end
getMudletHomeDir = function() return "memory" end
getPlayerRoom = function() return "test" end
tempTimer = id; tempAlias = id; tempRegexTrigger = id; registerAnonymousEventHandler = id
killTimer = noop; killAlias = noop; killTrigger = noop; killAnonymousEventHandler = noop
io.exists = function() return false end
cecho = noop; decho = noop; echo = noop; dechoLink = noop
le = { ui = { output = noop, prefix = noop }, storage = { write_json = function() return true end } }

local windows, labels, backgrounds, layouts = {}, {}, 0, 0
Geyser = { Label = {}, UserWindow = {} }
function Geyser.UserWindow:new(config)
    local window = { config = config, type_delete = function(self) self.deleted = true end,
        get_width = function() return 260 end }
    windows[#windows+1] = window
    return window
end
function Geyser.Label:new(config, parent)
    local label = { config = config, parent = parent, visible = true }
    function label:setStyleSheet(value) self.style = value end
    function label:setClickCallback(fn) self.click = fn end
    function label:show() self.visible = true end
    function label:hide() self.visible = false end
    function label:move(x, y) self.x, self.y = x, y end
    function label:resize(width, height) self.width, self.height = width, height end
    function label:echo(value) self.html = value end
    function label:delete() self.deleted = true end
    labels[#labels+1] = label
    return label
end
setBackgroundColor = function(name, _, _, _, alpha)
    assert(name == "LeZleceniaWindow" and alpha == 0)
    backgrounds = backgrounds + 1
end
saveWindowLayout = function() layouts = layouts + 1 end

dofile("le/zlecenia.lua")
local z = le.zlecenia
assert(z.UI.window and z.UI.mode == "window")
assert(z.UI.header.parent == z.UI.window and z.UI.pool[1].parent == z.UI.window)
assert(z.UI.header.visible, "puste okno ma pokazywac licznik 0")
z.data.orders.test = {
    key="test", npc="stary elf", what="ziola", roomName="las", roomID=1,
    completionAt=os.time()+3600
}
z.UI.rebuild()
assert(z.UI.slotOrder[1] and z.UI.pool[1].visible)
z.UI.pool[1].click()
assert(z.UI.expandedKey == "test" and z.UI.routeBtn[1].visible
    and z.UI.deleteBtn[1].visible, "klikniecie nie rozwija dostawy")
assert(z.UI.pool[1].height == tostring(z.config.panel.itemHeight + z.config.panel.expandedExtra).."px")
z.UI.pool[1].click()
assert(z.UI.expandedKey == nil and not z.UI.routeBtn[1].visible)
z.UI.header.click()
assert(z.UI.panelHidden and not z.UI.pool[1].visible)
z.UI.header.click()
assert(not z.UI.panelHidden and z.UI.pool[1].visible)
local old_window, old_header, old_item = z.UI.window, z.UI.header, z.UI.pool[1]
dofile("le/zlecenia.lua")
assert(old_window.deleted and old_header.deleted and old_item.deleted,
    "reload nie usunal starych okien i callbackow")
assert(z.UI.window ~= old_window and #windows == 2 and backgrounds == 2 and layouts > 0)
assert(z.UI.pool[1] ~= old_item and z.UI.pool[1].parent == z.UI.window)
z.UI.pool[1].click()
assert(z.UI.expandedKey == "test", "klikniecie po reloadzie nie dziala")
z.cleanup()
assert(z.UI.pool == nil and z.UI.window == nil, "cleanup ma zwolnic pool")
print("OK: isolated orders UserWindow, clicks and cleanup after hot reload")
