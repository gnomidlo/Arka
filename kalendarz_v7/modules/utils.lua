calendar = calendar or {}

function calendar.table_contains(t, val)
  for _, v in pairs(t) do
    if v == val then return true end
  end
  return false
end

function calendar.table_size(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function calendar.table_n_union(t1, t2)
  local res = {}
  for _, v in ipairs(t1) do table.insert(res, v) end
  for _, v in ipairs(t2) do table.insert(res, v) end
  return res
end

function calendar.time_to_minutes(time_str)
  if not time_str then return 0 end
  local h, m = time_str:match("(%d+):(%d+)")
  return (tonumber(h) or 0) * 60 + (tonumber(m) or 0)
end

function calendar.minutes_to_time(minutes)
  local h = math.floor(minutes / 60) % 24
  local m = math.floor(minutes % 60)
  return string.format("%02d:%02d", h, m)
end

function calendar.format_24h(hour)
  return string.format("<white>%02d:00<reset>", tonumber(hour) or 0)
end

function calendar.resttime(time)
  if time <= 0 then return "0s" end
  local days = math.floor(time / 86400)
  local rem = time % 86400
  local hours = math.floor(rem / 3600)
  rem = rem % 3600
  local minutes = math.floor(rem / 60)
  local seconds = math.floor(rem % 60)
  if days > 0 then return days .. "d " .. hours .. "h" end
  if hours > 0 then return hours .. "h " .. minutes .. "m" end
  return minutes .. "m " .. seconds .. "s"
end
