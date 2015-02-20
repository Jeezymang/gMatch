local circleBorder = Material( "gui/circle_border512x512.png", "noclamp smooth" )
local circleFill = Material( "gui/circle_fill512x512.png", "noclamp smooth" )
local heartMat = Material( "gui/heart512x512.png", "noclamp" )
local bulletMat = Material( "gui/bullet_256x71.png", "noclamp" )
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
			local notifyWide = txtW + 36
			notifyWide = math.Clamp( notifyWide, ScrW( ) * 0.15, ScrW( ) * 0.5 )
			if ( notifyWide > ScrW( ) * 0.15 ) then
				notifyXPos = notifyXPos - ( ( notifyWide - ScrW( ) * 0.15 ) )
			end
			local notifyTall = ScrH( ) * 0.04
			draw.RoundedBox( 0, notifyXPos, offsetY - ( ( notifyTall * 0.5 ) - 8 ), notifyWide, notifyTall, panelColor )
			draw.BlurredRect( notifyXPos, offsetY - ( ( notifyTall * 0.5 ) - 8 ), notifyWide, notifyTall, 5, 3, Color( 255, 255, 255, notifyAlpha ) )
			draw.TexturedRect( notifyXPos + 4, offsetY, 16, 16, notifyIcon, Color( 255, 255, 255, notifyAlpha ) )
			draw.SimpleText( notifyTbl.message, textFont, notifyXPos + 24, offsetY - ( ( notifyTall * 0.5 ) - ( txtH * 0.7 ) ), textColor, TEXT_ALIGN_LEFT )
		end
	end
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

local function DrawHealthIndicator( )
	local healthStartPosX, healthStartPosY = ScrW( ) * 0.0005, ScrH( ) * 0.945
	local pnlX, pnlY, pnlW, pnlH = healthStartPosX + 28, healthStartPosY - 28, 32 * 10.645, 64
	draw.RoundedBox( 0, pnlX, pnlY, pnlW, pnlH, Color( 45, 45, 45, 200 ) )
	draw.RoundedBox( 0, pnlX, pnlY, pnlW, pnlH * 0.35, Color( 45, 45, 45, 235 ) )
	draw.BlurredRect( pnlX, pnlY, pnlW, pnlH, 3, 3 )
	local roundAmt = GMatch:GetGameVar( "FinishedRounds", 0 )
	draw.SimpleText( "Round #" .. roundAmt, "GMatch_Lobster_MediumBoldStatic", pnlX + 8, pnlY + 5, Color( 255, 255, 255 ), TEXT_ALIGN_LEFT )
	for i = 1, 10 do
		local partHPStart = ( i * 10 )
		local partHPEnd = partHPStart - 10
		local heartPercent = math.Clamp( ( ( LocalPlayer( ):Health( ) - partHPEnd ) / 10 ), 0, 1 )
		local sizeWave = math.abs( ( math.sin( CurTime( ) * 3 ) * 1 ) )
		draw.TexturedRect( healthStartPosX + ( i * ( 32 + sizeWave ) ), healthStartPosY, 32 + sizeWave, 32 + sizeWave, heartMat, Color( 255, 255, 255 ) )
		draw.HorizontalCutTexturedRect( healthStartPosX + ( i * ( 32 + sizeWave ) ), healthStartPosY, 32 + sizeWave, 32 + sizeWave, heartMat, Color( 175, 45, 45 ), heartPercent )
	end
	DrawAmmoIndicator( pnlX, pnlY )
end

local function DrawGameSwitchTime( )
	if not ( gameSwitchTime ) then
		gameSwitchTime = GMatch:GetGameVar( "GameSwitchTime", nil )
		if ( gameSwitchTime ) then gameSwitchTime = CurTime( ) + gameSwitchTime end
	elseif ( gameSwitchTime and gameSwitchTime > CurTime( ) ) then
		local timeLeft = string.NiceTime( gameSwitchTime - CurTime( ) )
		draw.SimpleText( "The gamemode will switch in " .. timeLeft .. "!", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.2, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end
end

local function DrawRespawnTimer( )
	if not ( LocalPlayer( ):Alive( ) ) then
		local respawnLength = LocalPlayer( ).respawnLength or 0
		local timeUntilRespawn = LocalPlayer( ).timeUntilRespawn or 0
		if ( timeUntilRespawn > CurTime( ) ) then
			local timeLeft = string.upper( string.NiceTime( timeUntilRespawn - CurTime( ) ) )
			draw.SimpleText( "YOU HAVE DIED", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.8, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
			draw.SimpleText( "YOU MAY RESPAWN IN " .. timeLeft .. "!", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.85, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
		else
			draw.SimpleText( "YOU MAY RESPAWN", "GMatch_Lobster_MediumBold", ScrW( ) * 0.5, ScrH( ) * 0.8, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
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
			local offsetY = ( ScrH( ) * 0.3 ) + ( ( 16 * index ) )

			if ( screenMessages[index-1] ) then
				local mes, font = screenMessages[index-1].message, screenMessages[index-1].font
				if not ( GMatch.GameData.Fonts[font] ) then font = "GMatch_Lobster_MediumBold" end
				surface.SetFont( font )
				local txtW, txtH = surface.GetTextSize( mes )
				offsetY = offsetY + ( txtH * 0.5 )
			end
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
	/*draw.RoundedBox( 0, 29, ScrH( ) - 222.5, 192, 150, Color( 45, 45, 45, 200 ) )
	draw.RoundedBox( 0, 29, ScrH( ) - 222.5, 192, 24, Color( 45, 45, 45, 200 ) )
	draw.BlurredRect( 29, ScrH( ) - 222.5, 192, 150, 3, 3 )*/
	draw.RoundedBox( 0, 29, ScrH( ) - 122.5, 341, 40, Color( 45, 45, 45, 200 ) )
	draw.RoundedBox( 0, 29, ScrH( ) - 122.5, 341, 16, Color( 45, 45, 45, 230 ) )
	draw.BlurredRect( 29, ScrH( ) - 122.5, 341, 40, 3, 3 )
	local timeRemaining = timerLength - CurTime( )
	local roundLength = GMatch.Config.RoundLength
	local overrideLength = GMatch.GameData.RoundLength
	if ( overrideLength ) then roundLength = overrideLength end
	local barWidth = 320 * ( timeRemaining / roundLength )
	draw.RoundedBox( 0, 40, ScrH( ) - 106.5, 320, 16, Color( 75, 75, 255, 200 ) )
	draw.RoundedBox( 0, 40, ScrH( ) - 106.5, barWidth, 16, Color( 25, 25, 255, 200 ) )
	/*local x = 1 deg = ( timeRemaining / roundLength ) * 360
	draw.TexturedRect( 66, ScrH( ) - 195.5, 118, 120, circleFill )
	for i = 1, deg, 1 do
		local x, y = math.PointOnCircle( i, 54, 121, ScrH( ) - 140 )
		draw.RoundedBox( 4, x, y, 8, 8, Color( 100, 100, 175, 100 ) )
	end
	draw.TexturedRect( 62, ScrH( ) - 200, 128, 128, circleBorder )*/
	draw.SimpleText( "Time Remaining", "GMatch_Lobster_MediumBoldStatic", 195, ScrH( ) - 122.5, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
	timeRemaining = string.FormattedTime( timeRemaining, "%02i:%02i" )
	draw.SimpleText( timeRemaining, "GMatch_Lobster_SmallBoldStatic", 195, ScrH( )  - 105, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
end

hook.Add( "HUDPaint", "GMatch:HUDPaint", function( )
	DrawNotifications( )
	DrawHealthIndicator( )
	DrawGameSwitchTime( )
	DrawRespawnTimer( )
	DrawCenterScreenMessages( )
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