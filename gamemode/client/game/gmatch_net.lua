net.Receive( "GMatch:ManipulateTimer", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_TIMER_SET ) then
		local timerLength = CurTime( ) + net.ReadUInt( 16 )
		GMatch.GameData.TimerLength = timerLength
	elseif ( opType == NET_TIMER_TOGGLE ) then
		local toggleStatus = tobool( net.ReadBit( ) )
		local roundLength = net.ReadUInt( 32 )
		GMatch.GameData.RoundLength = roundLength
		GMatch.GameData.TimerToggled = toggleStatus
	elseif ( opType == NET_TIMER_NETDATATIME ) then
		local estimatedTime = net.ReadUInt( 32 )
		GMatch.GameData.NETDataEstimatedTime = estimatedTime
		GMatch.GameData.NETDataEstimatedEndTime = CurTime( ) + estimatedTime
	end
end )

net.Receive( "GMatch:ManipulateText", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_TEXT_CENTERMESSAGE ) then
		local txt = net.ReadString( )
		local len = net.ReadUInt( 16 )
		local col = net.ReadVector( )
		if ( col == Vector( -1, -1, -1 ) ) then col = nil
		else col = col:ToColor( ) end
		local isRainbow = tobool( net.ReadBit( ) )
		local font = net.ReadString( )
		if ( IsValid( LocalPlayer( ) ) ) then
			LocalPlayer( ):PrintCenterMessage( txt, len, col, isRainbow, font )
		end
	elseif ( opType == NET_TEXT_DISPLAYNOTIFY ) then
		local txt = net.ReadString( )
		local len = net.ReadUInt( 16 )
		local iconPath = net.ReadString( )
		local textColor = net.ReadVector( )
		if ( textColor == Vector( -1, -1, -1 ) ) then textColor = nil
		else textColor = textColor:ToColor( ) end
		local panelColor = net.ReadVector( )
		if ( panelColor == Vector( -1, -1, -1 ) ) then panelColor = nil
		else panelColor = panelColor:ToColor( ) end
		local isRainbow = tobool( net.ReadBit( ) )
		local font = net.ReadString( )
		if ( IsValid( LocalPlayer( ) ) ) then
			LocalPlayer( ):DisplayNotify( txt, len, iconPath, textColor, panelColor, isRainbow, font )
		end
	elseif ( opType == NET_TEXT_COLOREDMESSAGE ) then
		local textTable = net.ReadTable( )
		chat.AddText( unpack( textTable ) )
	end
end )

local typeWhitelist = {
	["string"] = function( ) return net.ReadString( ) end,
	["boolean"] = function( ) return tobool( net.ReadBit( ) ) end,
	["table"] = function( ) return net.ReadTable( ) end,
	["number"] = function( ) return net.ReadInt( 32 ) end,
	["Vector"] = function( ) return net.ReadVector( ) end,
	["Angle"] = function( ) return net.ReadAngle( ) end,
	["Entity"] = function( ) return net.ReadEntity( ) end
}

net.Receive( "GMatch:ManipulateGameVars", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_VARS_SEND ) then
		local varName = net.ReadString( )
		local varType = net.ReadString( )
		if not ( typeWhitelist[ varType ] ) then ErrorNoHalt( "Invalid GameVar type specified." ) return end
		local varFunc = typeWhitelist[ varType ]
		local varValue = varFunc( )
		GMatch.GameData.GameVars[ varName ] = varValue
	end
end )

net.Receive( "GMatch:ManipulatePlayerVars", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_PLAYERVARS_SEND ) then
		local steamID = net.ReadString( )
		local varName = net.ReadString( )
		local varType = net.ReadString( )
		if not ( typeWhitelist[ varType ] ) then ErrorNoHalt( "Invalid PlayerVar type specified." ) return end
		local varFunc = typeWhitelist[ varType ]
		local varValue = varFunc( )
		GMatch.GameData.PlayerVars[ steamID ] = GMatch.GameData.PlayerVars[ steamID ] or { }
		GMatch.GameData.PlayerVars[ steamID ][ varName ] = varValue
	end
end )

net.Receive( "GMatch:ManipulateGameVotes", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_GAMEVOTES_OPEN ) then
		if not ( IsValid( LocalPlayer( ).gMatchGameSelect ) ) then
			vgui.Create( "gMatch_GameSelect" )
		end
	elseif ( opType == NET_GAMEVOTES_CLOSE ) then
		if ( IsValid( LocalPlayer( ).gMatchGameSelect ) ) then
			LocalPlayer( ).gMatchGameSelect:Remove( )
		end
	elseif ( opType == NET_GAMEVOTES_ADD ) then
		local gameName = net.ReadString( )
		if ( IsValid( LocalPlayer( ).gMatchGameSelect ) ) then
			LocalPlayer( ).gMatchGameSelect:AddVote( gameName )
		end
	elseif ( opType == NET_GAMEVOTES_REMOVE ) then
		local gameName = net.ReadString( )
		if ( IsValid( LocalPlayer( ).gMatchGameSelect ) ) then
			LocalPlayer( ).gMatchGameSelect:RemoveVote( gameName )
		end
	end
end )

net.Receive( "GMatch:ManipulateMapVotes", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_MAPVOTES_OPEN ) then
		if not ( IsValid( LocalPlayer( ).gMatchMapSelect ) ) then
			vgui.Create( "gMatch_MapSelect" )
		end
	elseif ( opType == NET_MAPVOTES_CLOSE ) then
		if ( IsValid( LocalPlayer( ).gMatchMapSelect ) ) then
			LocalPlayer( ).gMatchMapSelect:Remove( )
		end
	elseif ( opType == NET_MAPVOTES_ADD ) then
		local mapName = net.ReadString( )
		if ( IsValid( LocalPlayer( ).gMatchMapSelect ) ) then
			LocalPlayer( ).gMatchMapSelect:AddVote( mapName )
		end
	elseif ( opType == NET_MAPVOTES_REMOVE ) then
		local mapName = net.ReadString( )
		if ( IsValid( LocalPlayer( ).gMatchMapSelect ) ) then
			LocalPlayer( ).gMatchMapSelect:RemoveVote( mapName )
		end
	end
end )

net.Receive( "GMatch:ManipulateTeams", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_TEAMS_CLEAR ) then
		local allTeams = team.GetAllTeams( )
		if ( #allTeams > 0 ) then
			for i = 1, #allTeams do
				team.GetAllTeams( )[i] = nil
			end
		end
	elseif ( opType == NET_TEAMS_ADD ) then
		local teamIndex = net.ReadUInt( 16 )
		local teamName = net.ReadString( )
		local teamColor = net.ReadVector( ):ToColor( )
		team.SetUp( teamIndex, teamName, teamColor )
	end
end )

net.Receive( "GMatch:ManipulatePlayer", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_PLAYER_SENDDEATHTIME ) then
		local respawnDelay = net.ReadUInt( 32 )
		LocalPlayer( ).respawnLength = respawnDelay
		LocalPlayer( ).timeUntilRespawn = CurTime( ) + respawnDelay
	end
end )

net.Receive( "GMatch:ManipulateMisc", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_MISC_TRIGGERPARTICLES ) then
		local selTbl = net.ReadTable( )
		local selEmitter = ParticleEmitter( selTbl.selOrigin );
		for i = 1, selTbl.selMax do
			if ( selEmitter ) then
				local particle = selEmitter:Add( selTbl.selSprite, selTbl.selOrigin )
				particle:SetColor( unpack( selTbl.selColor ) )
				if not ( selTbl.selVelocity ) then
					local velMulti = selTbl.selVelocityMulti
					particle:SetVelocity( Vector( math.random( -velMulti, velMulti ), math.random( -velMulti, velMulti ), math.random( -velMulti, velMulti ) ) )
				else
					particle:SetVelocity( selTbl.selVelocity )
				end
				particle:SetRoll( selTbl.selRoll )
				particle:SetRollDelta( selTbl.selRollDelta )
				particle:SetDieTime( selTbl.selDieTime )
				particle:SetLifeTime( selTbl.selLifeTime )
				particle:SetStartAlpha( selTbl.selStartAlpha )
				particle:SetStartSize( selTbl.selStartSize )
				particle:SetEndSize( selTbl.selEndSize )
				particle:SetEndAlpha( selTbl.selEndAlpha )
				particle:SetGravity( selTbl.selGravity )
				particle:SetPos( particle:GetPos( ) + Vector( 0, 0, i *3 ) )
				particle:SetStartLength( selTbl.selStartLength )
			end
		end
	elseif ( opType == NET_MISC_TRIGGERENDGAMEMUSIC ) then
		local tblIndex = net.ReadUInt( 16 )
		local musicTable = GMatch.Config.EndRoundMusicURLs[tblIndex]
		LocalPlayer( ):DisplayNotify( "Playing: " .. musicTable.name , 4, "icon16/music.png", Color( 255, 255, 255 ), nil, true, nil )
		sound.PlayURL( musicTable.url, "mono", function( soundPatch ) 
			if ( IsValid( soundPatch ) ) then
				soundPatch:SetPos( LocalPlayer( ):GetPos( ) )
				soundPatch:Play( )
				if not ( system.HasFocus( ) ) then soundPatch:SetVolume( 0 ) end
				local timerTickCount = 0
				timer.Create( "EndRoundMusicManage", 1, 40, function( ) 
					if not ( IsValid( soundPatch ) ) then 
						soundPatch = nil 
						timer.Destroy( "EndRoundMusicManage" )
						return 
					end
					if not ( system.HasFocus( ) ) then
						soundPatch:SetVolume( 0 )
					else
						soundPatch:SetVolume( 1 )
					end
					timerTickCount = timerTickCount + 1
					if( timerTickCount >= 39 ) then
						soundPatch:Stop( )
						soundPatch = netil
					end
				end )
			else
				LocalPlayer( ):ChatPrint( "Unable to play URL." )
			end
		end )
	end
end )

net.Receive( "GMatch:ManipulateStats", function( len )
	local opType = net.ReadUInt( 16 )
	if ( opType == NET_STATS_SENDSTAT ) then
		local statName = net.ReadString( )
		local statValue = net.ReadUInt( 32 )
		local steamID = net.ReadString( )
		GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
		GMatch.GameData.PlayerStats[steamID] = GMatch.GameData.PlayerStats[steamID] or { }
		GMatch.GameData.PlayerStats[steamID][statName] = statValue
	end
end )