function GMatch:SearchForPlayers( )
	timer.Create( "GMatch:SearchForPlayers", self.Config.PlayerSearchInterval, 0, function( )
		local playerCount = #player.GetAll( )
		if ( playerCount < self.Config.RequiredPlayers ) then
			local remainPlayers = self.Config.RequiredPlayers - playerCount
			self:BroadcastCenterMessage( remainPlayers .. " more players are required before the match can begin.", 5, Color( 175, 45, 45 ) )
		else
			self:BroadcastCenterMessage( "The round has begun!", 5, Color( 125, 45, 45 ) )
			timer.Destroy( "GMatch:SearchForPlayers" )
			self:BeginRound( )
		end
	end )
end

function GMatch:BeginIntermission( )
	local intermissionLength = GMatch.Config.IntermissionLength
	local overrideLength = hook.Call( "OnBeginIntermissionTimer", GAMEMODE, intermissionLength )
	if ( overrideLength ) then intermissionLength = overrideLength end
	self.GameData.IntermissionLength = intermissionLength
	timer.Create( "GMatch:Intermission", intermissionLength, 1, function( )
		self:SetGameVar( "IntermissionActive", false, true )
		self:ToggleTimers( false, 0 )
		self:SearchForPlayers( )
	end )
	self:AlterTimerLength( timer.TimeLeft( "GMatch:Intermission" ), intermissionLength )
	self:BroadcastCenterMessage( "The next round will begin in " .. string.NiceTime( intermissionLength ) .. "!", 5, Color( 45, 125, 45 ) )
	self:SetGameVar( "IntermissionActive", true, true )
end

function GMatch:DestroyWarningTimers( )
	timer.Destroy( "GMatch:OneMinuteWarning" )
	timer.Destroy( "GMatch:ThirtySecondWarning" )
	timer.Destroy( "GMatch:TenSecondWarning" )
end

function GMatch:BeginRound( )
	if ( self.Config.RespawnAmount ) then
		for index, ply in ipairs ( player.GetAll( ) ) do
			ply:SetPlayerVar( "RespawnCount", 0, true )
		end
		self.GameData.RespawnTimes = { }
	end
	local roundLength = self.Config.RoundLength
	local overrideLength = hook.Call( "OnBeginRoundTimer", GAMEMODE, roundLength )
	if ( overrideLength ) then roundLength = overrideLength end
	self.GameData.RoundLength = roundLength
	if ( roundLength >= 60 ) then
		timer.Create( "GMatch:OneMinuteWarning", roundLength - 60, 1, function( )
			self:BroadcastSound( "halo/oneminuteremaining.mp3")
		end )
	end
	if ( roundLength >= 30 ) then
		timer.Create( "GMatch:ThirtySecondWarning", roundLength - 30, 1, function( )
			self:BroadcastSound( "halo/thirtysecondsremaining.mp3")
		end )
	end
	timer.Create( "GMatch:TenSecondWarning", roundLength - 10, 1, function( )
		self:BroadcastSound( "halo/tensecondsremaining.mp3")
	end )
	timer.Create( "GMatch:OngoingRound", roundLength, 1, function( )
		local roundWinner = hook.Call( "OnRoundCheckWinner", GAMEMODE )
		if ( roundWinner ) then
			if ( tonumber( roundWinner ) ) then
				self:BroadcastCenterMessage( team.GetName( tonumber( roundWinner ) ) .. " has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
				
			elseif ( IsValid( roundWinner ) ) then
				self:BroadcastCenterMessage( roundWinner:Name( ) .. " has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
				roundWinner:SetGameStat( "Wins", roundWinner:GetGameStat( "Wins" ) + 1 )
			end
		end
		hook.Call( "OnEndRound", GAMEMODE, #player.GetAll( ) )
		self:BroadcastCenterMessage( "The round is now over!", 5, Color( 175, 45, 45 ) )
		self:ToggleTimers( false, 0 )
		self:CheckForGameSwitch( )
		self:CheckForMapSwitch( )
		self:PlayEndRoundMusic( )
		self:SetGameVar( "RoundActive", false, true )
		self:BeginIntermission( )
		self:BroadcastSound( "halo/game_over.mp3" )
	end )
	hook.Call( "OnBeginRound", GAMEMODE, #player.GetAll( ) )
	self:InitiateTimers( )
	self:SetGameVar( "RoundActive", true, true )
end

function GMatch:CheckForGameSwitch( )
	self.GameData.FinishedRounds = self.GameData.FinishedRounds or 0
	self.GameData.FinishedRounds = self.GameData.FinishedRounds + 1
	self:SetGameVar( "FinishedRounds", self.GameData.FinishedRounds, true )
	if (self.GameData.FinishedRounds % self.Config.RoundAmountPerGameSwitch == 0 ) then
		self:BeginGameVote( )
	end
end

function GMatch:CheckForMapSwitch( )
	self.GameData.FinishedRounds = self.GameData.FinishedRounds or 0
	self.GameData.FinishedRounds = self.GameData.FinishedRounds + 1
	self:SetGameVar( "FinishedRounds", self.GameData.FinishedRounds, true )
	if ( self.GameData.FinishedRounds % self.Config.RoundAmountPerMapSwitch == 0 ) then
		self:BeginMapVote( )
	end
end

function GMatch:FinishRound( roundWinner )
	local roundWinner = roundWinner
	if not ( roundWinner ) then
		local closestWinner = hook.Call( "OnRoundCheckWinner", GAMEMODE )
		if ( closestWinner ) then roundWinner = closestWinner end
	end
	if ( roundWinner ) then
		if ( tonumber( roundWinner ) and team.NumPlayers( roundWinner ) > 0 ) then
			self:BroadcastCenterMessage( team.GetName( tonumber( roundWinner ) ) .. " Team has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
			local playerTable = team.GetPlayers( tonumber( roundWinner ) )
			for index, ply in ipairs ( playerTable ) do
				ply:SetGameStat( "Wins", ply:GetGameStat( "Wins", 0 ) + 1 )
			end
		elseif ( IsValid( roundWinner ) ) then
			self:BroadcastCenterMessage( roundWinner:Name( ) .. " has won the round!", 10, nil, true, "GMatch_Lobster_LargeBold" )
			roundWinner:SetGameStat( "Wins", roundWinner:GetGameStat( "Wins", 0 ) + 1 )
		end
	end
	hook.Call( "OnFinishRound", GAMEMODE, roundWinner )
	timer.Destroy( "GMatch:OngoingRound" )
	self:BroadcastSound( "halo/game_over.mp3" )
	self:DestroyWarningTimers( )
	self:CheckForGameSwitch( )
	self:CheckForMapSwitch( )
	self:ToggleTimers( false, 0 )
	self:PlayEndRoundMusic( )
	self:SetGameVar( "RoundActive", false, true )
	self:BeginIntermission( )
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

function GMatch:BroadcastSound( soundPath, plyTbl )
	net.Start( "GMatch:ManipulateMisc" )
		net.WriteUInt( NET_MISC_PLAYSOUND, 16 )
		net.WriteString( soundPath )
	net.Send( plyTbl or player.GetAll( ) )
end

function GMatch:SetGameVar( name, val, networked )
	self.GameData.GameVars[name] = val
	if not ( networked ) then return end
	self.GameData.NetworkedGameVars = GMatch.GameData.NetworkedGameVars or { }
	self.GameData.NetworkedGameVars[name] = val
	local valType = type( val )
	if ( valType == "Player" or valType == "Weapon" ) then valType = "Entity" end
	if not ( self.GameVarTypes[ valType ] ) then ErrorNoHalt( "Invalid GameVar type defined.\n" ) return end
	local varFunc = self.GameVarTypes[ valType ]
	net.Start( "GMatch:ManipulateGameVars" )
		net.WriteUInt( NET_VARS_SEND, 16 )
		net.WriteString( name )
		net.WriteString( valType )
		varFunc( val )
	net.Broadcast( )
end

function GMatch:BeginGameVote( )
	if ( self.GameData.GameVoteStarted or timer.Exists( "GMatch:GameSwitchTimer" ) ) then return end
	if ( self.GameData.MapVoteStarted or timer.Exists( "GMatch:MapSwitchTimer" ) ) then return end
	self.GameData.GameVotes = { }
	self.GameData.GameVoteStarted = true
	net.Start( "GMatch:ManipulateGameVotes" )
		net.WriteUInt( NET_GAMEVOTES_OPEN, 16 )
	net.Broadcast( )
	timer.Create( "GMatch:GameVoteTimer", self.Config.GameVoteLength, 1, function( )
		net.Start( "GMatch:ManipulateGameVotes" )
			net.WriteUInt( NET_GAMEVOTES_CLOSE, 16 )
		net.Broadcast( )
		local voteTable = { }
		for steamID, gameName in pairs ( self.GameData.GameVotes ) do
			local curValue = voteTable[gameName] or 0
			curValue = curValue + 1
			voteTable[gameName] = curValue
		end
		self.GameData.GameVotes = { }
		self.GameData.GameVoteStarted = false
		local winningGame = table.GetWinningKey( voteTable )
		if not ( winningGame ) then
			self:BroadcastCenterMessage( "Nobody voted for a gamemode.", 5 )
			return
		end
		local winnerName = self.Config.Gamemodes[winningGame].name
		if ( winningGame == gMatchGameFolder ) then
			self:BroadcastCenterMessage( "The current gamemode, " .. winnerName .. ", has won the vote.", 5 )
		else
			self:BroadcastCenterMessage( winnerName .. " has won the vote.", 5 )
			local gameSwitchTime = GMatch.Config.TimeUntilGameSwitch
			self:BroadcastCenterMessage( "The new gamemode will begin in " .. string.NiceTime( gameSwitchTime ) .. ".", 5 )
			self:SetGameVar("GameSwitchTime", gameSwitchTime, true )
			timer.Simple( self.Config.TimeUntilGameSwitch * 0.75, function( )
				self:SaveAllPlayerStats( 0.15 )
			end )
			timer.Create( "GMatch:GameSwitchTimer", self.Config.TimeUntilGameSwitch, 1, function( )
				RunConsoleCommand( "gamemode", winningGame )
				RunConsoleCommand( "changelevel", game.GetMap( ) )
			end )
		end
	end )
end

function GMatch:BeginMapVote( )
	if ( self.GameData.MapVoteStarted or timer.Exists( "GMatch:MapSwitchTimer" ) ) then return end
	if ( self.GameData.GameVoteStarted or timer.Exists( "GMatch:GameSwitchTimer" ) ) then return end
	self.GameData.MapVotes = { }
	self.GameData.MapVoteStarted = true
	net.Start( "GMatch:ManipulateMapVotes" )
		net.WriteUInt( NET_MAPVOTES_OPEN, 16 )
	net.Broadcast( )
	timer.Create( "GMatch:MapVoteTimer", self.Config.GameVoteLength, 1, function( )
		net.Start( "GMatch:ManipulateMapVotes" )
			net.WriteUInt( NET_MAPVOTES_CLOSE, 16 )
		net.Broadcast( )
		local voteTable = { }
		for steamID, mapName in pairs ( self.GameData.MapVotes ) do
			local curValue = voteTable[mapName] or 0
			curValue = curValue + 1
			voteTable[mapName] = curValue
		end
		self.GameData.MapVotes = { }
		self.GameData.MapVoteStarted = false
		local winningMap = table.GetWinningKey( voteTable )
		if not ( winningMap ) then
			self:BroadcastCenterMessage( "Nobody voted for a map.", 5 )
			return
		end
		local winnerName = self.Config.Maps[winningMap].name
		if ( winningMap == game.GetMap( ) ) then
			self:BroadcastCenterMessage( "The current map, " .. winnerName .. ", has won the vote.", 5 )
		else
			self:BroadcastCenterMessage( winnerName .. " has won the vote.", 5 )
			local mapSwitchTime = self.Config.TimeUntilMapSwitch
			self:BroadcastCenterMessage( "The new map will load in " .. string.NiceTime( mapSwitchTime ) .. ".", 5 )
			self:SetGameVar("MapSwitchTime", mapSwitchTime, true )
			timer.Simple( self.Config.TimeUntilMapSwitch * 0.75, function( )
				self:SaveAllPlayerStats( 0.15 )
			end )
			timer.Create( "GMatch:MapSwitchTimer", self.Config.TimeUntilMapSwitch, 1, function( )
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
	if ( !team.GetAllTeams( ) or #team.GetAllTeams( ) <= 0 ) then return 1001 end
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
	if ( amt > #self.Config.DefaultTeams ) then amt = #Gself.Config.DefaultTeams end
	local shuffledTable = table.Shuffle( self.Config.DefaultTeams )
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

function GMatch:StartRespawningEntityTimer( spawnRate, spawnChance )
	timer.Create( "GMatch:EntityRespawningTimer", spawnRate, 0, function( ) 
		for id, entTbl in pairs ( self.GameData.RespawningEntities or { } ) do
			if ( IsValid( entTbl.ent ) ) then continue end
			local spawnChance = math.Clamp( spawnChance, 1, 100 )
			local randomRoll = math.random( 100 )
			if ( randomRoll > spawnChance ) then continue end
			local respawnEnt = ents.Create( entTbl.class )
			if ( entTbl.class == "prop_physics" ) then
				respawnEnt:SetModel( entTbl.model )
			end
			respawnEnt:Spawn( )
			respawnEnt:Activate( )
			respawnEnt.respawnID = id
			respawnEnt:SetPos( entTbl.pos )
			respawnEnt:SetAngles( entTbl.ang )
			local physObj = respawnEnt:GetPhysicsObject( )
			if ( physObj:IsValid( ) and entTbl.frozen ) then physObj:EnableMotion( false ) end
			self.GameData.RespawningEntities[id].ent = respawnEnt
		end
	end )
end

function GMatch:SpawnPersistentEntities( resultSet )
	for index, data in ipairs ( resultSet ) do
		local persistEnt = ents.Create( data.class )
		if ( data.class == "prop_physics" ) then
			persistEnt:SetModel( data.model )
		end
		persistEnt:Spawn( )
		persistEnt:Activate( )
		persistEnt.persistID = data.id
		local entPos = Vector( tonumber( data.x ), tonumber( data.y ), tonumber( data.z ) )
		local entAng = Angle( tonumber( data.pitch ), tonumber( data.yaw ), tonumber( data.roll ) )
		persistEnt:SetPos( entPos )
		persistEnt:SetAngles( entAng )
		local physObj = persistEnt:GetPhysicsObject( )
		if ( physObj:IsValid( ) and tobool( tonumber( data.frozen ) ) ) then physObj:EnableMotion( false ) end
	end
end

function GMatch:SpawnRespawnableEntities( resultSet )
	for index, data in ipairs ( resultSet ) do
		self.GameData.RespawningEntities = GMatch.GameData.RespawningEntities or { }
		self.GameData.RespawningEntities[tonumber( data.id )] = {
			ent = nil,
			class = data.class,
			model = data.model,
			pos = Vector( tonumber( data.x ), tonumber( data.y ), tonumber( data.z ) ),
			ang = Angle( tonumber( data.pitch ), tonumber( data.yaw ), tonumber( data.roll ) ),
			frozen = tobool( tonumber( data.frozen ) )
		}
	end
end

function GMatch:PlayEndRoundMusic( )
	if not ( self.Config.EnableEndRoundMusic ) then return end
	net.Start( "GMatch:ManipulateMisc" )
		net.WriteUInt( NET_MISC_TRIGGERENDGAMEMUSIC, 16 )
		net.WriteUInt( math.random( #self.Config.EndRoundMusicURLs ), 16 )
	net.Broadcast( )
end

function GMatch:SaveAllPlayerStats( increment )
	self:BroadcastNotify( "Beginning to save stats for all online players.", 4, "icon16/wrench.png" )
	local saveTimerIncrement = increment
	local savedPlayerCount = 0
	for index, ply in ipairs ( player.GetAll( ) ) do
		if ( ply:IsBot( ) ) then return end
		timer.Simple( saveTimerIncrement, function( )
			if not ( IsValid( ply ) ) then return end
			ply:SaveGameStats( )
		end )
		savedPlayerCount = savedPlayerCount + 1
		saveTimerIncrement = saveTimerIncrement + increment
	end
	local saveTime = savedPlayerCount * increment
	timer.Simple( saveTime, function( ) 
		self:BroadcastNotify( "Saved stats for " .. savedPlayerCount .. " players. ( " .. string.NiceTime( saveTime ) .. " elapsed. )", 4, "icon16/comment.png" )
	end )
end

function GMatch:DidTeamGainLead( teamIndex, oldScore, newScore, valueFunc )
	local sortedTable = { }
	local scoreTable = { }
	for _teamIndex, teamTbl in pairs ( team.GetAllTeams( ) ) do
		if ( _teamIndex == teamIndex ) then continue end
		table.insert( sortedTable, { teamIndex = _teamIndex, value = valueFunc( _teamIndex ) } )
		scoreTable[ valueFunc( _teamIndex ) ] = scoreTable[ valueFunc( _teamIndex ) ] or { }
		table.insert( scoreTable[ valueFunc( _teamIndex ) ], _teamIndex )
	end
	table.SortByMember( sortedTable, "value", false )
	local highestScore = sortedTable[1].value
	if ( newScore == highestScore ) then
		self:BroadcastSound( "halo/tiedtheleader.mp3", team.GetPlayers( teamIndex ) )
	elseif ( oldScore <= highestScore and newScore > highestScore ) then
		self:BroadcastSound( "halo/gainedthelead.mp3", team.GetPlayers( teamIndex ) )
		for index, _teamIndex in pairs ( scoreTable[ highestScore ] ) do
			self:BroadcastSound( "halo/lost_the_lead.mp3", team.GetPlayers( _teamIndex ) )
		end
	end
end