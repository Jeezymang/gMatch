GM = GM or GAMEMODE
function GM:PostGamemodeLoaded( )
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
	local selectQuery = [[
	SELECT *
	FROM %s
	WHERE map = %s AND gamemode = %s;
	]]
	local resultSet = sql.Query( string.format( selectQuery, SQLStr( "gmatch_persist" ), SQLStr( game.GetMap( ) ), SQLStr( gMatchGameFolder ) ) )
	if ( resultSet ) then
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
	resultSet = sql.Query( string.format( selectQuery, SQLStr( "gmatch_respawnable" ), SQLStr( game.GetMap( ) ), SQLStr( gMatchGameFolder ) ) )
	if ( resultSet ) then
		for index, data in ipairs ( resultSet ) do
			GMatch.GameData.RespawningEntities = GMatch.GameData.RespawningEntities or { }
			GMatch.GameData.RespawningEntities[tonumber( data.id )] = {
				ent = nil,
				class = data.class,
				model = data.model,
				pos = Vector( tonumber( data.x ), tonumber( data.y ), tonumber( data.z ) ),
				ang = Angle( tonumber( data.pitch ), tonumber( data.yaw ), tonumber( data.roll ) ),
				frozen = tobool( tonumber( data.frozen ) )
			}
		end
	end
	timer.Create( "GMatch:EntityRespawningTimer", GMatch.Config.EntityRespawnInterval, 0, function( ) 
		for id, entTbl in pairs ( GMatch.GameData.RespawningEntities or { } ) do
			if ( IsValid( entTbl.ent ) ) then continue end
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
			GMatch.GameData.RespawningEntities[id].ent = respawnEnt
		end
	end )
end

function GM:OnReloaded( )
	if not ( gMatchGameFolder == "gmatch" ) then
		GMatch:IncludeAllFiles( gMatchGameFolder .. "/gamemode/" )
	end
end

function GM:PlayerInitialSpawn( ply )
	self.BaseClass:PlayerInitialSpawn( ply )
	--GMatch:RetrievePlayerStats( ply )
	local entIndex = ply:EntIndex( )
	timer.Create( "GMatch:StatSavingTimer_" .. entIndex, GMatch.Config.StatSavingInterval, 1, function( )
		if not ( IsValid( ply ) ) then
			timer.Destroy( "GMatch:StatSavingTimer_" .. entIndex )
		else
			if not ( ply.isInitialized ) then return end
			ply:SaveGameStats( )
		end
	end )
end

util.AddNetworkString( "SendFuckingPlayerClass" )
function GM:PlayerSpawn( ply )
	player_manager.SetPlayerClass( ply, "gmatch_player_class" )
	self.BaseClass:PlayerSpawn( ply )
	if ( ply:GetObserverMode( ) == OBS_MODE_CHASE ) then
		ply:UnSpectate( )
		ply.spectatingPlayer = nil
		ply:KillSilent( )
		ply:Spawn( )
	end
end

function GM:PlayerSelectSpawn( ply, spawnAttempts )
	local overrideSpawn = hook.Call( "OnSelectSpawnPoint", GM, ply )
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
	local respawnTime = GMatch.Config.RespawnTime
	local overrideTime = hook.Call( "OnSetRespawnTimer", GM, victim, attacker )
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
	ply.timeUntilRespawn = ply.timeUntilRespawn or ( CurTime( ) + GMatch.Config.RespawnTime )
	if ( ply.timeUntilRespawn > CurTime( ) ) then
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
			if ( hpLeft <= 0 ) then
				attacker:SetGameStat( "Headshots", attacker:GetGameStat( "Headshots" ) + 1 )
				GMatch:BroadcastCenterMessage( attacker:Name( ) .. " has blew " .. ply:Name( ) .. "'s head off!", 5, nil, true, "GMatch_Lobster_LargeBold" )
			end 
		end
	end
end

function GM:PlayerDisconnected( ply )
	timer.Simple( 0.1, function( ) // Welp, this is hacky.
		if ( timer.Exists( "GMatch:OngoingRound" ) ) then
			if ( #player.GetAll( ) == 0 ) then
				GMatch:FinishRound( )
			end
		end
	end )
end