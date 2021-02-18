PLUGIN_NAME = "Match Server"
PLUGIN_AUTHOR = "Baruch" -- hlepouse@gmail.com
PLUGIN_VERSION = "14 feb 2021"

-- common

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

-- commands
-- params: { admin right, modo right, common right, show message in chat }

function forceTeam(cn, team)
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
    	for player in rvsf() do
        forceTeam(player.player_cn, TEAM_CLA)
      end
      for player in cla() do
        forceTeam(player.player_cn, TEAM_RVSF)
      end
    end
  };

  ["!sortteams"] =
  {
    function (cn, args)

      local playerName -- one active player name

      for player in players() do
        if team == TEAM_RVSF or team == TEAM_CLA then
          playerName = getname(player.player_cn)
          break
        end
      end

      if playerName == nil then
        return
      end

      local tagIndex -- the prefix length we need to check in order to differentiate the 2 teams

      for i = 1, playerName:len() do

        for player in players() do
          if team == TEAM_RVSF or team == TEAM_CLA then
            if playerName:sub(1, i) ~= getname(player.player_cn):sub(1, i) then
              tagIndex = i
              break
            end
          end
        end

        if tagIndex ~= nil then
          break
        end

      end

      local team1 = {}
      local team2 = {}

      for player in players() do
        if team == TEAM_RVSF or team == TEAM_CLA then
          local player_cn = player.player_cn
          if playerName:sub(1, tagIndex) == getname(player_cn):sub(1, tagIndex) then
            table.insert(team1, player_cn)
          else
            table.insert(team2, player_cn)
          end
        end
      end

      for i, player_cn in ipairs(team1) do
        forceTeam(player_cn, TEAM_CLA)
      end

      for i, player_cn in ipairs(team2) do
        forceTeam(player_cn, TEAM_RVSF)
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

function onPlayerCallVote(cn, type, text, number)
  if type == SA_AUTOTEAM and not getautoteam() then
    voteend(VOTE_NO)
  end
end