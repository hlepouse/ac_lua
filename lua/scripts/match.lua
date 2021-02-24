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
	forcedeath(cn)
	setteam(cn, team, 1)
end

commands =
{
	["!cmds"] =
	{
		function (cn, args)
			say("\fPAvailable commands : \fY!sortteams \fP| \fY!switchteams \fP| \fY!bench <cn> \fP| \fY!unhits", cn)
		end
	};

	["!unhits"] =
	{
		function (cn, args)
        		say(string.format("\fPHitreg fix is \f0ENABLED \fP! Otherwise you would've lost \fY%i / \fY%i \fPshots", getunhits(cn), getshots(cn)), cn)
		end
	};

	["!bench"] =
	{
		function (cn, args)
			if not isadmin(cn) then
				return
			end
      			if #args == 1 then
				local player = tonumber(args[1])
				forceTeam(player, TEAM_SPECT)
			end
		end
	};

	["!switchteams"] =
	{
		function (cn, args)
			if not isadmin(cn) then
				return
			end
			for player in players() do
				local team = getteam(player)
				if team == TEAM_RVSF then
					forceTeam(player, TEAM_CLA)
				elseif team == TEAM_CLA then
					forceTeam(player, TEAM_RVSF)
				end
			end
		end
	};

	["!sortteams"] =
	{
		function (cn, args)

			if not isadmin(cn) then
				return
			end

			local playerName -- one active player name

			for player in players() do
				local team = getteam(player)
				if team == TEAM_RVSF or team == TEAM_CLA then
					playerName = getname(player)
					break
				end
			end

			if playerName == nil then
				return
			end

			local tagIndex -- the prefix length we need to check in order to differentiate the 2 teams

			for i = 1, playerName:len() do

				for player in players() do
					local team = getteam(player)
					if team == TEAM_RVSF or team == TEAM_CLA then
						if playerName:sub(1, i) ~= getname(player):sub(1, i) then
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
				local team = getteam(player)
				if team == TEAM_RVSF or team == TEAM_CLA then
					local player_cn = player
					if playerName:sub(1, tagIndex) == getname(player_cn):sub(1, tagIndex) then
						table.insert(team1, player_cn)
					else
						table.insert(team2, player_cn)
					end
				end
			end

			for i, player_cn in ipairs(team1) do
				forceTeam(player_cn, TEAM_RVSF)
			end

			for i, player_cn in ipairs(team2) do
				forceTeam(player_cn, TEAM_CLA)
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
	else
		for player in players() do
			if player ~= cn then
				say(getname(cn) .. "\f1#" .. cn .. "\fY: \f0" .. text, player)
			end
		end
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
