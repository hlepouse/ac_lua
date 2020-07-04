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

include("ac_server")

pickuprespawn = {}
players_to_kick = {}
players_to_ban = {}
gfragging_stats = {}
countries = {}
iptocountry = {}
start_times = {}
gemakills = {}
flagspam = {}
auto = {}
maprot = getwholemaprot()
maprot_modified = false
modos = {}
nextmap = nil

kick_delay = 50


function pretty_split(text)
    local splitted_text = split(text, " ")
    for index, subtext in ipairs(splitted_text) do
        if subtext == "" then
            table.remove(splitted_text, index)
        end
    end
    return splitted_text
end

function ismodo(cn)
    if modos[cn] == "ok" then
        return true
    else
        return false
    end
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

---

function sendMOTD(cn)
    if cn == nil then cn = -1 end
    --say("This server runs with the SvearkMod script, modified by .:HsOs:.Baruch (hlepouse@gmail.com)", cn)
    say("\f1Type \f2!cmds \f1to see available server commands", cn)
    mapbest(cn)
    commands["!mybest"][2](cn, {})
end

-- commands
-- params: { admin right, modo right, common right, show message in chat }

commands =
 {
  ["!cmds"] =
  {
    { true, true, true, true };
    function (cn, args)
        say("\fP----------------------------------------------------------------------------------------", cn)
		say("\f1Available commands : \f2!mybest \fP| \f2!maptop \fP| \f2!gtop \fP| \f2!grank \fP| \f2!best \f1 <cn> \fP| \f4~ \fP|", cn)
        say("\fP----------------------------------------------------------------------------------------", cn)
		say("\f1Available commands : \f2!pm \f1<cn> <text> \fP| \f2!login \f1<password> \fP| \f4~~~~~~~~~~ \fP|", cn)
        say("\fP----------------------------------------------------------------------------------------", cn)
		if ismodo(cn) then
            say("\f0Moderator commands : \f2!ext \f1<minutes> \fP| \f2!f1 \fP| \f2!f2 \fP| \f2!logout \fP| \f2!removebans   \fP|", cn)
	    if ismodo(cn) then say("\fP----------------------------------------------------------------------------------------", cn)
		if isadmin(cn) then
			say("\f3Admin commands : \f2!ext \f1<minutes> \fP| \f2!bl \f1<cn or ip> <reason> \fP| \f4~~~~~~~~~~ \fP|", cn)
        if isadmin(cn) then say("\fP----------------------------------------------------------------------------------------", cn)
		if isadmin(cn) then
         	say("\f3Admin commands : \f2!promote \f1<cn> \fP| \f2!demote \f1<cn> \fP| \f3!autokick \f1<ON>  <OFF> \fP|", cn)
	    if isadmin(cn) then say("\fP----------------------------------------------------------------------------------------", cn)
		end
    end
	end
	end
	end
	end
	end
  };

  ["!ext"] =
  {
    { true, true, false, false };
    function (cn, args)
      if #args == 1 then
        settimeleft(tonumber(args[1]))
      end
    end
  };

  ["!pm"] =
  {
    { true, true, true, false };
    function (cn, args)
        if (#args < 2) then return end
        local to, text = tonumber(args[1]), table.concat(args, " ", 2)
        if (not isconnected(to)) then return end
        say(string.format("\f1PM from \f2%s (%d)\f1 : \fM%s", getname(cn), cn, text), to)
        say(string.format("\f1PM for \f2%s \f1has been sent", getname(to)), cn)
    end
  };

  ["!mapbest"] =
  {
    { true, true, true, false };
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
    { true, true, true, false };
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
    { true, true, true, false };
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

  ["!bl"] =
  {
    { true, false, false, false };
    function (cn, args)
        if #args == 0 then
            say("\f3Invalid format", cn)
            return
        end
        local target_cn = tonumber(args[1])
        local ip = ""
        if target_cn == nil then
            if isip(args[1]) then
                ip = args[1]
            else
                say("\f3Invalid format", cn)
                return
            end
        else
            if isconnected(target_cn) then
                ip = getip(target_cn)
            else
                say("\f3Player " .. args[1] .. " isn't connected", cn)
                return
            end
        end
        local file = io.open("./config/serverblacklist.cfg", "a+")
        if file == nil then
            say("\f3File serverblacklist.cfg not found", cn)
            return
        end
        if auto["cn"] ~= nil then return end
        local time = os.date("[%d %b %Y %H:%M]")
        local line = "\n" .. ip .. " // " .. time
        if target_cn == nil then
            if #args > 1 then
                local reason = table.concat(args, " ", 2)
                line = line .. " - " .. reason
            end
            say("\f3IP " .. ip .. " is now blacklisted", cn)
        else
            line = line .. " " .. getname(target_cn)
            if #args > 1 then
                local reason = table.concat(args, " ", 2)
                line = line .. " - " .. reason
            end
            say("\f3Player " .. getname(target_cn) .. " with IP " .. ip .. " has been blacklisted", cn)
        end
        line = line .. " (added by " .. getname(cn) .. " )"
        file:write(line)
        file:close()
        if target_cn ~= nil then
            local name = getname(target_cn)
            table.insert(players_to_ban, target_cn)
            for i = 0, maxclient() - 1 do
                if isconnected(i) and i ~= target_cn and i ~= cn then
                    say(string.format("\f3Player \f2%s \f3has been blacklisted", name), i)
                end
            end
        end
    end
  };

  ["!maptime"] =
  {
    { true, false, false, false };
    function (cn, args)
        if #args ~= 1 then
            say("\f3Invalid format", cn)
            return
        end
        local i,t = findMap()
        if i == nil then
            say("\f3This map isn't in maprot", cn)
            return
        end
        t["time"] = args[1]
        if args[1] == 1 then
            say("\f3The map time in maprot has been set to " .. args[1] .. " minute", cn)
        else
            say("\f3The map time in maprot has been set to " .. args[1] .. " minutes", cn)
        end
    end
  };

  ["!addmap"] =
  {
    { true, false, false, false };
    function (cn, args)
        if #args > 1 then
            say("\f3Invalid format", cn)
            return
        end
        local i,t = findMap()
        if i ~= nil then
            say("\f3This map is already in maprot", cn)
            return
        end
        local time = 15
        if #args[1] ~= nil then time = args[1] end
        maprot[maprotSize()+1] = { ["map"] = getmapname(), ["mode"] = 5, ["time"] = time, ["allowVote"] = 1, ["minplayer"] = 1, ["maxplayer"] = 20, ["skiplines"] = 0 }
        maprot_modified = true
        say("\f3This map has been added to maprot", cn)
    end
  };

  ["!removemap"] =
  {
    { true, false, false, false };
    function (cn, args)
        if #args ~= 0 then
            say("\f3Invalid format", cn)
            return
        end
        local i,t = findMap()
        if i == nil then
            say("\f3This map isn't in maprot", cn)
            return
        end
        table.remove(maprot, i)
        maprot_modified = true
        say("\f3This map has been removed from maprot", cn)
    end
  };

  ["!inmaprot"] =
  {
    { true, false, false, false };
    function (cn, args)
        if #args ~= 0 then
            say("\f3Invalid format", cn)
            return
        end
        local i,t = findMap()
        if i == nil then
            say("\f3This map isn't in maprot", cn)
        else
            say("\f3This map is in maprot", cn)
        end
    end
  };

  ["!reloadmaprot"] =
  {
    { true, false, false, false };
    function (cn, args)
        maprot = getwholemaprot()
        maprot_modified = false
        say("\f3Maprot has been reloaded from maprot.cfg", cn)
    end
  };

  ["!login"] =
  {
    { true, true, true, false };
    function (cn, args)
        if #args ~= 1 then
            say("\f3Invalid format", cn)
            return
        end
        local file = io.open("./config/modos.cfg")
        if file == nil then
            say("\f3Login failed", cn)
            return
        end
        local not_found = true
        for line in file:lines() do
            local splitted_line = pretty_split(line)
            if splitted_line[1] == args[1] then
                not_found = false
            end
        end
        if not_found then
            say("\f3Login failed", cn)
        else
            say("\f3" .. getname(cn) .. " is now moderator")
            modos[cn] = "ok"
        end
    end
  };

  ["!logout"] =
  {
    { false, true, false, false };
    function (cn, args)
        if #args ~= 0 then
            say("\f3Invalid format", cn)
            return
        end
        modos[cn] = nil
    end
  };

  ["!promote"] =
  {
    { true, false, false, false };
    function (cn, args)
        if #args ~= 1 then
            say("\f3Invalid format", cn)
            return
        end
        local target_cn = tonumber(args[1])
        if isconnected(target_cn) then
            say("\f3" .. getname(target_cn) .. " is now moderator")
            modos[target_cn] = "ok"
        else
            say("\f3Player disconnected", cn)
        end
    end
  };

  ["!demote"] =
  {
    { true, false, false, false };
    function (cn, args)
        if #args ~= 1 then
            say("\f3Invalid format", cn)
            return
        end
        local target_cn = tonumber(args[1])
        if isconnected(target_cn) then
            say("\f3" .. getname(target_cn) .. " isn't moderator anymore", cn)
            say("\f3You're not moderator anymore", target_cn)
            modos[target_cn] = nil
        else
            say("\f3Player disconnected", cn)
        end
    end
  };

  ["!f1"] =
  {
    { false, true, false, false };
    function (cn, args)
        if #args ~= 0 then
            say("\f3Invalid format", cn)
            return
        end
        voteend(VOTE_YES)
    end
  };

  ["!f2"] =
  {
    { false, true, false, false };
    function (cn, args)
        if #args ~= 0 then
            say("\f3Invalid format", cn)
            return
        end
        voteend(VOTE_NO)
    end
  };

  ["!best"] =
  {
    { true, true, true, false };
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

  ["!skipmap"] =
  {
    { true, true, false, false };
    function (cn, args)
        if #args ~= 0 then
            say("\f3Invalid format", cn)
            return
        end
        --changemap(getmaprotnextmap(), GM_CTF, maptime)
    end
  };

  ["!autokick"] = 
  {
    { true, false, false, false };
    function (cn, args)
      if autokick then autokick = false else autokick = true end
      say("\f1AUTOKICK MODE IS TURNED " .. (autokick and "ON" or "OFF"), cn)
    end
  };
  
  ["!removebans"] =
  {
    { false, true, false, false };
    function (cn, args)
        if #args ~= 0 then
            say("\f3Invalid format", cn)
            return
        end
        removebans()
        say("\f3Bans have been removed", cn)
    end
  }
  }


function getCountry(cn)
    local splitted_ip = split(getip(cn), ".")
    splitted_ip[1] = tonumber(splitted_ip[1])
    splitted_ip[2] = tonumber(splitted_ip[2])
    splitted_ip[3] = tonumber(splitted_ip[3])
    splitted_ip[4] = tonumber(splitted_ip[4])
    local ip = splitted_ip[1]*2^24 + splitted_ip[2]*2^16 + splitted_ip[3]*2^8 + splitted_ip[4]
    local indexmin = 1
    local indexmax = sizeiptocountry
    while indexmin < indexmax do
        local index = math.floor((indexmin + indexmax) / 2)
        ipmin = iptocountry[index]["ipmin"]
        ipmax = iptocountry[index]["ipmax"]
        if ipmin <= ip then
            indexmin = index
        end
        if ipmax >= ip then
            indexmax = index
        end
    end
    return iptocountry[indexmin]["country"]
end

function loadIpToCountry()
    for line in io.lines("./lua/config/IpToCountry.csv") do
        local ascii = string.byte(line,1)
        if ascii ~= 32 and ascii ~= 35 then
            local splitted_line = split(line, "\"")
            table.insert(iptocountry, { ipmin = tonumber(splitted_line[2]),
                                        ipmax = tonumber(splitted_line[4]),
                                        country = splitted_line[14] } )
        end
    end
    sizeiptocountry = #iptocountry
end



function isGema(mapname)
    local s = string.lower(mapname)
   if string.find(s, "gema") ~= nil then return true end
   if string.find(s, "g3ma") ~= nil then return true end
   if string.find(s, "gem4") ~= nil then return true end
   if string.find(s, "g3m4") ~= nil then return true end
   return false
end

function findMap()
    for i,t in ipairs(maprot) do
        if t["map"] == getmapname() then return i,t end
    end
    return nil,nil
end

function maprotSize()
    local size = 0
    for i,t in ipairs(maprot) do
        size = size + 1
    end
    return size
end

function writeMaprot()
    local file = io.open("./config/maprot.cfg", "w+")
end

-- handlers

function onPlayerSayText(cn, text)
  local parts = split(text, " ")
  local command, args = parts[1], slice(parts, 2)
  if commands[command] ~= nil then
    local params, callback = commands[command][1], commands[command][2]
    if (isadmin(cn) and params[1]) or (ismodo(cn) and params[2]) or params[3] then
      callback(cn, args)
      if not params[4] then
        return PLUGIN_BLOCK
      elseif isadmin(cn) or ismodo(cn) then
        for i = 0, maxclient() - 1 do
            if isconnected(i) and i ~= cn then
                say("\fP" .. getname(cn) .. ": \f0" .. text, i)
            end
        end
        return PLUGIN_BLOCK
      end
    else
      return PLUGIN_BLOCK
    end
  elseif string.byte(command,1) == string.byte("!",1) then
    return PLUGIN_BLOCK
  elseif isadmin(cn) or ismodo(cn) then
    for i = 0, maxclient() - 1 do
        if isconnected(i) and i ~= cn then
            say("\fP" .. getname(cn) .. ": \f0" .. text, i)
        end
    end
    return PLUGIN_BLOCK
  end
end

function onMapChange(mapname, gamemode)
    sendMOTD()
    for ip,kills in pairs(gemakills) do
        gemakills[ip] = nil
    end
    nextmap = getnextmap()
    if maprot_modified then
        setwholemaprot(maprot)
        maprot_modified = false
    end
end

function onPlayerConnect(cn)
    countries[cn] = getCountry(cn)
    for i = 0, maxclient() - 1 do
        if isconnected(i) and i ~= cn then
                say(string.format("\fX[CM~SERVER] \f1Player \f2%s \f1connected from \f2%s", getname(cn), countries[cn]), i)
            end
        end
    sendMOTD(cn)
    setautoteam(false)
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
    local ip = getip(cn)
    if flagspam[ip] == nil then
        flagspam[ip] = 1
    else
        say("\f3Please don't flagspam", cn)
        flagspam[ip] = flagspam[ip] + 1
    end
    if flagspam[ip] >= 3 then
		table.insert(players_to_kick, cn)
    end
  end
end

function onPlayerSpawn(cn)
    start_times[cn] = getsvtick()
    flagspam[getip(cn)] = nil
end

autokick = true

function LuaLoop()

for i,id in ipairs(pickuprespawn) do
    spawnitem(id)
end
pickuprespawn = {}

 if not autokick or isadmin(acn) then return end
  for i, cn in ipairs(players_to_ban) do
    gfragging_stats[getip(cn)] = nil
    ban(cn) say(string.format("\fBBANNED BY THE SERVEUR , DON'T KILL ON GEMA !!!"))
  end
  players_to_ban = {}

  for i, cn in ipairs(players_to_kick) do
    disconnect(cn, DISC_FFIRE) say(string.format("\fBKICKED BY THE SERVEUR , DON'T KILL ON GEMA !!!"))
  end
  players_to_kick = {}
end

function onPlayerDeath(tcn, acn, gib, gun)
   if not autokick or isadmin(acn) then return end
  if acn ~= tcn then
    if gfragging_stats[getip(acn)] ~= nil then
      gfragging_stats[getip(acn)] = gfragging_stats[getip(acn)] + 1
    else
      gfragging_stats[getip(acn)] = 1
    end

    if gfragging_stats[getip(acn)] >= 3 then -- 3-rd kill results in a ban
      table.insert(players_to_ban, acn)
    else
      table.insert(players_to_kick, acn)
	end
end
end

function onPlayerCallVote(cn, type, text, number)
    if type == SA_AUTOTEAM and not getautoteam() then
        voteend(VOTE_NO)
        say("\f3You don't have the permission to set autoteam on", cn)
    elseif (type == SA_FORCETEAM) or (type == SA_SHUFFLETEAMS) then
        say("\f3You don't have the permission to vote that", cn)
        voteend(VOTE_NO)
    elseif type == SA_MAP then
        if number ~= GM_CTF then
            if number == 21 then
                if nextmap ~= nil then setnextmap(nextmap) end
                say("\f3You don't have the permission to use this command", cn)
            else
                say("\f3Only CTF mode is allowed", cn)
            end
            voteend(VOTE_NO)
        elseif not isGema(text) then
            say("\f3This map doesn't seem to be a gema", cn)
            voteend(VOTE_NO)
        elseif ismodo(cn) then
            voteend(VOTE_YES)
        end
    elseif type == SA_MASTERMODE and not isadmin(cn) then
        if number ~= 0 then
            say("\f3You don't have the permission to vote that", cn)
            voteend(VOTE_NO)
        end
    elseif type == SA_KICK and ismodo(cn) then
        voteend(VOTE_YES)
    elseif type == SA_BAN and ismodo(cn) then
        voteend(VOTE_YES)
    end
end

function onPlayerRoleChange(cn, new_role)
    if new_role == CR_ADMIN then
        modos[cn] = "ok"
    end
end

 function onPlayerItemPickup(cn, item_type, item_id)
    table.insert(pickuprespawn, item_id)
end

function onInit()
    loadIpToCountry()
end

function onPlayerDisconnect(cn, reason)
    for i,v in pairs(modos) do
        if i == cn then
            modos[i] = nil
        end
    end
end