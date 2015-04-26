local circleBorder = Material( "gui/circle_border512x512.png", "noclamp smooth" )
local circleFill = Material( "gui/circle_fill512x512.png", "noclamp smooth" )
local heartMat = Material( "gui/heart512x512.png", "noclamp" )
local bulletMat = Material( "gui/bullet_256x71.png", "noclamp" )
local barBorderMat = Material( "gui/bar_border128x32.png", "noclamp" )
local gameSwitchTime = nil

local fallbackIcon = Material( "icon16/heart.png" )
local materialCache = { }

local function DrawNotifications( )
	local notifies = GMatch.GameData.Notifies or { }
	if ( #notifies > 0 ) then
		for index, notifyTbl in ipairs ( notifies ) do
			if ( notifyTbl.expireTime < CurTime( ) ) then
				table.remove( notifies, index )
				continue
			end
			local textColor = notifyTbl.textCol or Color( 255, 255, 255, 255 )
			local panelColor = notifyTbl.panelColor or Color( 45, 45, 45, 255 )
			local textFont = notifyTbl.font or "GMatch_Lobster_MediumBold"
			local notifyIcon = notifyTbl.iconPath
			if ( notifyIcon and !materialCache[notifyIcon] ) then materialCache[notifyIcon] = Material( notifyIcon )
			elseif ( notifyIcon and materialCache[notifyIcon] ) then notifyIcon = materialCache[notifyIcon] end
			notifyIcon = notifyIcon or fallbackIcon
			if not ( type( notifyIcon ) == "IMaterial" ) then notifyIcon = fallbackIcon end
			if not ( GMatch.GameData.Fonts[textFont] ) then textFont = "GMatch_Lobster_MediumBold" end
			if ( notifyTbl.isRainbow ) then panelColor = util.RainbowStrobe( 2 ) end
			local notifyAlpha = ( ( notifyTbl.expireTime - CurTime( ) ) / notifyTbl.notifyLength ) * 255
			if ( notifyAlpha < 20 ) then
				table.remove( notifies, index )
				continue
			end
			textColor = Color( textColor.r, textColor.g, textColor.b, notifyAlpha )
			panelColor = Color( panelColor.r, panelColor.b, panelColor.g, notifyAlpha )
			local offsetY = ( ScrH( ) * 0.85 ) - ( ( ScrH( ) * 0.0425 ) * index )
			surface.SetFont( textFont )
			local notifyXPos = ( ScrW( ) - ( ScrW( ) * 0.175 ) )
			local txtW, txtH = surface.GetTextSize( notifyTbl.message )
			local heightMulti = 0.5
			if ( txtH >= 30 ) then heightMulti = 0.3 end
			if ( txtH < 14 ) then heightMulti = 1.5 end
			local notifyWide = txtW + 36
			notifyWide = math.Clamp( notifyWide, ScrW( ) * 0.15, ScrW( ) * 0.5 )
			if ( notifyWide > ScrW( ) * 0.15 ) then
				notifyXPos = notifyXPos - ( ( notifyWide - ScrW( ) * 0.15 ) )
			end
			local notifyTall = ScrH( ) * 0.04
			draw.RoundedBox( 0, notifyXPos, offsetY - ( ( notifyTall * 0.5 ) - 8 ), notifyWide, notifyTall, panelColor )
			draw.BlurredRect( notifyXPos, offsetY - ( ( notifyTall * 0.5 ) - 8 ), notifyWide, notifyTall, 5, 3, Color( 255, 255, 255, notifyAlpha ) )
			draw.TexturedRect( notifyXPos + 4, offsetY, 16, 16, notifyIcon, Color( 255, 255, 255, notifyAlpha ) )
			draw.SimpleText( notifyTbl.message, textFont, notifyXPos + 24, ( offsetY - ( notifyTall * 0.5 ) ) + ( txtH * heightMulti ), textColor, TEXT_ALIGN_LEFT )
		end
	end
end

local function DrawNETDataTimer( )
	if not ( GMatch.GameData.NETDataEstimatedTime ) then return end
	if ( GMatch.GameData.NETDataEstimatedEndTime < CurTime( ) ) then return end
	local timeLeft = GMatch.GameData.NETDataEstimatedEndTime - CurTime( )
	local timePercent = 100 - ( ( timeLeft / GMatch.GameData.NETDataEstimatedTime ) * 100 )
	local textY = 100
	if ( GMatch.GameData.TimerToggled ) then textY = textY + 40 end
	draw.SimpleText( "Receiving Networked Data: " .. math.Round( timePercent ) .. "%", "GMatch_Lobster_SmallBoldStatic", 32, ScrH( ) - textY, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )
end

local function DrawAmmoIndicator( startX, startY )
	local wep = LocalPlayer( ):GetActiveWeapon( )
	if not ( IsValid( wep ) ) then return end
	local currentClip = wep:Clip1( )
	local maxClip = 0
	if ( GMatch.Config.MaxClips[wep:GetClass( )] ) then
		maxClip = GMatch.Config.MaxClips[wep:GetClass( )]
	elseif ( wep:GetTable( ).Primary ) then
		maxClip = wep:GetTable( ).Primary.ClipSize
	end
	if ( maxClip == 0 ) then return end
	local ammoSlice = math.floor( maxClip / 6 )
	local clipsLeft = math.Clamp( math.Round( LocalPlayer( ):GetAmmoCount( wep:GetPrimaryAmmoType( ) ) / maxClip ), 0, 999 )
	draw.SimpleText( "x" .. clipsLeft, "GMatch_Lobster_SmallBoldStatic", startX + 140, startY + 6, Color( 255, 255, 255 ), TEXT_ALIGN_RIGHT )
	for i = 1, 6 do
		local partAmmoStart = ( i * ammoSlice )
		local partAmmoEnd = partAmmoStart - ammoSlice
		local ammoPercent = math.Clamp( ( ( currentClip - partAmmoEnd ) / ammoSlice ), 0, 1 )
		draw.TexturedRect( ( startX + 110 + i * 32 ), startY + 8, 32, 14, bulletMat, Color( 45, 45, 45 ) )
		draw.HorizontalCutTexturedRect( ( startX + 110 + i * 32 ), startY + 8, 32, 14, bulletMat, Color( 255, 255, 255 ), ( ammoPercent  ) )
	end
end

local function DrawArmorIndicator( startX, startY )
	local colorShadeSin = math.sin( CurTime( ) * 8 ) * 45
	local armorBarWide = ( LocalPlayer( ):Armor( ) / 100 ) * 342
	local borderColor = Color( 65, 65, 65, 255 )
	draw.RoundedBox( 0, startX, startY + 64, armorBarWide, 12, Color( 45, 45 - colorShadeSin, 175, 175 ) )
	draw.TexturedRect( startX, startY + 64, 114, 12, barBorderMat, borderColor )
	draw.TexturedRect( startX + 114, startY + 64, 114, 12, barBorderMat, borderColor )
	draw.TexturedRect( startX + 228, startY + 64, 114, 12, barBorderMat, borderColor )
end

local function DrawHealthIndicator( )
	local healthStartPosX, healthStartPosY = 2, ScrH( ) - 54
	local pnlX, pnlY, pnlW, pnlH = healthStartPosX + 28, healthStartPosY - 28, 32 * 10.645, 78
	draw.RoundedBox( 0, pnlX, pnlY, pnlW, pnlH, Color( 45, 45, 45, 200 ) )
	draw.RoundedBox( 0, pnlX, pnlY, pnlW, pnlH * 0.35, Color( 45, 45, 45, 235 ) )
	draw.BlurredRect( pnlX, pnlY, pnlW, pnlH, 3, 3 )
	local roundAmt = GMatch:GetGameVar( "FinishedRounds", 0 )
	draw.SimpleText( "Round #" .. roundAmt, "GMatch_Lobster_MediumBoldStatic", pnlX + 8, pnlY + 5, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )
	for i = 1, 10 do
		local partHPStart = ( i * 10 )
		local partHPEnd = partHPStart - 10
		local heartPercent = math.Clamp( ( ( LocalPlayer( ):Health( ) - partHPEnd ) / 10 ), 0, 1 )
		local sizeWave = math.abs( ( math.sin( CurTime( ) * 6 ) * 1 ) )
		if ( LocalPlayer( ):Health( ) > LocalPlayer( ):GetMaxHealth( ) * 0.25 ) then sizeWave = 0 end
		draw.TexturedRect( healthStartPosX + 7.5 + ( i * 32 ), healthStartPosY - ( sizeWave * 4 ), 32 + sizeWave, 32, heartMat, Color( 255, 255, 255 ) )
		draw.HorizontalCutTexturedRect( healthStartPosX + 7.5 + ( i * 32 ), healthStartPosY - ( sizeWave * 4 ), 32, 32 + sizeWave, heartMat, Color( 175, 45, 45 ), heartPercent )
	end
	if not ( GMatch.Config.NoDrawAmmo ) then
		DrawAmmoIndicator( pnlX, pnlY )
	end
	DrawArmorIndicator( pnlX, pnlY )
end

local function DrawGameSwitchTime( )
	local gameSwitchTime = GMatch:GetGameVar( "GameSwitchTime", nil )
	if ( gameSwitchTime ) then gameSwitchTime = CurTime( ) + gameSwitchTime end
	if ( gameSwitchTime and gameSwitchTime > CurTime( ) ) then
		local timeLeft = string.NiceTime( gameSwitchTime - CurTime( ) )
		draw.SimpleText( "The gamemode will switch in " .. timeLeft .. "!", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.1, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end
end

local function DrawMapSwitchTime( )
	local mapSwitchTime = GMatch:GetGameVar( "MapSwitchTime", nil )
	if ( mapSwitchTime ) then mapSwitchTime = CurTime( ) + mapSwitchTime end
	if ( mapSwitchTime and mapSwitchTime > CurTime( ) ) then
		local timeLeft = string.NiceTime( mapSwitchTime - CurTime( ) )
		draw.SimpleText( "The map will switch in " .. timeLeft .. "!", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.1, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end
end

local function DrawRespawnTimer( )
	if not ( LocalPlayer( ):Alive( ) ) then
		local respawnLength = LocalPlayer( ).respawnLength or 0
		local timeUntilRespawn = LocalPlayer( ).timeUntilRespawn or 0
		local scaleSin = math.sin( CurTime( ) * 2 ) * 0.1
		scaleSin = 0.87 + scaleSin
		if ( timeUntilRespawn > CurTime( ) ) then
			local colorShadeSin = math.sin( CurTime( ) * 2 ) * 150
			local shadowColor = Color( 192 - colorShadeSin, 192 + colorShadeSin, 4 )
			local timeLeft = string.upper( string.NiceTime( timeUntilRespawn - CurTime( ) ) )
			draw.TextSpecial( "YOU HAVE DIED", "GMatch_Lobster_MediumBold_S", ScrW( ) * 0.5025, ScrH( ) * 0.9475, Color( 45, 45, 45 ), scaleSin, nil )
			draw.TextSpecial( "YOU HAVE DIED", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.945, Color( 255, 255, 255 ), scaleSin, nil )
			--draw.SimpleText( "YOU HAVE DIED", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.8, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
			draw.TextSpecial( "YOU MAY RESPAWN IN " .. timeLeft .. "!", "GMatch_Lobster_MediumBold_S", ScrW( ) * 0.5025, ScrH( ) * 0.97025, shadowColor, scaleSin, nil )
			draw.TextSpecial( "YOU MAY RESPAWN IN " .. timeLeft .. "!", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.97, Color( 255, 255, 255 ), scaleSin, nil )
			--draw.SimpleText( "YOU MAY RESPAWN IN " .. timeLeft .. "!", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.85, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
		else
			local drawCanRespawn = true
			if ( GMatch.Config.RespawnAmount and GMatch.GameData.TimerToggled ) then
				local respawnsLeft = GMatch.Config.RespawnAmount - LocalPlayer( ):GetPlayerVar( "RespawnCount", 0 )
				if ( respawnsLeft > 0 ) then
					local timeText = "TIMES"
					if ( respawnsLeft == 1 ) then timeText = "TIME" end
					local respawnText = "YOU MAY RESPAWN " .. respawnsLeft .. " MORE " .. timeText
					draw.TextSpecial( respawnText, "GMatch_Lobster_MediumBold_S", ScrW( ) * 0.5025, ScrH( ) * 0.9475, Color( 194, 45, 4 ), scaleSin, nil )
					draw.TextSpecial( respawnText, "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.945, Color( 255, 255, 255 ), scaleSin, nil )
					--draw.SimpleText( "YOU MAY RESPAWN " .. respawnsLeft .. " MORE TIMES", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.7, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
				else
					draw.TextSpecial( "YOU MAY NOT RESPAWN UNTIL THE NEXT ROUND", "GMatch_Lobster_MediumBold_S", ScrW( ) * 0.5025, ScrH( ) * 0.97025, Color( 194, 45, 4 ), scaleSin, nil )
					draw.TextSpecial( "YOU MAY NOT RESPAWN UNTIL THE NEXT ROUND", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.97, Color( 255, 255, 255 ), scaleSin, nil )
					--draw.SimpleText( "YOU MAY NOT RESPAWN UNTIL THE NEXT ROUND", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.7, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
					drawCanRespawn = false
				end
			end
			if not ( drawCanRespawn ) then return end
			draw.TextSpecial( "YOU MAY RESPAWN", "GMatch_Lobster_MediumBold_S", ScrW( ) * 0.5025, ScrH( ) * 0.97025, Color( 45, 194, 4 ), scaleSin, nil )
			draw.TextSpecial( "YOU MAY RESPAWN", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.97, Color( 255, 255, 255 ), scaleSin, nil )
			--draw.TextSpecial( "YOU MAY RESPAWN", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.8, Color( 255, 255, 255 ), scaleSin, nil )
			--draw.SimpleText( "YOU MAY RESPAWN", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.8, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
		end
	end
end

local function DrawCenterScreenMessages( )
	local screenMessages = GMatch.GameData.ScreenMessages or { }
	if ( #screenMessages > 0 ) then
		for index, mesTbl in ipairs ( screenMessages ) do
			if ( mesTbl.expireTime < CurTime( ) ) then
				table.remove( screenMessages, index )
				continue
			end
			local textColor = mesTbl.col or Color( 255, 255, 255, 255 )
			local textFont = mesTbl.font or "GMatch_Lobster_MediumBold"
			if not ( GMatch.GameData.Fonts[textFont] ) then textFont = "GMatch_Lobster_MediumBold" end
			if ( mesTbl.isRainbow ) then textColor = util.RainbowStrobe( 2 ) end
			surface.SetFont( textFont )
			local txtW, txtH = surface.GetTextSize( mesTbl.message )
			local offsetY = ( ( ScrH( ) * 0.2 ) + ( ( 26 * index ) ) ) - txtH

			/*if ( screenMessages[index-1] ) then
				local mes, font = screenMessages[index-1].message, screenMessages[index-1].font
				if not ( GMatch.GameData.Fonts[font] ) then font = "GMatch_Lobster_MediumBold" end
				surface.SetFont( font )
				local txtW, txtH = surface.GetTextSize( mes )
				local _txtW, _txtH = surface.GetTextSize( "A" )
				--txtH = _txtH
				offsetY = offsetY + txtH --( txtH * 0.5 )
			end*/
			local textAlpha = ( ( mesTbl.expireTime - CurTime( ) ) / mesTbl.mesLength ) * 255
			if ( textAlpha < 20 ) then
				table.remove( screenMessages, index )
				continue
			end
			textColor = Color( textColor.r, textColor.g, textColor.b, textAlpha )
			draw.SimpleText( mesTbl.message, textFont, ScrW( ) * 0.5, offsetY, textColor, TEXT_ALIGN_CENTER )
		end
	end
end

local function DrawRoundTimer( timerLength )
	draw.RoundedBox( 0, 29, ScrH( ) - 125.5, 341, 40, Color( 45, 45, 45, 200 ) )
	draw.RoundedBox( 0, 29, ScrH( ) - 125.5, 341, 16, Color( 45, 45, 45, 230 ) )
	draw.BlurredRect( 29, ScrH( ) - 125.5, 341, 40, 3, 3 )
	local timeRemaining = timerLength - CurTime( )
	local roundLength = GMatch.Config.RoundLength
	local overrideLength = GMatch.GameData.RoundLength
	if ( overrideLength ) then roundLength = overrideLength end
	local barWidth = 320 * ( timeRemaining / roundLength )
	draw.RoundedBox( 0, 40, ScrH( ) - 109.5, 320, 16, Color( 75, 75, 255, 200 ) )
	draw.RoundedBox( 0, 40, ScrH( ) - 109.5, barWidth, 16, Color( 25, 25, 255, 200 ) )
	if not ( GMatch:IsIntermissionActive( ) ) then
		draw.SimpleText( "Time Remaining", "GMatch_Lobster_MediumBoldStatic", 195, ScrH( ) - 125.5, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
	else
		draw.SimpleText( "INTERMISSION", "GMatch_Lobster_MediumBoldStatic", 195, ScrH( ) - 125.5, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end
	timeRemaining = string.FormattedTime( timeRemaining, "%02i:%02i" )
	draw.SimpleText( timeRemaining, "GMatch_Lobster_SmallBoldStatic", 195, ScrH( ) - 108, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
end

hook.Add( "HUDPaint", "GMatch:HUDPaint", function( )
	DrawNotifications( )
	if not ( GMatch.Config.NoDrawHealth ) then
		DrawHealthIndicator( )
	end
	DrawGameSwitchTime( )
	DrawMapSwitchTime( )
	if not ( GMatch.Config.NoDrawRespawnTime ) then
		DrawRespawnTimer( )
	end
	DrawCenterScreenMessages( )
	if not ( GMatch.Config.NoDrawDataTime ) then
		DrawNETDataTimer( )
	end
	local showTimer = GMatch.GameData.TimerToggled or false
	local timerLength = GMatch.GameData.TimerLength or 0
	if not ( showTimer ) then return end
	DrawRoundTimer( timerLength )
end )

local HUDToHide = {
	["CHudHealth"] = true, 
	["CHudBattery"] = true,
	["CHudAmmo"] = true
}

hook.Add("HUDShouldDraw", "GMatch:HUDShouldDraw", function( name )
	if ( HUDToHide[ name ] ) then
		return false
	end
end )

function GM:HUDDrawTargetID( )
	return false
end

function GM:PostDrawOpaqueRenderables( )
	local targetPlayer = LocalPlayer( ):GetEyeTrace( ).Entity
	if ( !IsValid( targetPlayer ) or !targetPlayer:IsPlayer( ) ) then return end
	local hitAng = LocalPlayer( ):GetAngles( )
	local newAng = Angle( 0, hitAng.y - 90, 90 )
	local entPos = targetPlayer:GetPos( )
	local attachmentID = targetPlayer:LookupAttachment( "eyes" )
	if ( attachmentID and targetPlayer:GetAttachment( attachmentID ) ) then
		entPos = targetPlayer:GetAttachment( attachmentID ).Pos
	end
	cam.Start3D2D( entPos + Vector( 0, 0, 10 ), newAng, 0.1 )
		local baseHeight = 0
		local indexDecrement = 0
		for index, lineInfo in ipairs ( GMatch.Config.TargetIDInfo ) do
			if ( isfunction( lineInfo.shouldDisplay ) and !lineInfo.shouldDisplay( targetPlayer ) ) then 
				indexDecrement = indexDecrement + 1
				continue
			end
			local index = index - 1 - ( indexDecrement )
			local textColor = lineInfo.color
			local text = lineInfo.textFunc( targetPlayer )
			if ( isfunction( textColor ) ) then textColor = lineInfo.color( targetPlayer ) end
			draw.SimpleText( text, lineInfo.font, 0, -( index * 24 ) - ( lineInfo.yOffset or 0 ), textColor, TEXT_ALIGN_CENTER )
		end
	cam.End3D2D( )
end