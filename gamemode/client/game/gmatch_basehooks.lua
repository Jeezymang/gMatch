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
	net.Start( "GMatch:ManipulateMisc" )
		net.WriteUInt( NET_MISC_INITIALIZEPLAYER, 16 )
	net.SendToServer( )
end )