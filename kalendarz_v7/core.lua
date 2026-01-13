calendar = calendar or {}

calendar.domain = calendar.domain or nil
calendar.json_file_path = calendar.json_file_path or (getMudletHomeDir() .. "/my_calendar.json")
calendar.gamehour_real_time = calendar.gamehour_real_time or 120
calendar.recalibration_tolerance_minutes = calendar.recalibration_tolerance_minutes or 110
calendar.cache = calendar.cache or {}
calendar.observed_sun_times = calendar.observed_sun_times or { imperial = {}, ishtar = {} }
calendar.state = calendar.state or {
  last_sync_ts = 0,
  script_load_time = 0,
  last_daylight_status = {},
  last_domain_change_ts = 0,
}

calendar.string2int = {
  ["pierwszy"] = 1,
  ["pierwsza"] = 1,
  ["drugi"] = 2,
  ["druga"] = 2,
  ["trzeci"] = 3,
  ["trzecia"] = 3,
  ["czwarty"] = 4,
  ["czwarta"] = 4,
  ["piaty"] = 5,
  ["piata"] = 5,
  ["szosty"] = 6,
  ["szosta"] = 6,
  ["siodmy"] = 7,
  ["siodma"] = 7,
  ["osmy"] = 8,
  ["osma"] = 8,
  ["dziewiaty"] = 9,
  ["dziewiata"] = 9,
  ["dziesiaty"] = 10,
  ["dziesiata"] = 10,
  ["jedenasty"] = 11,
  ["jedenasta"] = 11,
  ["dwunasty"] = 12,
  ["dwunasta"] = 12,
  ["trzynasty"] = 13,
  ["trzynasta"] = 13,
  ["czternasty"] = 14,
  ["czternasta"] = 14,
  ["pietnasty"] = 15,
  ["szesnasty"] = 16,
  ["siedemnasty"] = 17,
  ["osiemnasty"] = 18,
  ["dziewietnasty"] = 19,
  ["dwudziesty"] = 20,
  ["dwudziesty pierwszy"] = 21,
  ["dwudziesty drugi"] = 22,
  ["dwudziesty trzeci"] = 23,
  ["dwudziesty czwarty"] = 24,
  ["dwudziesty piaty"] = 25,
  ["dwudziesty szosty"] = 26,
  ["dwudziesty siodmy"] = 27,
  ["dwudziesty osmy"] = 28,
  ["dwudziesty dziewiaty"] = 29,
  ["trzydziesty"] = 30,
  ["trzydziesty pierwszy"] = 31,
  ["trzydziesty drugi"] = 32,
  ["trzydziesty trzeci"] = 33,
  ["trzydziesty czwarty"] = 34,
  ["trzydziesty piaty"] = 35,
  ["trzydziesty szosty"] = 36,
  ["trzydziesty siodmy"] = 37,
  ["trzydziesty osmy"] = 38,
  ["trzydziesty dziewiaty"] = 39,
  ["czterdziesty"] = 40,
  ["czterdziesty pierwszy"] = 41,
  ["czterdziesty drugi"] = 42,
  ["czterdziesty trzeci"] = 43,
  ["czterdziesty czwarty"] = 44,
  ["czterdziesty piaty"] = 45,
}

function calendar.recompute_year_time()
  for _, cal in pairs({ calendar.imperial, calendar.ishtar }) do
    if cal and cal.config then
      cal.config.year_time = cal.config.days_in_year * 24 * calendar.gamehour_real_time
    end
  end
end

function calendar.get_day_start_ts(cal, day_num)
  if not cal.data.offset or cal.data.offset == 0 then return 0 end
  return cal.data.offset + ((day_num - 1) * 24 * calendar.gamehour_real_time)
end

function calendar.get_timestamp_for_time(cal, day, minutes_into_day)
  local day_start = calendar.get_day_start_ts(cal, day)
  local sec_per_game_min = calendar.gamehour_real_time / 60
  return day_start + (minutes_into_day * sec_per_game_min)
end

function calendar.get_current_game_time_info(cal)
  if not cal.data.offset or cal.data.offset == 0 then return nil end
  local now = getEpoch()
  local sec_per_day = 24 * calendar.gamehour_real_time
  local elapsed = (now - cal.data.offset) % cal.config.year_time
  local day = math.floor(elapsed / sec_per_day) + 1
  local minutes = math.floor((elapsed % sec_per_day) / (calendar.gamehour_real_time / 60))
  return { day = day, minutes = minutes }
end

function calendar.recalibrate_by_event(cal_name, event_type)
  if not cal_name or not calendar[cal_name] then return end
  local cal = calendar[cal_name]
  local now = getEpoch()

  if now - (calendar.state.last_sync_ts or 0) < 30 then return end

  local info = calendar.get_current_game_time_info(cal) or { day = 1, minutes = 0 }
  local sun = calendar.get_sunrise_sunset(cal, info.day)
  local target_min = calendar.time_to_minutes(event_type == "sunrise" and sun.sunrise or sun.sunset)

  local new_dur = calendar.calculate_true_hour_duration(cal_name)
  if new_dur and math.abs(new_dur - 125.1314) < 10 then
    calendar.gamehour_real_time = new_dur
    calendar.recompute_year_time()
  end

  local sec_per_day = 24 * calendar.gamehour_real_time
  local sec_per_min = calendar.gamehour_real_time / 60
  local total_game_sec_passed = ((info.day - 1) * sec_per_day) + (target_min * sec_per_min)

  cal.data.offset = now - total_game_sec_passed
  cal.data.precision = 1
  calendar.domain = cal_name

  local domain = cal.config.domain
  calendar.observed_sun_times[domain] = calendar.observed_sun_times[domain] or {}
  calendar.observed_sun_times[domain][tostring(info.day)] = {
    [event_type] = calendar.minutes_to_time(target_min),
    [event_type .. "_real_ts"] = now,
  }

  calendar.state.last_sync_ts = now
  if Pix then Pix:whisper("Zsynchronizowano precyzyjnie!", "light_cyan", "🌒") end
  calendar.save_local_time_data()
  calendar.reload_calendar(cal)
end

function calendar.refresh_calendar(cal, d, h)
  local now = getEpoch()
  local sec_per_day = 24 * calendar.gamehour_real_time
  local sec_per_hour = calendar.gamehour_real_time
  local total_game_sec = ((d - 1) * sec_per_day) + (h * sec_per_hour)
  cal.data.offset = now - total_game_sec
  cal.data.precision = 59
  calendar.domain = cal.config.domain
  calendar.save_local_time_data()
  return calendar.reload_calendar(cal)
end

function calendar.display_full_time_info(cal, day, hour, filters, n)
  local now = getEpoch()
  local d_num, h_num = tonumber(day), tonumber(hour)

  local sun_today = calendar.get_sunrise_sunset(cal, d_num)
  local sun_tomorrow = calendar.get_sunrise_sunset(cal, (d_num % cal.config.days_in_year) + 1)

  local sunrise_today_ts = calendar.get_timestamp_for_time(cal, d_num, calendar.time_to_minutes(sun_today.sunrise))
  local sunset_today_ts = calendar.get_timestamp_for_time(cal, d_num, calendar.time_to_minutes(sun_today.sunset))
  local sunrise_tomorrow_ts = calendar.get_timestamp_for_time(cal, d_num + 1, calendar.time_to_minutes(sun_tomorrow.sunrise))

  local next_sunrise_ts, next_sunset_ts
  local cur_min = h_num * 60

  if cur_min < calendar.time_to_minutes(sun_today.sunrise) then
    next_sunrise_ts, next_sunset_ts = sunrise_today_ts, sunset_today_ts
  elseif cur_min < calendar.time_to_minutes(sun_today.sunset) then
    next_sunrise_ts, next_sunset_ts = sunrise_tomorrow_ts, sunset_today_ts
  else
    next_sunrise_ts = sunrise_tomorrow_ts
    next_sunset_ts = calendar.get_timestamp_for_time(cal, d_num + 1, calendar.time_to_minutes(sun_tomorrow.sunset))
  end

  local season = calendar.get_current_season(cal, d_num)
  local month = calendar.get_month_info(cal, d_num)
  local next_events = calendar.get_next_n_events(n or 3, filters)
  local line_sep = "<slate_grey>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━<reset>"

  cecho("\n" .. line_sep .. "\n            <white>..:: " .. cal.config.name .. " ::..\n")
  cecho(string.format("          <dim_grey>(%d. %s, dzien %d/%d)<reset>\n", month.day, month.name, d_num, cal.config.days_in_year))
  cecho(line_sep .. "\n")
  cecho(string.format("<light_steel_blue>Godzina: <white>%02d:00          <light_steel_blue>Pora Roku: <white>%s\n", h_num, season))
  cecho(string.format("<gold>Nastepny swit: <white>%s (za %s)  ", os.date("%H:%M", next_sunrise_ts), calendar.resttime(next_sunrise_ts - now)))
  cecho(string.format("<gold>Nastepny zmierzch: <white>%s (za %s)\n", os.date("%H:%M", next_sunset_ts), calendar.resttime(next_sunset_ts - now)))
  cecho(line_sep .. "\n")
  cecho("<light_steel_blue>NADCHODZACE WYDARZENIA:\n")
  for _, e in ipairs(next_events) do
    cecho(string.format("  %s<%s>%-20s <yellow>-> <wheat>za %-10s <gray>(%s)\n", calendar.get_prefix(e.type), e.color, e.desc, calendar.resttime(e.timestamp - now), os.date("%H:%M %d.%m", e.timestamp)))
  end
  cecho(line_sep .. "\n")
end

function calendar.show_calendar_results(filters, n)
  local cal = calendar[calendar.domain]
  local info = calendar.get_current_game_time_info(cal)
  if info then
    calendar.display_full_time_info(cal, info.day, math.floor(info.minutes / 60), filters, n)
  else
    cecho("\n<orange>[Kalendarz] Brak synchronizacji! Uzyj /czas! <dzien> <godzina><reset>\n")
  end
end

function calendar.reload_calendar(cal)
  if not cal.data.offset or cal.data.offset == 0 then return cal end
  cal.data.results = {}
  local now = getEpoch()
  local sec_per_year = cal.config.year_time

  for _, v in pairs(cal.config.search_times) do
    local t = calendar.get_timestamp_for_time(cal, v.day, v.hour * 60)
    while t < now do t = t + sec_per_year end
    table.insert(cal.data.results, {
      desc = v.desc,
      timestamp = t,
      color = v.color,
      type = v.type,
      game_date = "(" .. calendar.get_gamedate(cal, v.day, v.hour) .. ")",
    })
  end
  table.sort(cal.data.results, function(a, b) return a.timestamp < b.timestamp end)
  return cal
end

function calendar.get_events_results()
  calendar.reload_calendar(calendar.imperial)
  calendar.reload_calendar(calendar.ishtar)
  local union = calendar.table_n_union(calendar.imperial.data.results, calendar.ishtar.data.results)
  table.sort(union, function(a, b) return a.timestamp < b.timestamp end)
  return union
end

function calendar.get_next_n_events(n, filters)
  local union = calendar.get_events_results()
  local res = {}
  local now = getEpoch()
  for _, e in ipairs(union) do
    if (not filters or calendar.table_contains(filters, e.type)) and e.timestamp > now then
      table.insert(res, e)
      if #res == n then break end
    end
  end
  return res
end

function calendar.get_prefix(type)
  local arr = string.split(type, "_")
  local domain = arr[#arr]
  if domain == "imperial" then return "<aquamarine>[<light_goldenrod>Imperium<aquamarine>]<reset> " end
  if domain == "ishtar" then return "<aquamarine>[<cornflower_blue>Ishtar  <aquamarine>]<reset> " end
  return ""
end

function calendar.check_filters(filters)
  if not filters or #filters == 0 then return false end
  local first_prefix = calendar.get_prefix(filters[1])
  if first_prefix == "" then return true end
  for i = 2, #filters do
    if first_prefix ~= calendar.get_prefix(filters[i]) then return false end
  end
  return true
end

function calendar.strip_colors(str)
  if not str then return "" end
  return str:gsub("<[^>]+>", "")
end

function calendar.get_monthday(cal, day)
  local cache_key = cal.config.domain .. "_monthday_" .. tostring(day)
  if calendar.cache[cache_key] then return calendar.cache[cache_key] end
  if not cal.config.sorted_months then return { day = 0, month = "blad" } end
  local sorted_months = cal.config.sorted_months
  local month_info = { day = 0, month = "nieznany" }
  for i = #sorted_months, 1, -1 do
    if day >= sorted_months[i].start then
      month_info = { day = day - sorted_months[i].start + 1, month = sorted_months[i].name }
      break
    end
  end
  calendar.cache[cache_key] = month_info
  return month_info
end

function calendar.get_gamedate(cal, ds, h)
  local dd = calendar.get_monthday(cal, tonumber(ds))
  return dd.day .. ". " .. dd.month .. " o " .. calendar.format_24h(tonumber(h)) .. " [" .. ds .. "]"
end

function calendar.get_current_season(cal, day)
  local current_season = "Nieznana"
  if not cal.config.seasons then return current_season end
  for _, season in ipairs(cal.config.seasons) do
    if tonumber(day) >= tonumber(season.day) then current_season = season.name else break end
  end
  return current_season
end

function calendar.get_month_info(cal, day)
  local cache_key = cal.config.domain .. "_monthinfo_" .. tostring(day)
  if calendar.cache[cache_key] then return calendar.cache[cache_key] end
  if not cal.config.sorted_months then return { name = "Blad", day = 0, length = 0 } end
  local sorted_months = cal.config.sorted_months
  local current_month = { name = "Unknown", day = 0, length = 0 }
  for i = #sorted_months, 1, -1 do
    local month = sorted_months[i]
    if day >= month.start then
      current_month.name = month.name
      current_month.day = day - month.start + 1
      if i < #sorted_months then current_month.length = sorted_months[i + 1].start - month.start
      else current_month.length = cal.config.days_in_year - month.start + 1 end
      break
    end
  end
  calendar.cache[cache_key] = current_month
  return current_month
end

function calendar.get_sunrise_sunset(cal, day)
  local domain = cal.config.domain
  local observed = calendar.observed_sun_times[domain] and calendar.observed_sun_times[domain][tostring(day)]
  if observed and observed.sunrise and observed.sunset then return observed end

  local cache_key = domain .. "_sun_" .. tostring(day)
  if calendar.cache[cache_key] and not observed then return calendar.cache[cache_key] end

  local cycle = {}
  for _, v in ipairs(cal.config.sun_cycle) do table.insert(cycle, v) end
  table.sort(cycle, function(a, b) return a.day < b.day end)

  local p1, p2
  if day < cycle[1].day then
    p1, p2 = cycle[#cycle], cycle[1]
  else
    for i = 1, #cycle do
      if day >= cycle[i].day then
        p1 = cycle[i]
        p2 = (i == #cycle) and cycle[1] or cycle[i + 1]
      else
        break
      end
    end
  end

  if not p1 or not p2 then return { sunrise = "06:00", sunset = "18:00" } end

  local total_days = (p2.day < p1.day) and (cal.config.days_in_year - p1.day) + p2.day or p2.day - p1.day
  local result
  if total_days == 0 then
    result = { sunrise = p1.sunrise, sunset = p1.sunset }
  else
    local days_into = (day < p1.day) and (cal.config.days_in_year - p1.day) + day or day - p1.day
    local progress = days_into / total_days
    local sunrise1, sunset1 = calendar.time_to_minutes(p1.sunrise), calendar.time_to_minutes(p1.sunset)
    local sunrise2, sunset2 = calendar.time_to_minutes(p2.sunrise), calendar.time_to_minutes(p2.sunset)
    local current_sunrise = calendar.minutes_to_time(sunrise1 + (sunrise2 - sunrise1) * progress)
    local current_sunset = calendar.minutes_to_time(sunset1 + (sunset2 - sunset1) * progress)
    result = { sunrise = current_sunrise, sunset = current_sunset }
  end

  if observed then
    if observed.sunrise then result.sunrise = observed.sunrise end
    if observed.sunset then result.sunset = observed.sunset end
  end
  calendar.cache[cache_key] = result
  return result
end

function calendar.calculate_true_hour_duration(cal_name)
  local domain = calendar[cal_name].config.domain
  local obs = calendar.observed_sun_times[domain]
  if not obs then return nil end

  local days = {}
  for d, data in pairs(obs) do
    if data.sunrise_real_ts then table.insert(days, tonumber(d)) end
  end
  table.sort(days)
  if #days < 2 then return nil end

  local first_day = tostring(days[1])
  local last_day = tostring(days[#days])
  local start_data = obs[first_day]
  local end_data = obs[last_day]

  local real_seconds_diff = end_data.sunrise_real_ts - start_data.sunrise_real_ts
  local game_days_diff = tonumber(last_day) - tonumber(first_day)
  if game_days_diff < 0 then game_days_diff = game_days_diff + calendar[cal_name].config.days_in_year end

  local start_game_min = calendar.time_to_minutes(start_data.sunrise)
  local end_game_min = calendar.time_to_minutes(end_data.sunrise)
  local total_game_minutes = (game_days_diff * 24 * 60) + (end_game_min - start_game_min)
  if total_game_minutes <= 0 then return nil end

  local true_hour_duration = (real_seconds_diff / total_game_minutes) * 60
  if Pix and math.abs(true_hour_duration - calendar.gamehour_real_time) > 0.001 then
    Pix:whisper(string.format("Autokalibracja: 1h gry = %.4f sekundy.", true_hour_duration), "light_cyan", "⚖️")
  end
  return true_hour_duration
end

function calendar.save_local_time_data()
  local data = {
    imperial_offset = calendar.imperial.data.offset,
    ishtar_offset = calendar.ishtar.data.offset,
    observed_sun_times = calendar.observed_sun_times,
    gamehour_real_time = calendar.gamehour_real_time,
  }
  local file = io.open(calendar.json_file_path, "w")
  if file then
    file:write(yajl.to_string(data))
    file:close()
  end
end

function calendar.read_local_time_data()
  if not io.exists(calendar.json_file_path) then return end
  local file = io.open(calendar.json_file_path, "r")
  local data = yajl.to_value(file:read("*a"))
  file:close()
  if data then
    calendar.gamehour_real_time = data.gamehour_real_time or calendar.gamehour_real_time
    calendar.imperial.data.offset = data.imperial_offset or 0
    calendar.ishtar.data.offset = data.ishtar_offset or 0
    calendar.observed_sun_times = data.observed_sun_times or { imperial = {}, ishtar = {} }
    calendar.recompute_year_time()
    calendar.reload_calendar(calendar.imperial)
    calendar.reload_calendar(calendar.ishtar)
  end
end

function calendar.init_gmcp()
  event_handlers = event_handlers or {}
  if event_handlers["calendar_time"] then killAnonymousEventHandler(event_handlers["calendar_time"]) end
  event_handlers["calendar_time"] = registerAnonymousEventHandler("gmcp.room.time", calendar.handle_gmcp_time)
  if event_handlers["calendar_domain"] then killAnonymousEventHandler(event_handlers["calendar_domain"]) end
  event_handlers["calendar_domain"] = registerAnonymousEventHandler("gmcp.room.info.map", calendar.handle_gmcp_domain)
end

function calendar.handle_gmcp_time()
  if getEpoch() - calendar.state.script_load_time < 10 then return end
  local domain = calendar.domain
  if not domain or not calendar[domain] then return end

  local daylight = gmcp.room.time.daylight
  local last = calendar.state.last_daylight_status[domain]

  if last == nil then
    calendar.state.last_daylight_status[domain] = daylight
    return
  end

  if daylight == last then return end
  if getEpoch() - calendar.state.last_domain_change_ts < 5 then
    calendar.state.last_daylight_status[domain] = daylight
    return
  end

  local event_type = daylight and "sunrise" or "sunset"
  if Pix then
    local event_desc = (event_type == "sunrise") and "Czuje wschodzace sloneczko!" or "O, sloneczko idzie spac!"
    Pix:whisper(event_desc, "light_cyan", "🌒")
  end
  calendar.recalibrate_by_event(domain, event_type)
  calendar.state.last_daylight_status[domain] = daylight
end

function calendar.handle_gmcp_domain()
  if not (gmcp and gmcp.room and gmcp.room.info and gmcp.room.info.map and gmcp.room.info.map.domain) then return end

  local mapped
  if gmcp.room.info.map.domain == "Imperium" then mapped = "imperial"
  elseif gmcp.room.info.map.domain == "Ishtar" then mapped = "ishtar" end
  if not mapped then return end

  if calendar.domain ~= mapped then
    calendar.domain = mapped
    calendar.state.last_domain_change_ts = getEpoch()
    calendar.cache = {}
  end

  if calendar.state.last_daylight_status[mapped] == nil and gmcp.room.time and gmcp.room.time.daylight ~= nil then
    calendar.state.last_daylight_status[mapped] = gmcp.room.time.daylight
  end
end

function calendar.init()
  calendar.state.script_load_time = getEpoch()
  calendar.recompute_year_time()
  for _, cal in pairs({ calendar.imperial, calendar.ishtar }) do
    cal.config.sorted_months = {}
    for name, start in pairs(cal.config.first_day_of_calparts) do
      table.insert(cal.config.sorted_months, { name = name, start = start })
    end
    table.sort(cal.config.sorted_months, function(a, b) return a.start < b.start end)
  end
  calendar.read_local_time_data()
  calendar.init_gmcp()
end
