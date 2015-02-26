function GMatch:CreateTables( )
	local persistTableQuery = [[
	CREATE TABLE IF NOT EXISTS %s (
	`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	`class` VARCHAR(255) NOT NULL,
	`model` VARCHAR(255),
	`map` VARCHAR(255) NOT NULL,
	`gamemode` VARCHAR(255) NOT NULL,
	`x` INTEGER NOT NULL,
	`y` INTEGER NOT NULL,
	`z` INTEGER NOT NULL,
	`yaw` INTEGER NOT NULL,
	`pitch` INTEGER NOT NULL,
	`roll` INTEGER NOT NULL,
	`frozen` BOOL NOT NULL );
	]]
	sql.Query( string.format( persistTableQuery, SQLStr( "gmatch_persist" ) ) )
	sql.Query( string.format( persistTableQuery, SQLStr( "gmatch_respawnable" ) ) )
	local statsTableQuery = [[
	CREATE TABLE IF NOT EXISTS gmatch_playerstats (
	`steam64` UNSIGNED BIG INT PRIMARY KEY NOT NULL,
	`kills` INTEGER DEFAULT 0,
	`deaths` INTEGER DEFAULT 0,
	`suicides` INTEGER DEFAULT 0,
	`headshots` INTEGER DEFAULT 0,
	`killingsprees` INTEGER DEFAULT 0,
	`highestkillingspree` INTEGER DEFAULT 0,
	`revenges` INTEGER DEFAULT 0,
	`dominations` INTEGER DEFAULT 0,
	`wins` INTEGER DEFAULT 0,
	`joindate` INTEGER DEFAULT 0,
	`lastjoin` INTEGER DEFAULT 0 );
	]]
	sql.Query( statsTableQuery )
end

function GMatch:RetrievePlayerStats( ply )
	local selectQuery = [[
	SELECT *
	FROM gmatch_playerstats
	WHERE steam64 = %s;
	]]
	local resultSet = sql.Query( string.format( selectQuery, ply:SteamID64( ) ) )
	if ( resultSet ) then
		for index, data in ipairs ( resultSet ) do
			GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
			GMatch.GameData.PlayerStats[ ply:SteamID( ) ] = {
				["Player"] = ply,
				["Kills"] = tonumber( data.kills ),
				["Deaths"] = tonumber( data.deaths ),
				["Suicides"] = tonumber( data.suicides ),
				["Headshots"] = tonumber( data.headshots ),
				["KillingSprees"] = tonumber( data.killingsprees ),
				["HighestKillingSpree"] = tonumber( data.highestkillingspree ),
				["Revenges"] = tonumber( data.revenges ),
				["Dominations"] = tonumber( data.dominations ),
				["Wins"] = tonumber( data.wins ),
				["JoinDate"] = tonumber( data.joindate ),
				["LastJoin"] = tonumber( data.lastjoin )
			}
			local updateQuery = [[
			UPDATE gmatch_playerstats
			SET lastjoin = %d
			WHERE steam64 = %s;
			]]
			sql.Query( string.format( updateQuery, os.time( ), ply:SteamID64( ) ) )
			local lastPlayed = string.NiceTime( os.time( ) - tonumber( data.lastjoin ) )
			GMatch:BroadcastColoredMessage( { Color( 175, 175, 255 ), ply:Name( ), Color( 255, 255, 255 ), " has joined again, they last played ", Color( 125, 175, 125 ), lastPlayed, Color( 255, 255, 255 ), " ago!" } )
		end
	else
		local insertQuery = [[
		INSERT INTO gmatch_playerstats
		( steam64, joindate, lastjoin )
		VALUES( %s, %d, %d );
		]]
		sql.Query( string.format( insertQuery, ply:SteamID64( ), os.time( ), os.time( ) ) )
		GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
		GMatch.GameData.PlayerStats[ ply:SteamID( ) ] = {
			["Player"] = ply,
			["Kills"] = 0,
			["Deaths"] = 0,
			["Suicides"] = 0,
			["Headshots"] = 0,
			["KillingSprees"] = 0,
			["HighestKillingSpree"] = 0,
			["Revenges"] = 0,
			["Dominations"] = 0,
			["Wins"] = 0,
			["JoinDate"] = os.time( ),
			["LastJoin"] = os.time( )
		}
		GMatch:BroadcastColoredMessage( { Color( 175, 175, 255 ), ply:Name( ), Color( 255, 255, 255 ), " has joined for the first time." } )
	end
	return ( GMatch.GameData.PlayerStats[ ply:SteamID( ) ] )
end

function GMatch:RetrieveMapEntities( )
	local selectQuery = [[
	SELECT *
	FROM %s
	WHERE map = %s AND gamemode = %s;
	]]
	local persistEntities = sql.Query( string.format( selectQuery, SQLStr( "gmatch_persist" ), SQLStr( game.GetMap( ) ), SQLStr( gMatchGameFolder ) ) )
	local respawnEntities = sql.Query( string.format( selectQuery, SQLStr( "gmatch_respawnable" ), SQLStr( game.GetMap( ) ), SQLStr( gMatchGameFolder ) ) )
	return persistEntities, respawnEntities
end