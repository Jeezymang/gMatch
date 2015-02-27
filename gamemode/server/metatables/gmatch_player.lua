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

function plyMeta:SendSound( soundPath )
	net.Start( "GMatch:ManipulateMisc" )
		net.WriteUInt( NET_MISC_PLAYSOUND, 16 )
		net.WriteString( soundPath )
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
	if ( self:Alive( ) ) then return end
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
	if ( self.killSpreeCount > 1 ) then
		hook.Call( "OnPlayerKillingSpree", GAMEMODE, self, self.killSpreeCount )
	end
	if ( self.killSpreeCount == GMatch.Config.KillingSpreeAmount ) then
		GMatch:BroadcastCenterMessage( self:Name( ) .. " is on a KILLING SPREE!", 5, nil, true, "GMatch_Lobster_LargeBold" )
		self:SetGameStat( "KillingSprees", self:GetGameStat( "KillingSprees" ) + 1 )
		self:SetPlayerVar( "OnKillingSpree", true, true )
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
	self:SetPlayerVar( "OnKillingSpree", false, true )
	self.killSpreeCount = 0
end

function plyMeta:SetGameStat( stat, val, initialSetting )
	if ( self:IsBot( ) ) then return end
	if ( ( !self.netDataFinishedSending or !self.isInitialized ) and !initialSetting ) then return end
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
	if ( !self.netDataFinishedSending or !self.isInitialized ) then return end
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

function plyMeta:SetPlayerVar( name, val, networked )
	local tableIndex = self:SteamID( )
	if ( self:IsBot( ) ) then tableIndex = self:UniqueID( ) end
	GMatch.GameData.PlayerVars[tableIndex] = GMatch.GameData.PlayerVars[tableIndex] or { }
	GMatch.GameData.PlayerVars[tableIndex][name] = val
	if not ( networked ) then return end
	GMatch.GameData.NetworkedPlayerVars = GMatch.GameData.NetworkedPlayerVars or { }
	GMatch.GameData.NetworkedPlayerVars[tableIndex] = GMatch.GameData.NetworkedPlayerVars[tableIndex] or { }
	GMatch.GameData.NetworkedPlayerVars[tableIndex][ name ] = val
	local valType = type( val )
	if ( valType == "Player" or valType == "Weapon" ) then valType = "Entity" end
	if not ( GMatch.PlayerVarTypes[ valType ] ) then ErrorNoHalt( "Invalid PlayerVar type defined.\n" ) return end
	local varFunc = GMatch.PlayerVarTypes[ valType ]
	net.Start( "GMatch:ManipulatePlayerVars" )
		net.WriteUInt( NET_PLAYERVARS_SEND, 16 )
		net.WriteString( tableIndex )
		net.WriteString( name )
		net.WriteString( valType )
		varFunc( val )
	net.Broadcast( )
end

function plyMeta:InitiateGameTimer( )
	if ( timer.Exists( "GMatch:OngoingRound" ) ) then
		GMatch:AlterTimerLength( timer.TimeLeft( "GMatch:OngoingRound" ), GMatch.GameData.RoundLength, self )
	elseif ( timer.Exists( "GMatch:Intermission" ) ) then
		GMatch:AlterTimerLength( timer.TimeLeft( "GMatch:Intermission" ), GMatch.GameData.IntermissionLength, self )
	end
end

function plyMeta:HasRevenge( victim )
	self.revengeTable = self.revengeTable or { }
	local revengeTable = self.revengeTable[ victim:SteamID( ) ]
	if ( revengeTable and revengeTable > GMatch.Config.KillsForRevenge ) then
		return true, revengeTable
	else
		return false
	end
end

function plyMeta:TakeRevenge( victim )
	self.revengeTable = self.revengeTable or { }
	self.revengeTable[victim:SteamID( )] = nil
	self:SetGameStat( "Revenges", self:GetGameStat( "Revenges", 0 ) + 1 )
end

function plyMeta:IsDominating( victim )
	victim.revengeTable = victim.revengeTable or { }
	local revengeTable = victim.revengeTable[ self:SteamID( ) ]
	if ( revengeTable and revengeTable == GMatch.Config.KillsForDomination ) then
		self:SetGameStat( "Dominations", self:GetGameStat( "Dominations", 0 ) + 1 )
		return true
	else
		return false
	end
end

function plyMeta:IncrementNoRevenge( attacker, amt )
	local amt = amt or 1
	self.revengeTable = self.revengeTable or { }
	self.revengeTable[ attacker:SteamID( ) ] = self.revengeTable[ attacker:SteamID( ) ] or 0
	self.revengeTable[ attacker:SteamID( ) ] = self.revengeTable[ attacker:SteamID( ) ] + amt
end

function plyMeta:DidGainLead( oldScore, newScore, valueFunc )
	local sortedTable = { }
	local scoreTable = { }
	for index, ply in pairs ( player.GetAll( ) ) do
		if ( ply == self ) then continue end
		table.insert( sortedTable, { ply = ply, value = valueFunc( ply ) } )
		scoreTable[ valueFunc( ply ) ] = scoreTable[ valueFunc( ply ) ] or { }
		table.insert( scoreTable[ valueFunc( ply ) ], ply )
	end
	table.SortByMember( sortedTable, "value", false )
	local highestScore = sortedTable[1].value
	if ( newScore == highestScore ) then
		self:SendSound( "halo/tiedtheleader.mp3" )
	elseif ( oldScore <= highestScore and newScore > highestScore ) then
		self:SendSound( "halo/gainedthelead.mp3" )
		for index, ply in pairs ( scoreTable[ highestScore ] ) do
			ply:SendSound( "halo/lost_the_lead.mp3" )
		end
	end
end