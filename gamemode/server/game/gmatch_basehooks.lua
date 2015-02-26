GM = GM or GAMEMODE
function GM:PostGamemodeLoaded( )
	GM = GM or GAMEMODE -- Ensure the GM table exists when the gamemode is loaded.
	GMatch:SearchForPlayers( )
	GMatch:IncludeAllFiles( gMatchGameFolder .. "/gamemode/")
	if ( GMatch.Config.AutoResourceContent ) then
		GMatch:AddGamemodeResources( )
	end
	GMatch:CreateTables( )
	if ( GMatch.Config.Maps[ game.GetMap( ) ] and GMatch.Config.Maps[ game.GetMap( ) ].workshopid ) then
		local workshopID = GMatch.Config.Maps[ game.GetMap( ) ].workshopid
		resource.AddWorkshop( workshopID )
	end
end

function GM:InitPostEntity( )
	local persistEntities, respawnEntities = GMatch:RetrieveMapEntities( )
	if ( persistEntities ) then
		GMatch:SpawnPersistentEntities( persistEntities )
	end
	if ( respawnEntities ) then
		GMatch:SpawnRespawnableEntities( respawnEntities )
	end
	GMatch:StartRespawningEntityTimer( GMatch.Config.EntityRespawnInterval, GMatch.Config.EntityRespawnChance )
end

function GM:OnReloaded( )
	self.BaseClass:OnReloaded( )
	if not ( gMatchGameFolder == "gmatch" ) then
		GMatch:IncludeAllFiles( gMatchGameFolder .. "/gamemode/" )
	end
end

function GM:PlayerInitialSpawn( ply )
	self.BaseClass:PlayerInitialSpawn( ply )
	local entIndex = ply:EntIndex( )
	timer.Create( "GMatch:StatSavingTimer_" .. entIndex, GMatch.Config.StatSavingInterval, 1, function( )
		if not ( IsValid( ply ) ) then
			timer.Destroy( "GMatch:StatSavingTimer_" .. entIndex )
		else
			if not ( ply.isInitialized ) then return end
			ply:SaveGameStats( )
		end
	end )
	if not ( ply:IsBot( ) ) then
		ply:SetTeam( 0 )
	else
		local assignTeam = hook.Call( "OnPlayerAssignTeam", GAMEMODE, ply )
		if ( assignTeam ) then ply:SetTeam( assignTeam )
		else ply:SetTeam( 1001 ) end
	end
end

function GM:PlayerSpawn( ply )
	player_manager.SetPlayerClass( ply, "gmatch_player_class" )
	self.BaseClass:PlayerSpawn( ply )
	ply.wasHeadshotted = false
	if ( ply:GetObserverMode( ) == OBS_MODE_CHASE ) then
		ply:UnSpectate( )
		ply.spectatingPlayer = nil
		ply:KillSilent( )
		ply:Spawn( )
	end
end

function GM:PlayerSelectSpawn( ply, spawnAttempts )
	local overrideSpawn = hook.Call( "OnSelectSpawnPoint", GAMEMODE, ply )
	if ( overrideSpawn ) then
		local posOffset = Vector( math.random( -256, 256 ), math.random( -256, 256 ), 0 )
		local newSpawn = overrideSpawn + posOffset
		local hullTrace = util.TraceHull( { start = newSpawn, endpos = newSpawn, mins = Vector( -16, -16, 0 ), maxs = Vector( 16, 16, 71 ) } )
		local traceRes = util.TraceLine( { start = overrideSpawn, endpos = newSpawn, filter = ply } )

		if ( hullTrace.Hit or traceRes.HitWorld ) then
			local spawnAttempts = spawnAttempts or 0
			spawnAttempts = spawnAttempts + 1
			if ( spawnAttempts > 50 ) then
				return self.BaseClass:PlayerSelectSpawn( ply )
			else
				self:PlayerSelectSpawn( ply, spawnAttempts )
			end
		else
			ply:SetPos( newSpawn )
		end
	else
		return self.BaseClass:PlayerSelectSpawn( ply )
	end
end

function GM:PlayerDeath( victim, inflictor, attacker, secondPass )
	self.BaseClass:PlayerDeath( victim, inflictor, attacker, true )
	victim:ResetKillSpreeProgress( )
	if ( victim == attacker and !secondPass ) then victim:SetGameStat( "Suicides", victim:GetGameStat( "Suicides" ) + 1 ) end
	if ( IsValid( attacker ) and attacker:IsPlayer( ) and attacker ~= victim and !secondPass ) then
		attacker:SetGameStat( "Kills", attacker:GetGameStat( "Kills" ) + 1 )
		attacker:IncrementKillSpreeProgress( 1 )
		victim:SetGameStat( "Deaths", victim:GetGameStat( "Deaths" ) + 1 )
	end
	if ( IsValid( victim ) and GMatch.Config.RespawnAmount and GMatch:IsRoundActive( ) and !secondPass ) then
		GMatch.GameData.RespawnTimes = GMatch.GameData.RespawnTimes or { }
		GMatch.GameData.RespawnTimes[ victim:EntIndex( ) ] = GMatch.GameData.RespawnTimes[ victim:EntIndex( ) ] or 0
		victim:SetPlayerVar( "RespawnCount", GMatch.GameData.RespawnTimes[ victim:EntIndex( ) ], true )
		GMatch.GameData.RespawnTimes[ victim:EntIndex( ) ] = GMatch.GameData.RespawnTimes[ victim:EntIndex( ) ] + 1
	end
	local respawnTime = GMatch.Config.RespawnTime
	local overrideTime = hook.Call( "OnSetRespawnTimer", GAMEMODE, victim, attacker )
	if ( overrideTime ) then respawnTime = overrideTime end
	victim.timeUntilRespawn = CurTime( ) + respawnTime
	net.Start( "GMatch:ManipulatePlayer" )
		net.WriteUInt( NET_PLAYER_SENDDEATHTIME, 16 )
		net.WriteUInt( respawnTime, 32 )
	net.Send( victim )
	if not ( GMatch.Config.EnablePlayerDeathSpectate ) then return end
	if ( istable( victim.spectatingPlayers ) ) then
		for steamID, ply in pairs ( victim.spectatingPlayers ) do
			if ( IsValid( ply ) ) then
				ply.spectatingPlayer = nil
				ply:SpectateRandomPlayer( )
				if not ( IsValid( ply.spectatingPlayer ) ) then
					ply:UnSpectate( )
				end
			end
		end
		victim.spectatingPlayers = { }
	end
	timer.Simple( GMatch.Config.TimeUntilSpectate, function( )
		if ( !IsValid( victim ) or victim:Alive( ) ) then return end
		if ( #player.GetAll( ) > 1 ) then
			victim:SpectateRandomPlayer( )
		end
	end )
end

function GM:PlayerDeathThink( ply )
	local canRespawn = true
	if ( GMatch.Config.RespawnAmount and GMatch:IsRoundActive( ) ) then
		GMatch.GameData.RespawnTimes = GMatch.GameData.RespawnTimes or { }
		GMatch.GameData.RespawnTimes[ ply:EntIndex( ) ] = GMatch.GameData.RespawnTimes[ ply:EntIndex( ) ] or 0
		if ( GMatch.Config.RespawnAmount < GMatch.GameData.RespawnTimes[ ply:EntIndex( ) ] ) then canRespawn = false end
	end
	ply.timeUntilRespawn = ply.timeUntilRespawn or ( CurTime( ) + GMatch.Config.RespawnTime )
	if ( ply.timeUntilRespawn > CurTime( ) or !canRespawn ) then
		return false
	else
		if ( ply:GetObserverMode( ) == OBS_MODE_CHASE ) then
			if ( IsValid( ply.spectatingPlayer ) ) then
				ply.spectatingPlayer.spectatingPlayers[ply:SteamID( )] = nil
			end
			ply.spectatingPlayer = nil
			ply:UnSpectate( )
		end
		self.BaseClass:PlayerDeathThink( ply )
	end
end

function GM:ScalePlayerDamage( ply, hitGroup, dmgInfo, secondPass )
	self.BaseClass:ScalePlayerDamage( ply, hitGroup, dmgInfo, true )
	if ( hitGroup == HITGROUP_HEAD and !secondPass ) then
		dmgInfo:ScaleDamage( 2 )
		local attacker = dmgInfo:GetAttacker( )
		if ( IsValid( attacker ) and attacker:IsPlayer( ) ) then
			local hpLeft = ( ply:Health( ) + ply:Armor( ) ) - dmgInfo:GetDamage( )
			if ( hpLeft <= 0 and !ply.wasHeadshotted ) then
				ply.wasHeadshotted = true
				attacker:SetGameStat( "Headshots", attacker:GetGameStat( "Headshots" ) + 1 )
				GMatch:BroadcastCenterMessage( attacker:Name( ) .. " has blew " .. ply:Name( ) .. "'s head off!", 5, nil, true, "GMatch_Lobster_LargeBold" )
			end 
		end
	end
end

function GM:PlayerDisconnected( ply )
	local tableIndex = ply:SteamID( )
	if ( ply:IsBot( ) ) then tableIndex = ply:UniqueID( ) end
	GMatch.GameData.PlayerVars[ tableIndex ] = nil
	GMatch.GameData.NetworkedPlayerVars = GMatch.GameData.NetworkedPlayerVars or { }
	GMatch.GameData.NetworkedPlayerVars[ tableIndex ] = nil
	ply:SaveGameStats( )
	timer.Simple( 0.1, function( ) // Welp, this is hacky.
		if ( timer.Exists( "GMatch:OngoingRound" ) ) then
			if ( #player.GetAll( ) == 0 ) then
				GMatch:FinishRound( )
			end
		end
	end )
end

function GM:KeyPress( ply, key )
	if ( key == IN_ATTACK and !ply:Alive( ) ) then
		if ( #player.GetAll( ) > 1 ) then
			ply:SpectateRandomPlayer( )
		end
	end
end