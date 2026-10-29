-- Regresja panelu zlecen: kliki po hot reloadzie i izolacja od glownej konsoli.
local function noop() end
local next_id = 0
local function id() next_id = next_id + 1; return next_id end
getMudletHomeDir = function() return "memory" end
getPlayerRoom = function() return "test" end
tempTimer = id; tempAlias = id; tempRegexTrigger = id; registerAnonymousEventHandler = id
killTimer = noop; killAlias = noop; killTrigger = noop; killAnonymousEventHandler = noop
io.exists = function() return false end
local links, output = {}, {}
cecho = noop; decho = function(text) output[#output+1] = text end; echo = noop
dechoLink = function(text, fn) links[#links+1] = {text=text, click=fn} end
local resized = 0
resizeWindow = function() resized = resized + 1 end
showWindow = noop; hideWindow = noop
le = { ui = { output = noop, prefix = noop }, storage = { write_json = function() return true end } }

local windows, labels, backgrounds, layouts = {}, {}, 0, 0
Geyser = { Label = {}, UserWindow = {} }
function Geyser.UserWindow:new(config)
    local window = { config = config, type_delete = function(self) self.deleted = true end,
        get_width = function() return 260 end, show=function(self) self.visible=true end, hide=function(self) self.visible=false end }
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
assert(not z.UI.header.visible and not z.UI.window.visible)
local now = os.time()
for i = 1, 8 do
    z.data.orders[tostring(i)] = {npc="NPC", what=i.." sztuk laku", roomName="Miejsce <&>", roomID=i, completionAt=now+i*100}
end
z.data.orders.expired = {completionAt=now-1}
z.data.orders.none = {status="brak"}
z.UI.rebuild()
assert(#z.UI.pool == 3 and z.UI.pages == 3 and z.UI.window.visible)
assert(z.UI.slotOrder[1].key == "1" and z.UI.slotOrder[3].key == "3")
assert(z.UI.pool[1].html:find("Miejsce &lt;&amp;&gt;",1,true))
local before = resized
z.UI.pool[1].click()
assert(#links == 2 and table.concat(output):find("NPC",1,true))
local routed
alias_func_prowadz = function(id) routed=id end
links[1].click()
assert(routed == 1)
z.UI.nav[2].click()
assert(z.UI.slotOrder[1].key == "4")
z.UI.nav[2].click()
assert(z.UI.slotOrder[1].key == "7" and not z.UI.slotOrder[3] and z.UI.pool[3].visible)
z.UI.nav[2].click()
assert(z.UI.page == 3 and resized == before, "Paging must not resize")
local linkCount = #links
z.UI.pool[3].click()
assert(#links == linkCount)
z.data.orders["7"], z.data.orders["8"] = nil, nil
z.UI.rebuild()
assert(z.UI.page == 2 and z.UI.slotOrder[1].key == "4")
z.UI.pool[1].click()
links[#links].click()
assert(not z.data.orders["4"], "Console delete must target clicked order")
local old_window, old_header, old_item, old_nav = z.UI.window, z.UI.header, z.UI.pool[1], z.UI.nav[1]
dofile("le/zlecenia.lua")
assert(old_window.deleted and old_header.deleted and old_item.deleted and old_nav.deleted)
assert(z.data.orders["1"] and z.UI.pool[1].parent == z.UI.window)
z.UI.pool[1].click()
assert(#links > linkCount)
z.data.orders = {}
z.UI.rebuild()
assert(not z.UI.window.visible and not z.UI.header.visible)
for _, label in ipairs(z.UI.pool) do assert(not label.visible) end
z.data.orders.unknown = {what="2 ziola", roomName="las"}
z.UI.rebuild()
assert(z.UI.window.visible and z.UI.pool[1].html:find("?:??",1,true))
z.cleanup()
Geyser.UserWindow = nil
z.UI.rebuild()
assert(z.UI.mode == "legacy" and #z.UI.pool == 3)
z.cleanup()
Geyser = nil
z.UI.rebuild()
print("OK: variant C pages, expiry, details, actions, fixed size, reload and missing APIs")
