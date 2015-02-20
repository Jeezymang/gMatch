function GMatch:SearchForPlayers( )
	timer.Create( "GMatch:SearchForPlayers", GMatch.Config.PlayerSearchInterval, 0, function( )
		local playerCount = #player.GetAll( )
		if ( playerCount < GMatch.Config.RequiredPlayers ) then
			local remainPlayers = GMatch.Config.RequiredPlayers - playerCount
			self:BroadcastCenterMessage( remainPlayers .. " more players are required before the match can begin.", 5, Color( 175, 45, 45 ) )
		else
			self:BroadcastCenterMessage( "The round has begun!", 5, Color( 125, 45, 45 ) )
			timer.Destroy( "GMatch:SearchForPlayers" )
			GMatch:BeginRound( )
		end
	end )
end

function GMatch:BeginRound( )
	local roundLength = GMatch.Config.RoundLength
	local overrideLength = hook.Call( "OnBeginRoundTimer", GM, roundLength )
	if ( overrideLength ) then roundLength = overrideLength end
	GMatch.GameData.RoundLength = roundLength
	timer.Create( "GMatch:OngoingRound", roundLength, 1, function( )
		local roundWinner = hook.Call( "OnRoundCheckWinner", GM )
		if ( roundWinner ) then
			if ( tonumber( roundWinner ) ) then
				self:BroadcastCenterMessage( team.GetName( tonumber( roundWinner ) ) .. " has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
				
			elseif ( IsValid( roundWinner ) ) then
				self:BroadcastCenterMessage( roundWinner:Name( ) .. " has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
				roundWinner:SetGameStat( "Wins", roundWinner:GetGameStat( "Wins" ) + 1 )
			end
		end
		hook.Call( "OnEndRound", GM, #player.GetAll( ) )
		self:BroadcastCenterMessage( "The round is now over!", 5, Color( 175, 45, 45 ) )
		GMatch:SearchForPlayers( )
		GMatch:DisableTimers( )
		GMatch:CheckForGameSwitch( )
		GMatch:CheckForMapSwitch( )
	end )
	hook.Call( "OnBeginRound", GM, #player.GetAll( ) )
	GMatch:InitiateTimers( )
end

function GMatch:CheckForGameSwitch( )
	GMatch.GameData.FinishedRounds = GMatch.GameData.FinishedRounds or 0
	GMatch.GameData.FinishedRounds = GMatch.GameData.FinishedRounds + 1
	GMatch:SetGameVar( "FinishedRounds", GMatch.GameData.FinishedRounds, true )
	if ( GMatch.GameData.FinishedRounds % GMatch.Config.RoundAmountPerGameSwitch == 0 ) then
		self:BeginGameVote( )
	end
end

function GMatch:CheckForMapSwitch( )
	GMatch.GameData.FinishedRounds = GMatch.GameData.FinishedRounds or 0
	GMatch.GameData.FinishedRounds = GMatch.GameData.FinishedRounds + 1
	GMatch:SetGameVar( "FinishedRounds", GMatch.GameData.FinishedRounds, true )
	if ( GMatch.GameData.FinishedRounds % GMatch.Config.RoundAmountPerMapSwitch == 0 ) then
		self:BeginMapVote( )
	end
end

function GMatch:FinishRound( roundWinner )
	if ( roundWinner ) then
		if ( tonumber( roundWinner ) ) then
			self:BroadcastCenterMessage( team.GetName( tonumber( roundWinner ) ) .. " Team has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
		elseif ( IsValid( roundWinner ) ) then
			self:BroadcastCenterMessage( roundWinner:Name( ) .. " has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
			roundWinner:SetGameStat( "Wins", victim:GetGameStat( "Wins" ) + 1 )
		end
	end
	hook.Call( "OnFinishRound", GM, roundWinner )
	timer.Destroy( "GMatch:OngoingRound" )
	GMatch:CheckForGameSwitch( )
	GMatch:CheckForMapSwitch( )
	GMatch:SearchForPlayers( )
	GMatch:DisableTimers( )
end

function GMatch:BroadcastCenterMessage( text, len, col, isRainbow, font )
	for index, ply in ipairs ( player.GetAll( ) ) do
		ply:PrintCenterMessage( text, len, col, isRainbow, font )
	end
end

function GMatch:BroadcastNotify( txt, length, iconPath, textColor, panelColor, isRainbow, font )
	for index, ply in ipairs ( player.GetAll( ) ) do
		ply:DisplayNotify( txt, length, iconPath, textColor, panelColor, isRainbow, font )
	end
end

function GMatch:SetGameVar( name, val, networked )
	GMatch.GameData.GameVars[name] = val
	if not ( networked ) then return end
	GMatch.GameData.NetworkedGameVars = GMatch.GameData.NetworkedGameVars or { }
	GMatch.GameData.NetworkedGameVars[name] = val
	local valType = type( val )
	if ( valType == "Player" or valType == "Weapon" ) then valType = "Entity" end
	if not ( GMatch.GameVarTypes[ valType ] ) then ErrorNoHalt( "Invalid GameVar type defined.\n" ) return end
	local varFunc = GMatch.GameVarTypes[ valType ]
	net.Start( "GMatch:ManipulateGameVars" )
		net.WriteUInt( NET_VARS_SEND, 16 )
		net.WriteString( name )
		net.WriteString( valType )
		varFunc( val )
	net.Broadcast( )
end

function GMatch:BeginGameVote( )
	if ( GMatch.GameData.GameVoteStarted or timer.Exists( "GMatch:GameSwitchTimer" ) ) then return end
	GMatch.GameData.GameVotes = { }
	GMatch.GameData.GameVoteStarted = true
	net.Start( "GMatch:ManipulateGameVotes" )
		net.WriteUInt( NET_GAMEVOTES_OPEN, 16 )
	net.Broadcast( )
	timer.Create( "GMatch:GameVoteTimer", GMatch.Config.GameVoteLength, 1, function( )
		net.Start( "GMatch:ManipulateGameVotes" )
			net.WriteUInt( NET_GAMEVOTES_CLOSE, 16 )
		net.Broadcast( )
		local voteTable = { }
		for steamID, gameName in pairs ( GMatch.GameData.GameVotes ) do
			local curValue = voteTable[gameName] or 0
			curValue = curValue + 1
			voteTable[gameName] = curValue
		end
		GMatch.GameData.GameVotes = { }
		GMatch.GameData.GameVoteStarted = false
		local winningGame = table.GetWinningKey( voteTable )
		if not ( winningGame ) then
			GMatch:BroadcastCenterMessage( "Nobody voted for a gamemode.", 5 )
			return
		end
		local winnerName = GMatch.Config.Gamemodes[winningGame].name
		if ( winningGame == gMatchGameFolder ) then
			GMatch:BroadcastCenterMessage( "The current gamemode, " .. winnerName .. ", has won the vote.", 5 )
		else
			GMatch:BroadcastCenterMessage( winnerName .. " has won the vote.", 5 )
			local gameSwitchTime = GMatch.Config.TimeUntilGameSwitch
			GMatch:BroadcastCenterMessage( "The new gamemode will begin in " .. string.NiceTime( gameSwitchTime ) .. ".", 5 )
			GMatch:SetGameVar("GameSwitchTime", gameSwitchTime, true )
			timer.Create( "GMatch:GameSwitchTimer", GMatch.Config.TimeUntilGameSwitch, 1, function( )
				RunConsoleCommand( "gamemode", winningGame )
				RunConsoleCommand( "changelevel", game.GetMap( ) )
			end )
		end
	end )
end

function GMatch:BeginMapVote( )
	if ( GMatch.GameData.MapVoteStarted or timer.Exists( "GMatch:MapSwitchTimer" ) ) then return end
	GMatch.GameData.MapVotes = { }
	GMatch.GameData.MapVoteStarted = true
	net.Start( "GMatch:ManipulateMapVotes" )
		net.WriteUInt( NET_MAPVOTES_OPEN, 16 )
	net.Broadcast( )
	timer.Create( "GMatch:MapVoteTimer", GMatch.Config.GameVoteLength, 1, function( )
		net.Start( "GMatch:ManipulateMapVotes" )
			net.WriteUInt( NET_MAPVOTES_CLOSE, 16 )
		net.Broadcast( )
		local voteTable = { }
		for steamID, mapName in pairs ( GMatch.GameData.MapVotes ) do
			local curValue = voteTable[mapName] or 0
			curValue = curValue + 1
			voteTable[mapName] = curValue
		end
		GMatch.GameData.MapVotes = { }
		GMatch.GameData.MapVoteStarted = false
		local winningMap = table.GetWinningKey( voteTable )
		if not ( winningMap ) then
			GMatch:BroadcastCenterMessage( "Nobody voted for a map.", 5 )
			return
		end
		local winnerName = GMatch.Config.Maps[winningMap].name
		if ( winningMap == game.GetMap( ) ) then
			GMatch:BroadcastCenterMessage( "The current map, " .. winnerName .. ", has won the vote.", 5 )
		else
			GMatch:BroadcastCenterMessage( winnerName .. " has won the vote.", 5 )
			local mapSwitchTime = GMatch.Config.TimeUntilMapSwitch
			GMatch:BroadcastCenterMessage( "The new map will load in " .. string.NiceTime( mapSwitchTime ) .. ".", 5 )
			GMatch:SetGameVar("MapSwitchTime", mapSwitchTime, true )
			timer.Create( "GMatch:MapSwitchTimer", GMatch.Config.TimeUntilMapSwitch, 1, function( )
				RunConsoleCommand( "changelevel", winningMap )
			end )
		end
	end )
end

function GMatch:RespawnPlayers( )
	for index, ply in ipairs ( player.GetAll( ) ) do
		if ( ply:GetObserverMode( ) == OBS_MODE_CHASE ) then
			ply:UnSpectate( )
			ply.spectatingPlayer = nil
		end
		if ( ply:Alive( ) ) then
			ply:KillSilent( )
		end
		ply.spectatingPlayers = { }
		ply:Spawn( )
	end
end

function GMatch:GetSmallestTeam( )
	if ( !team.GetAllTeams( ) or #team.GetAllTeams( ) <= 0 ) then return 1 end
	local teamTable = { }
	for index, teamData in ipairs( team.GetAllTeams( ) ) do
		table.insert( teamTable, { teamEnum = index, plyCount = team.NumPlayers( index ) } ) 
	end
	table.SortByMember( teamTable, "plyCount", true )
	return teamTable[1].teamEnum
end

function GMatch:GenerateTeams( amt )
	local allTeams = team.GetAllTeams( )
	if ( #allTeams > 0 ) then
		for i = 1, #allTeams do
			team.GetAllTeams( )[i] = nil
		end
	end
	net.Start( "GMatch:ManipulateTeams" )
		net.WriteUInt( NET_TEAMS_CLEAR, 16 )
	net.Broadcast( )
	local amt = amt or 2
	if ( amt > #GMatch.Config.DefaultTeams ) then amt = #GMatch.Config.DefaultTeams end
	local shuffledTable = table.Shuffle( GMatch.Config.DefaultTeams )
	for i = 1, amt do
		local teamData = shuffledTable[i]
		team.SetUp( i, teamData.name, teamData.col )
		self:NetworkTeam( i, teamData.name, teamData.col )
	end
end

function GMatch:CreateTeams( teamTable )
	for index, teamData in ipairs ( teamTable ) do
		team.SetUp( index, teamData.name, teamData.col )
		self:NetworkTeam( index, teamData.name, teamData.col )
	end
end

function GMatch:AssignTeams( )
	for index, ply in ipairs ( player.GetAll( ) ) do
		local smallestTeam = self:GetSmallestTeam( )
		ply:SetTeam( smallestTeam )
	end
end

function GMatch:BroadcastColoredMessage( messTable )
	net.Start( "GMatch:ManipulateText" )
		net.WriteUInt( NET_TEXT_COLOREDMESSAGE, 16 )
		net.WriteTable( messTable )
	net.Broadcast( )
end