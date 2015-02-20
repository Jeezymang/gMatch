function GM:Initialize( )
	if not ( gMatchGameFolder == "gmatch" ) then
		GMatch:IncludeAllFiles( gMatchGameFolder .. "/gamemode/" )
	end
end

function GM:OnReloaded( )
	if not ( gMatchGameFolder == "gmatch" ) then
		GMatch:IncludeAllFiles( gMatchGameFolder .. "/gamemode/" )
	end
end

hook.Add( "InitPostEntity", "GMatch_InitPostEntity", function( )
	net.Start( "GMatch:ManipulateGameVars" )
		net.WriteUInt( NET_VARS_REQUEST, 16 )
	net.SendToServer( )
	net.Start( "GMatch:ManipulatetEAMS" )
		net.WriteUInt( NET_TEAMS_REQUEST, 16 )
	net.SendToServer( )
end )