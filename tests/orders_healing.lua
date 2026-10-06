local function noop() end
local writes, output, links = 0, {}, {}
getMudletHomeDir = function() return "memory" end
tempTimer = function() return 1 end
tempAlias = tempTimer; tempRegexTrigger = tempTimer; registerAnonymousEventHandler = tempTimer
killTimer = noop; killAlias = noop; killTrigger = noop; killAnonymousEventHandler = noop
cecho = function(text) output[#output+1] = text end
decho = cecho; echo = noop
cechoLink = function(_, _, hint) links[#links+1] = hint end
le = {
    ui = {output = function(_, text) output[#output+1] = text end, command = noop, note = noop, prefix = noop},
    storage = {write_json = function() writes = writes + 1; return true end},
}
Geyser = {Label = {new = function() return setmetatable({}, {__index = function() return noop end}) end}}
io.exists = function() return false end
dofile("le/zlecenia.lua")
local z = le.zlecenia
z.data = {orders = {
    a = {completionAt = os.time()-1, npc="A", what="a"},
    b = {completionAt = os.time()-1, npc="B", what="b"},
    c = {completionAt = os.time()+60, npc="C", what="c"},
}, completed=5}
writes = 0
z.check_expired()
assert(z.data.completed == 5 and z.data.orders.c and not z.data.orders.a and not z.data.orders.b)
assert(writes == 1, "expired orders should be saved together")
z.check_expired(); assert(writes == 1)
getPlayerRoom = function() return "c" end
matches = {"", "C"}
z.handle_order_completed()
assert(z.data.completed == 6 and not z.data.orders.c)
local order = {key="route", roomID=123}
for _, callback in ipairs({false, function() error("route") end, function() return false end}) do
    alias_func_prowadz = callback or nil
    z.UI.toggle_route(order)
    assert(z.UI.routingKey == nil)
end
alias_func_prowadz = function(room) assert(room == 123) end
alias_func_prowadz_stop = noop
z.UI.toggle_route(order); assert(z.UI.routingKey == "route")
z.UI.toggle_route(order); assert(z.UI.routingKey == nil)
z.UI.toggle_route(order); z.init(); assert(z.UI.routingKey == nil)
dofile("le/lecz.lua")
herbs = nil; output, links = {}, {}
le.lecz.report({"jad_wija"})
assert(#links == 2 and links[1] == "wylecz zatrucie")
assert(not table.concat(output):find("brak danych"))
links = {}
le.lecz.report({"jad_wija", "gadzi_jad"})
assert(#links == 3 and links[3] == "Zbuduj baze ziol")
io.exists = function() return true end
io.open = function() return {read = function() return "broken" end, close = noop} end
yajl = {to_value = function() error("invalid JSON") end}
z.load(); writes = 0
assert(not z.save() and writes == 0)
print("OK: expired/completed orders, route failures, reload, non-herbal advice, corrupt save protection")
