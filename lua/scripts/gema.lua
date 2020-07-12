PLUGIN_NAME = "SvearkMod in Lua - Modified by Baruch"
PLUGIN_AUTHOR = "Sveark, Baruch" -- sveark@gmail.com, hlepouse@gmail.com
PLUGIN_VERSION = "16 dec 2012"

--[[

This a modification from Sveark's script, available here : http://sveark.info/ac/Lua/
You can use and modify this script for your server, but please quote Sveark and myself (Baruch) in the script, with e-mails.
Thanks to Dietrich for telling me about the webnet77 database.
Thanks to CriticalMachine for testing some codes on his gema server.
Thanks to .:HsOs:. clan for first hosting this script.

The ip localization uses webnet77 website database  (http://webnet77.com/). Thanks a lot for their amazing work.
You can download the newest version of the database (IpToCountry.csv) here : http://software77.net/cgi-bin/ip-country/geo-ip.pl?action=download
Just replace the oldest by the newest, in the ./lua/config directory.

This script was originally made for .:HsOs:. clan gema server.

Baruch

]]

-- common

function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

start_times = {}
flagspam = {}

function pretty_split(text)
    local splitted_text = split(text, " ")
    for index, subtext in ipairs(splitted_text) do
        if subtext == "" then
            table.remove(splitted_text, index)
        end
    end
    return splitted_text
end

function say(text, cn)
  if cn == nil then cn = -1 end
  clientprint(cn, text)
end

function slice(array, S, E)
  local result = {}
  local length = #array
  S = S or 1
  E = E or length
  if E < 0 then
    E = length + E + 1
  elseif E > length then
    E = length
  end
  if S < 1 or S > length then
    return {}
  end
  local i = 1
  for j = S, E do
    result[i] = array[j]
    i = i + 1
  end
  return result
end

function isip(s) -- checks if a given string can be interpreted as an ip
    local splitted_ip = split(s,".")
    if #splitted_ip ~= 4 then
        return false
    end
    for k = 1, 4 do
        local n = tonumber(splitted_ip[k])
        if n == nil then
            return false
        end
        if n < 0 or n > 255 then
            return false
        end
    end
    return true
end

function printfile(path)
    -- local file = assert(io.open(path, "r"), "File " .. path .. " not found"))
    for line in io.lines(path) do
        say(line)
    end
end

function cnadmin()
    for i = 0, maxclient() - 1 do
        if isadmin(i) then
            return i
        end
    end
    return nil
end


-- interface to the records

function sorted_records(records)
  local sorted_records = {}
  for player, delta in pairs(records) do
    table.insert(sorted_records, { player, delta })
  end
  table.sort(sorted_records, function (L, R) return L[2] < R[2] end)
  return sorted_records
end

function add_record(map, player, delta)
  local records = load_records(map)
  if records[player] == nil or delta < records[player] then
    records[player] = delta
    save_records(map, records)
  end
end

function save_records(map, records)
  local sorted_records = sorted_records(records)
  local lines = {}
  for i,record in ipairs(sorted_records) do
    table.insert(lines, record[1] .. " " .. tostring(record[2]))
  end
  cfg.setvalue("SvearkMod_maps", map:lower():gsub("=", ""), table.concat(lines, "\t"))
end

function load_records(map)
  local records = {}
  local data = cfg.getvalue("SvearkMod_maps", map:lower():gsub("=", ""))
  if data ~= nil then
    local lines = split(data, "\t")
    for i,line in ipairs(lines) do
      record = split(line, " ")
      records[record[1]] = tonumber(record[2])
    end
  end
  return records
end

function get_best_record(map)
    local sorted_records = sorted_records(load_records(map)) -- marche, renvoie {}
    if #sorted_records == 0 then
        return nil, nil
    else
        local i, best_record = next(sorted_records)
        return best_record[1], best_record[2]
    end
end

function mapbest(cn)
    local player, delta = get_best_record(getmapname())
    if player ~= nil then
        local modulo = delta % 60000
        say(string.format("\f1The best time for this map is \f2%02d:%02d:%03d \f1(recorded by \f2%s\f1)", delta / 60000, modulo / 1000, modulo % 1000, player), cn)
    else
        say("\f1No best time found for this map", cn)
    end
end

function sendMOTD(cn)
    if cn == nil then cn = -1 end
    say("Welcome to Gema Haven ! Join us on discord.gg/gVbE2wm", cn)
    say("\f1Type \f2!cmds \f1to see available server commands", cn)
    mapbest(cn)
    commands["!mybest"][1](cn, {})
end

-- commands
-- params: { admin right, modo right, common right, show message in chat }

commands =
 {
  ["!cmds"] =
  {
    function (cn, args)
		  say("\f1Available commands : \f2!reset \fP| \f2!mybest \fP| \f2!maptop \fP| \f2!best \f1<cn> \fP| \f2!ext \f1<time>", cn)
	 end
  };

  ["!ext"] =
  {
    function (cn, args)
      if #args == 1 then
        local time_ext = tonumber(args[1])
        if time_ext > 0 and time_ext <= 60 then
          settimeleft(math.min(gettimeleft() + time_ext + 1, 60))
        end
      end
    end
  };

  ["!mapbest"] =
  {
    function (cn, args)
      local player, delta = get_best_record(getmapname())
      if player ~= nil then
        local modulo = delta % 60000
        say(string.format("\f1The best time for this map is \f2%02d:%02d:%03d \f1(recorded by \f2%s\f1)", delta / 60000, modulo / 1000, modulo % 1000, player), cn)
      else
        say("\f1No best time found for this map", cn)
      end
    end
  };

  ["!mybest"] =
  {
    function (cn, args)
      local records = load_records(getmapname())
      local delta = records[getname(cn)]
      if delta == nil then
        say("\f1No private record found for this map", cn)
      else
        local rank = 1
        for player, record in pairs(records) do
            if record < delta then rank = rank + 1 end
        end
        local suffixe = "th"
        if rank == 1 then suffixe = "st" end
        if rank == 2 then suffixe = "nd" end
        if rank == 3 then suffixe = "rd" end
        local modulo = delta % 60000
        say(string.format("\f1Your best time for this map is \f2%02d:%02d:%03d \f1(\f2%d%s \f3place\f1)", delta / 60000, modulo / 1000, modulo % 1000, rank, suffixe), cn)
      end
    end
  };

  ["!maptop"] =
  {
    function (cn, args)
      local sorted_records = sorted_records(load_records(getmapname()))
      if next(sorted_records) == nil then
        say("\f1Map top is empty", cn)
      else
        say("\f1Fastest players of this map :", cn)
        for i, record in ipairs(sorted_records) do
          if i > 5 then break end
          local modulo = record[2] % 60000
          say(string.format("\f1%d. \f2%s \f0%02d:%02d:%03d", i, record[1], record[2] / 60000, modulo / 1000, modulo % 1000), cn)
        end
      end
    end
  };

  ["!best"] =
  {
    function (cn, args)
        if #args ~= 1 then
            say("\f3Invalid format", cn)
            return
        end
        local target_cn = tonumber(args[1])
        local records = load_records(getmapname())
        local delta = records[getname(target_cn)]
        if delta == nil then
            say("\f1No record found for this map", cn)
        else
        local rank = 1
        for player, record in pairs(records) do
            if record < delta then rank = rank + 1 end
        end
        local suffixe = "th"
        if rank == 1 then suffixe = "st" end
        if rank == 2 then suffixe = "nd" end
        if rank == 3 then suffixe = "rd" end
        local modulo = delta % 60000
        say(string.format("\f1The best time of player \f2%s \f1for this map is \f2%02d:%02d:%03d \f1(%d%s place)", getname(target_cn), delta / 60000, modulo / 1000, modulo % 1000, rank, suffixe), cn)
      end
    end
  };

  ["!reset"] =
  {
    function (cn, args)
        sdropflag(cn)
        flagspam[getip(cn)] = nil
        sendspawn(cn)
        start_times[cn] = getsvtick()
    end
  };

  }

function isGema(mapname)
  local s = string.lower(mapname)
  if string.find(s, "gema") ~= nil then return true end
  if string.find(s, "g3ma") ~= nil then return true end
  if string.find(s, "gem4") ~= nil then return true end
  if string.find(s, "g3m4") ~= nil then return true end
  return false
end

-- handlers

function onPlayerSayText(cn, text)
  local parts = split(text, " ")
  local command, args = parts[1], slice(parts, 2)
  if commands[command] ~= nil then
    local callback = commands[command][1]
    callback(cn, args)
    return PLUGIN_BLOCK       
  elseif string.byte(command,1) == string.byte("!",1) then
    return PLUGIN_BLOCK
  end
end

function onPlayerConnect(cn)
    sendMOTD(cn)
    setautoteam(false)
end

function onFlagActionBefore(cn, action, flag)
  if action == FA_STEAL and flagspam[getip(cn)] ~= nil then
    return PLUGIN_BLOCK
  end
end

function onFlagAction(cn, action, flag)
  if action == FA_SCORE then
    if start_times[cn] == nil then
        return
    end
    local delta = getsvtick() - start_times[cn]
    start_times[cn] = nil
    if delta == 0 then return end
    local records = load_records(getmapname())
    local previous_score = records[getname(cn)]
    if previous_score == nil then previous_score = delta end
    add_record(getmapname(), getname(cn), delta)
    if previous_score >= delta then
        local rank = 1
        for player, record in pairs(records) do
            if record < delta then rank = rank + 1 end
        end
        local suffixe = "th"
        if rank == 1 then suffixe = "st" end
        if rank == 2 then suffixe = "nd" end
        if rank == 3 then suffixe = "rd" end
        local modulo = delta % 60000
        say(string.format("\fX[CM~SERVER] \f3\fb\%s \f1SCORED AFTER\f3 %02d\fH min\f3 %02d\fH sec\f3 %02d \f1Your current position is \fX(\fP%d%s\fH place\fX)", getname(cn), delta / 60000, modulo / 1000, modulo % 1000, rank, suffixe))
    else
        local modulo = delta % 60000
        say(string.format("\fX[CM~SERVER] \f3\fb\%s \f1SCORED AFTER\f3 %02d\fH min\f3 %02d\fH sec\f3 %02d \f1(but has a better record)", getname(cn), delta / 60000, modulo / 1000, modulo % 1000))
    end
    local best_player, best_delta = get_best_record(getmapname())
    if best_delta == delta then
        say("\f2******** \fP\fbNEW BEST TIME RECORDED! \f2********")
    end
  elseif action == FA_DROP or action == FA_LOST then
    flagaction(cn, FA_RESET, flag)
  elseif action == FA_STEAL then
    flagspam[getip(cn)] = 1
  end
end

function onPlayerSpawn(cn)
    start_times[cn] = getsvtick()
    flagspam[getip(cn)] = nil
end

function onPlayerDamage(actor_cn, target_cn, damage, actor_gun, gib)
  if actor_cn ~= target_cn then
    return PLUGIN_BLOCK
  end
end

function onPlayerCallVote(cn, type, text, number)
    if type == SA_AUTOTEAM and not getautoteam() then
        voteend(VOTE_NO)
    elseif (type == SA_FORCETEAM) or (type == SA_SHUFFLETEAMS) then
        voteend(VOTE_NO)
    elseif type == SA_MAP then
        if number ~= GM_CTF then
            voteend(VOTE_NO)
        elseif not isGema(text) then
            say("\f3This map doesn't seem to be a gema", cn)
            voteend(VOTE_NO)
        end
    elseif type == SA_MASTERMODE then
        if number ~= 0 then
            voteend(VOTE_NO)
        end
    end
end