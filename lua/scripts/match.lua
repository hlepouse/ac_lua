PLUGIN_NAME = "Match Server"
PLUGIN_AUTHOR = "Baruch" -- hlepouse@gmail.com
PLUGIN_VERSION = "14 feb 2021"

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

function cnadmin()
    for i = 0, maxclient() - 1 do
        if isadmin(i) then
            return i
        end
    end
    return nil
end

-- commands
-- params: { admin right, modo right, common right, show message in chat }

function forceteam(cn, team)
	setteam(cn, team, 1)
end

commands =
 {
  ["!cmds"] =
  {
    function (cn, args)
		  say("\f1Available commands : \f2!sortteams \fP| \f2!switchteams", cn)
	 end
  };

  ["!switchteams"] =
  {
    function (cn, args)
    	for i = 0, maxclient() - 1 do
        	if isconnected(i) then
			team = getteam(i)
			if team == 0 then
				forceteam(i, 1)
			elseif team == 1 then
				forceteam(i, 0)
			end
		end
        end
    end
  };
}

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
    setautoteam(false)
end

function onFlagActionBefore(cn, action, flag)
  if action == FA_STEAL and flagspam[getip(cn)] ~= nil then
    return PLUGIN_BLOCK
  end
end
