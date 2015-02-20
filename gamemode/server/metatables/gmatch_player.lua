local plyMeta = FindMetaTable( "Player" )

function plyMeta:PrintCenterMessage( txt, length, col, isRainbow, font )
	net.Start( "GMatch:ManipulateText" )
		net.WriteUInt( NET_TEXT_CENTERMESSAGE, 16 )
		net.WriteString( txt )
		net.WriteUInt( length, 16 )
		local colorVector
		if not ( col ) then colorVector = Vector( -1, -1, -1 )
		else colorVector = col:ToVector( ) end
		net.WriteVector( colorVector )
		net.WriteBit( isRainbow )
		if ( font ) then net.WriteString( font ) end
	net.Send( self )
end

function plyMeta:DisplayNotify( txt, length, iconPath, textColor, panelColor, isRainbow, font )
	net.Start( "GMatch:ManipulateText" )
		net.WriteUInt( NET_TEXT_DISPLAYNOTIFY, 16 )
		net.WriteString( txt )
		net.WriteUInt( length, 16 )
		net.WriteString( iconPath )
		local textVector
		if not ( textColor ) then textVector = Vector( -1, -1, -1 )
		else textVector = textColor:ToVector( ) end
		net.WriteVector( textVector )
		local panelVector
		if not ( panelColor ) then panelVector = Vector( -1, -1, -1 )
		else panelVector = panelColor:ToVector( ) end
		net.WriteVector( panelVector )
		net.WriteBit( isRainbow )
		if ( font ) then net.WriteString( font ) end
	net.Send( self )
end

function plyMeta:GiveCurrentPrimaryAmmo( amt )
	local activeWep = self:GetActiveWeapon( )
	if ( IsValid( activeWep ) and activeWep:GetPrimaryAmmoType( ) ) then
		self:GiveAmmo( amt, activeWep:GetPrimaryAmmoType( ) )
	end
end

function plyMeta:GiveCurrentSecondaryAmmo( amt )
	local activeWep = self:GetActiveWeapon( )
	if ( IsValid( activeWep ) and activeWep:GetSecondaryAmmoType( ) ) then
		self:GiveAmmo( amt, activeWep:GetSecondaryAmmoType( ) )
	end
end

function plyMeta:GiveAllWeaponsPrimaryAmmo( amt )
	for index, wep in ipairs ( self:GetWeapons( ) ) do
		if ( !IsValid( wep ) or !wep:GetPrimaryAmmoType( ) ) then continue end
		self:GiveAmmo( amt, wep:GetPrimaryAmmoType( ) )
	end
end

function plyMeta:GiveAllWeaponsSecondaryAmmo( amt )
	for index, wep in ipairs ( self:GetWeapons( ) ) do
		if ( !IsValid( wep ) or !wep:GetSecondaryAmmoType( ) ) then continue end
		self:GiveAmmo( amt, wep:GetSecondaryAmmoType( ) )
	end
end

function plyMeta:SendColoredMessage( messTable )
	net.Start( "GMatch:ManipulateText" )
		net.WriteUInt( NET_TEXT_COLOREDMESSAGE, 16 )
		net.WriteTable( messTable )
	net.Send( self )
end

function plyMeta:SpectateRandomPlayer( )
	local shuffledPlayers = table.Shuffle( player.GetAll( ) )
	for index, ply in ipairs( shuffledPlayers ) do
		if ( ply ~= self and ply:Alive( ) ) then
			if ( GMatch.Config.SpectateTeamOnly and ply:Team( ) ~= self:Team( ) ) then continue end
			self:Spectate( OBS_MODE_CHASE )
			self:SpectateEntity( ply )
			self:StripWeapons( )
			self.spectatingPlayer = nil
			ply.spectatingPlayers = ply.spectatingPlayers or { }
			ply.spectatingPlayers[self:SteamID( )] = self
			break
		end
	end
end

function plyMeta:IncrementKillSpreeProgress( val )
	local val = val or 1
	self.killSpreeCount = self.killSpreeCount or 0
	self.killSpreeCount = self.killSpreeCount + val
	if ( self.killSpreeCount == GMatch.Config.KillingSpreeAmount ) then
		GMatch:BroadcastCenterMessage( self:Name( ) .. " is on a KILLING SPREE!", 5, nil, true, "GMatch_Lobster_LargeBold" )
		self:SetGameStat( "KillingSprees", self:GetGameStat( "KillingSprees" ) + 1 )
	elseif ( self.killSpreeCount > GMatch.Config.KillingSpreeAmount ) then
		local highestKillSpree = self:GetGameStat( "HighestKillingSpree" )
		if ( self.killSpreeCount > highestKillSpree ) then
			self:SetGameStat( "HighestKillingSpree", self.killSpreeCount )
		end
		local wasFiveKills = ( ( self.killSpreeCount - GMatch.Config.KillingSpreeAmount ) % GMatch.Config.KillingSpreeAnnounceInterval == 1 )
		if ( wasFiveKills ) then
			GMatch:BroadcastCenterMessage( self:Name( ) .. " has killed " .. self.killSpreeCount .. " players without retribution!", 5, nil, true, "GMatch_Lobster_LargeBold" )
		end
	end
end

function plyMeta:ResetKillSpreeProgress( )
	self.killSpreeCount = self.killSpreeCount or 0
	if ( self.killSpreeCount > GMatch.Config.KillingSpreeAmount ) then
		GMatch:BroadcastCenterMessage( self:Name( ) .. " is no longer on a killing spree.", 5, nil, true, "GMatch_Lobster_LargeBold" )
	end
	self.killSpreeCount = 0
end

function plyMeta:SetGameStat( stat, val )
	if ( self:IsBot( ) ) then return end
	GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
	local playerTable = GMatch.GameData.PlayerStats[ self:SteamID( ) ]
	if not ( playerTable ) then return end
	if not ( playerTable[ stat ] ) then return end
	GMatch.GameData.PlayerStats[ self:SteamID( ) ][ stat ] = val
	if not ( type( val ) == "number" ) then return end
	net.Start( "GMatch:ManipulateStats" )
		net.WriteUInt( NET_STATS_SENDSTAT, 16 )
		net.WriteString( stat )
		net.WriteUInt( val, 32 )
		net.WriteString( self:SteamID( ) )
	net.Broadcast( )
end

function plyMeta:SaveGameStats( )
	if ( self:IsBot( ) ) then return end
	GMatch.GameData.PlayerStats = GMatch.GameData.PlayerStats or { }
	local playerTable = GMatch.GameData.PlayerStats[ self:SteamID( ) ]
	if not ( playerTable ) then return end
	local updateQuery = [[
	UPDATE gmatch_playerstats
	SET kills = %d, deaths = %d, suicides = %d, headshots = %d, killingsprees = %d, 
	highestkillingspree = %d, revenges = %d, dominations = %d, wins = %d
	WHERE steam64 = %s;
	]]
	sql.Query( string.format( updateQuery, playerTable["Kills"], playerTable["Deaths"], playerTable["Suicides"], playerTable["Headshots"],
	playerTable["KillingSprees"], playerTable["HighestKillingSpree"], playerTable["Revenges"], playerTable["Dominations"], playerTable["Wins"], self:SteamID64( ) ) )
	self:DisplayNotify( "Your stats have been saved.", 5, "icon16/heart.png", nil, nil, true )
end