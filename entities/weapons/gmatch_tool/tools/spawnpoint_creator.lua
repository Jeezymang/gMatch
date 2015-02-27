local SPAWNPOINT_SEND = 1
local SPAWNPOINT_TOGGLEVIEW = 2
local SPAWNPOINT_REMOVE = 3
local fileName = string.StripExtension( string.GetFileFromFilename( debug.getinfo(1).short_src ) )

local TOOL = { }

TOOL.Name = "Spawnpoint Creator"
TOOL.Usage = { 
	["LeftClick"] = "Create a spawn point.",
	["RightClick"] = "Remove nearest spawn point.",
	["Reload"] = "View the spawn points."
}

if ( SERVER ) then 
	util.AddNetworkString( "GMatchTool_SpawnPointCreator" )
else
	net.Receive( "GMatchTool_SpawnPointCreator", function( len )
		local opType = net.ReadUInt( 16 )
		if ( opType == SPAWNPOINT_SEND ) then
			local spawnID = net.ReadUInt( 32 )
			local teamIndex = net.ReadUInt( 16 )
			local pos = net.ReadVector( )
			GMatch.GameData.SpawnPoints = GMatch.GameData.SpawnPoints or { }
			GMatch.GameData.SpawnPoints[ spawnID ] = { teamIndex = teamIndex, pos = pos }
		elseif ( opType == SPAWNPOINT_TOGGLEVIEW ) then
			LocalPlayer( ).gMatchSpawnPointCreator_ViewingSpawns = !( LocalPlayer( ).gMatchSpawnPointCreator_ViewingSpawns )
		elseif ( opType == SPAWNPOINT_REMOVE ) then
			local spawnID = net.ReadUInt( 32 )
			GMatch.GameData.SpawnPoints = GMatch.GameData.SpawnPoints or { }
			GMatch.GameData.SpawnPoints[ spawnID ] = nil
		end
	end )
	function TOOL:DrawHUD( )
		if not ( LocalPlayer( ).gMatchSpawnPointCreator_ViewingSpawns ) then return end
		GMatch.GameData.SpawnPoints = GMatch.GameData.SpawnPoints or { }
		for id, spawnData in pairs ( GMatch.GameData.SpawnPoints ) do
			local screenData = spawnData.pos:ToScreen( )
			draw.SimpleText( "SpawnID[ " .. id .. " ]", "GMatch_Lobster_MediumBoldStatic", screenData.x, screenData.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
		end
	end
end

function TOOL:PrimaryAttack( trace, owner )
	if ( SERVER ) then
		local spawnPoint = trace.HitPos
		local insertQuery = [[
		INSERT INTO gmatch_spawnpoints
		( map, gamemode, team, x, y, z )
		VALUES( %s, %s, %d, %d, %d, %d );
		]]
		sql.Query( string.format( insertQuery, SQLStr( game.GetMap( ) ), SQLStr( gMatchGameFolder ), owner:Team( ), spawnPoint.x, spawnPoint.y, spawnPoint.z ) )
		local selectIDQuery = [[
		SELECT MAX( id ) AS id
		FROM gmatch_spawnpoints;
		]]
		local spawnID = tonumber( sql.Query( selectIDQuery )[1].id )
		owner:DisplayNotify( "Created Spawn Point ID[ " .. spawnID .. " ] at: " .. tostring( spawnPoint ), 4, "icon16/wrench.png" )
		GMatch.GameData.SpawnPoints = GMatch.GameData.SpawnPoints or { }
		GMatch.GameData.SpawnPoints[spawnID] = {
			teamIndex = owner:Team( ),
			pos = spawnPoint
		}
		net.Start( "GMatchTool_SpawnPointCreator" )
			net.WriteUInt( SPAWNPOINT_SEND, 16 )
			net.WriteUInt( spawnID, 32 )
			net.WriteUInt( owner:Team( ), 16 )
			net.WriteVector( spawnPoint )
		net.Send( owner )
	end
end

function TOOL:SecondaryAttack( trace, owner )
	if ( !SERVER or !owner:IsSuperAdmin( ) ) then return end
	local distanceTable = { }
	GMatch.GameData.SpawnPoints = GMatch.GameData.SpawnPoints or { }
	for id, spawnData in pairs ( GMatch.GameData.SpawnPoints ) do
		local hitPos = trace.HitPos
		table.insert( distanceTable, { id = id, distance = hitPos:Distance( spawnData.pos ) } )
	end
	if ( #distanceTable > 0 ) then
		table.SortByMember( distanceTable, "distance", true )
		local winningID = distanceTable[1].id
		if ( distanceTable[1].distance > 300 ) then
			owner:DisplayNotify( "There are no spawnpoints near that position.", 4, "icon16/error.png" )
			return
		end
		local deleteQuery = [[
		DELETE FROM gmatch_spawnpoints
		WHERE id = %d;
		]]
		sql.Query( string.format( deleteQuery, tonumber( winningID ) ) )
		owner:DisplayNotify( "You've removed SpawnID[ " .. winningID .. " ].", 4, "icon16/wrench.png" )
		GMatch.GameData.SpawnPoints[winningID] = nil
		net.Start( "GMatchTool_SpawnPointCreator" )
			net.WriteUInt( SPAWNPOINT_REMOVE, 16 )
			net.WriteUInt( winningID, 32 )
		net.Send( owner )
	end
end

function TOOL:Reload( trace, owner )
	if ( SERVER ) then
		self.viewingSpawnPoints = self.viewingSpawnPoints or false
		if not ( self.viewingSpawnPoints ) then
			GMatch.GameData.SpawnPoints = GMatch.GameData.SpawnPoints or { }
			for id, spawnData in pairs ( GMatch.GameData.SpawnPoints ) do
				net.Start( "GMatchTool_SpawnPointCreator" )
					net.WriteUInt( SPAWNPOINT_SEND, 16 )
					net.WriteUInt( id, 32 )
					net.WriteUInt( spawnData.teamIndex, 16 )
					net.WriteVector( spawnData.pos )
				net.Send( owner )
			end
			self.viewingSpawnPoints = true
			owner:DisplayNotify( "Now displaying all spawnpoints.", 4, "icon16/comment.png" )
			net.Start( "GMatchTool_SpawnPointCreator" )
				net.WriteUInt( SPAWNPOINT_TOGGLEVIEW, 16 )
			net.Send( owner )
		else
			self.viewingSpawnPoints = false
			owner:DisplayNotify( "Now hiding all spawnpoints.", 4, "icon16/comment.png" )
			net.Start( "GMatchTool_SpawnPointCreator" )
				net.WriteUInt( SPAWNPOINT_TOGGLEVIEW, 16 )
			net.Send( owner )
		end
	end
end

local gMatchToolTable = weapons.GetStored( "gmatch_tool" )
gMatchToolTable.Tools = gMatchToolTable.Tools or { }
gMatchToolTable.Tools[fileName] = TOOL