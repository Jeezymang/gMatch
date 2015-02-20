util.AddNetworkString( "GMatch:ManipulateTimer" )
util.AddNetworkString( "GMatch:ManipulateText" )
util.AddNetworkString( "GMatch:ManipulateGameVars" )
util.AddNetworkString( "GMatch:ManipulateGameVotes" )
util.AddNetworkString( "GMatch:ManipulateMapVotes" )
util.AddNetworkString( "GMatch:ManipulateTeams" )
util.AddNetworkString( "GMatch:ManipulatePlayer" )
util.AddNetworkString( "GMatch:ManipulateWorld" )
util.AddNetworkString( "GMatch:ManipulateMisc" )
util.AddNetworkString( "GMatch:ManipulateStats" )
//util.AddNetworkString( "GMatch:ManipulateScores" )

function GMatch:InitiateTimers( )
	local timeLeft = timer.TimeLeft( "GMatch:OngoingRound" )
	net.Start( "GMatch:ManipulateTimer" )
		net.WriteUInt( NET_TIMER_SET, 16 )
		net.WriteUInt( timeLeft, 16 )
	net.Broadcast( )

	local roundLength = GMatch.GameData.RoundLength
	net.Start( "GMatch:ManipulateTimer" )
		net.WriteUInt( NET_TIMER_TOGGLE, 16 )
		net.WriteBit( true )
		net.WriteUInt( roundLength, 32 )
	net.Broadcast( )
end

function GMatch:DisableTimers( )
	net.Start( "GMatch:ManipulateTimer" )
		net.WriteUInt( NET_TIMER_TOGGLE, 16 )
		net.WriteBit( false )
	net.Broadcast( )
end

function GMatch:GameVoteAction( enum, gameName )
	net.Start( "GMatch:ManipulateGameVotes" )
		net.WriteUInt( enum, 16 )
		net.WriteString( gameName )
	net.Broadcast( )
end

function GMatch:MapVoteAction( enum, mapName )
	net.Start( "GMatch:ManipulateMapVotes" )
		net.WriteUInt( enum, 16 )
		net.WriteString( mapName )
	net.Broadcast( )
end

function GMatch:NetworkTeam( index, name, color )
	net.Start( "GMatch:ManipulateTeams" )
		net.WriteUInt( NET_TEAMS_ADD, 16 )
		net.WriteUInt( index, 16 )
		net.WriteString( name )
		net.WriteVector( color:ToVector( ) )
	net.Broadcast( )
end

net.Receive( "GMatch:ManipulateGameVars", function( len, ply )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_VARS_REQUEST ) then
		if not ( ply.isInitialized ) then
			ply.isInitialized = true
			hook.Call( "OnPlayerInitialized", GM, ply )
			GMatch:RetrievePlayerStats( ply )
		end
		local gameVars = GMatch.GameData.NetworkedGameVars or { }
		for varName, varValue in pairs ( gameVars ) do
			net.Start( "GMatch:ManipulateGameVars" )
				net.WriteUInt( NET_VARS_SEND, 16 )
				net.WriteString( varName )
				net.WriteString( type( varValue ) )
				GMatch.GameVarTypes[type( varValue )]( varValue )
			net.Send( ply )
		end
	end
end )

net.Receive( "GMatch:ManipulateGameVotes", function( len, ply )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_GAMEVOTES_VOTE and GMatch.GameData.GameVoteStarted ) then
		local gameName = net.ReadString( )
		if not ( GMatch.Config.Gamemodes[ gameName ] ) then
			ErrorNoHalt( ply:Name( ) .. " attempted to vote for an invalid game. [ " .. gameName .. " ]" )
			return
		end
		local fullName = GMatch.Config.Gamemodes[ gameName ].name
		local votedGame = GMatch.GameData.GameVotes[ ply:SteamID( ) ]
		if ( votedGame ) then
			GMatch:GameVoteAction( NET_GAMEVOTES_REMOVE, votedGame )
			GMatch.GameData.GameVotes[ ply:SteamID( ) ] = gameName
			GMatch:GameVoteAction( NET_GAMEVOTES_ADD, gameName )
			ply:DisplayNotify( "You've voted for the " .. fullName .. " gamemode!", 5, "icon16/comment.png" )
		else
			GMatch.GameData.GameVotes[ ply:SteamID( ) ] = gameName
			GMatch:GameVoteAction( NET_GAMEVOTES_ADD, gameName )
			ply:DisplayNotify( "You've voted for the " .. fullName .. " gamemode!", 5, "icon16/comment.png" )
		end
	end
end )

net.Receive( "GMatch:ManipulateMapVotes", function( len, ply )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_MAPVOTES_VOTE and GMatch.GameData.MapVoteStarted ) then
		local mapName = net.ReadString( )
		if not ( GMatch.Config.Maps[ mapName ] ) then
			ErrorNoHalt( ply:Name( ) .. " attempted to vote for an invalid game. [ " .. mapName .. " ]" )
			return
		end
		local fullName = GMatch.Config.Maps[ mapName ].name
		local votedMap = GMatch.GameData.MapVotes[ ply:SteamID( ) ]
		if ( votedMap ) then
			GMatch:MapVoteAction( NET_MAPVOTES_REMOVE, votedMap )
			GMatch.GameData.MapVotes[ ply:SteamID( ) ] = mapName
			GMatch:MapVoteAction( NET_MAPVOTES_ADD, mapName )
			ply:DisplayNotify( "You've voted for the " .. fullName .. " map!", 5, "icon16/comment.png" )
		else
			GMatch.GameData.MapVotes[ ply:SteamID( ) ] = mapName
			GMatch:MapVoteAction( NET_MAPVOTES_ADD, mapName )
			ply:DisplayNotify( "You've voted for the " .. fullName .. " map!", 5, "icon16/comment.png" )
		end
	end
end )


net.Receive( "GMatch:ManipulateTeams", function( len, ply )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_TEAMS_REQUEST ) then
		for index, teamData in ipairs ( team.GetAllTeams( ) ) do
			net.Start( "GMatch:ManipulateTeams" )
			net.WriteUInt( NET_TEAMS_ADD, 16 )
			net.WriteUInt( index, 16 )
			net.WriteString( teamData.Name )
			net.WriteVector( teamData.Color:ToVector( ) )
		net.Send( ply )
		end
	end
end )

net.Receive( "GMatch:ManipulateWorld", function( len, ply )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_WORLD_MAKEPERSISTENT ) then
		if not ( ply:IsSuperAdmin( ) ) then return end
		local ent = net.ReadEntity( )
		if ( ent.respawnID ) then ply:DisplayNotify( "You can't make an entity persistent and respawnable.", 5, "icon16/error.png" ) return end
		if ( ent.persistID ) then ply:DisplayNotify( "That entity has already been marked as persistent.", 5, "icon16/error.png" ) return end
		local entFrozen = false
		if ( ent:GetPhysicsObject( ):IsValid( ) ) then entFrozen = ent:GetPhysicsObject( ):IsMotionEnabled( ) end
		entFrozen = entFrozen and 1 or 0
		local entPos = ent:GetPos( )
		local entAng = ent:GetAngles( )
		local entInsertQuery = [[
		INSERT INTO gmatch_persist
		( class, model, map, gamemode, x, y, z, yaw, pitch, roll, frozen )
		VALUES( %s, %s, %s, %s, %d, %d, %d, %d, %d, %d, %d );
		]]
		sql.Query( string.format( entInsertQuery, SQLStr( ent:GetClass( ) ), SQLStr( ent:GetModel( ) ), SQLStr( game.GetMap( ) ), SQLStr( gMatchGameFolder ), entPos.x, entPos.y, entPos.z, entAng.y, entAng.p, entAng.r, entFrozen ) )
	  	local entIDMax = [[
	  	SELECT MAX(id) AS maxID
	  	FROM gmatch_persist;
	  	]]
	  	ent.persistID = sql.Query( entIDMax )[1].maxID
	  	ply:DisplayNotify( "You've set Entity ID[ " .. ent.persistID .. " ] as persistent.", 5, "icon16/table_add.png" )
	elseif ( opType == NET_WORLD_REMOVEPERSISTENCE ) then
		if not ( ply:IsSuperAdmin( ) ) then return end
		local ent = net.ReadEntity( )
		if not ( ent.persistID ) then ply:DisplayNotify( "That entity is not marked as persistent.", 5, "icon16/error.png" ) return end
		local entRemoveQuery = [[
		DELETE FROM gmatch_persist
		WHERE id = %d;
		]]
		sql.Query( string.format( entRemoveQuery, tonumber( ent.persistID ) ) )
		ply:DisplayNotify( "You've removed Entity ID[ " .. ent.persistID .. " ]'s persistence.", 5, "icon16/table_delete.png" )
		ent.persistID = nil
	elseif ( opType == NET_WORLD_MAKERESPAWNABLE ) then
		if not ( ply:IsSuperAdmin( ) ) then return end
		local ent = net.ReadEntity( )
		if ( ent.persistID ) then ply:DisplayNotify( "You can't make an entity persistent and respawnable.", 5, "icon16/error.png" ) return end
		if ( ent.respawnID ) then ply:DisplayNotify( "That entity is already set as respawnable.", 5, "icon16/error.png" ) return end
		local entFrozen = false
		if ( ent:GetPhysicsObject( ):IsValid( ) ) then entFrozen = ent:GetPhysicsObject( ):IsMotionEnabled( ) end
		entFrozen = entFrozen and 1 or 0
		local entPos = ent:GetPos( )
		local entAng = ent:GetAngles( )
		local entInsertQuery = [[
		INSERT INTO gmatch_respawnable
		( class, model, map, gamemode, x, y, z, yaw, pitch, roll, frozen )
		VALUES( %s, %s, %s, %s, %d, %d, %d, %d, %d, %d, %d );
		]]
		sql.Query( string.format( entInsertQuery, SQLStr( ent:GetClass( ) ), SQLStr( ent:GetModel( ) ), SQLStr( game.GetMap( ) ), SQLStr( gMatchGameFolder ), entPos.x, entPos.y, entPos.z, entAng.y, entAng.p, entAng.r, entFrozen ) )
	  	local entIDMax = [[
	  	SELECT MAX(id) AS maxID
	  	FROM gmatch_respawnable;
	  	]]
	  	ent.respawnID = sql.Query( entIDMax )[1].maxID
	  	ply:DisplayNotify( "You've enabled Entity ID[ " .. ent.respawnID .. " ]'s respawning status.", 5, "icon16/transmit_add.png" )
	  	GMatch.GameData.RespawningEntities = GMatch.GameData.RespawningEntities or { }
	  	GMatch.GameData.RespawningEntities[tonumber( ent.respawnID )] = {
			ent = ent,
			class = ent:GetClass( ),
			model = ent:GetModel( ),
			pos = Vector( tonumber( entPos.x ), tonumber( entPos.y ), tonumber( entPos.z ) ),
			ang = Angle( tonumber( entAng.pitch ), tonumber( entAng.yaw ), tonumber( entAng.roll ) ),
			frozen = tobool( entFrozen )
		}
	elseif ( opType == NET_WORLD_REMOVERESPAWNABLE ) then
		if not ( ply:IsSuperAdmin( ) ) then return end
		local ent = net.ReadEntity( )
		if not ( ent.respawnID ) then ply:DisplayNotify( "That entity is not set as respawnable.", 5, "icon16/error.png" ) return end
		local entRemoveQuery = [[
		DELETE FROM gmatch_respawnable
		WHERE id = %d;
		]]
		sql.Query( string.format( entRemoveQuery, tonumber( ent.respawnID ) ) )
		GMatch.GameData.RespawningEntities = GMatch.GameData.RespawningEntities or { }
		GMatch.GameData.RespawningEntities[ent.respawnID] = nil
		ply:DisplayNotify( "You've disabled Entity ID[ " .. ent.respawnID .. " ]'s respawning status.", 5, "icon16/transmit_delete.png" )
		ent.respawnID = nil
	end
end )

hook.Add( "OnPlayerInitialized", "GMatch:OnPlayerInitialized", function( ply )
	for index, plr in ipairs ( player.GetAll( ) ) do
		GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
		local statTable = GMatch.GameData.PlayerStats[plr:SteamID( )]
		for stat, val in pairs ( statTable or { } ) do
			if ( type( val ) ~= "number" ) then continue end
			net.Start( "GMatch:ManipulateStats" )
				net.WriteUInt( NET_STATS_SENDSTAT, 16 )
				net.WriteString( stat )
				net.WriteUInt( val, 32 )
				net.WriteString( plr:SteamID( ) )
			net.Send( ply )
		end
	end
end )