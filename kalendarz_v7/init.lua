calendar = calendar or {}

local base_path = getMudletHomeDir() .. "/kalendarz_v7"

dofile(base_path .. "/modules/utils.lua")
calendar.imperial = dofile(base_path .. "/modules/domains/imperial.lua")
calendar.ishtar = dofile(base_path .. "/modules/domains/ishtar.lua")
dofile(base_path .. "/core.lua")

calendar.init()
